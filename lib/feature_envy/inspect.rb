# frozen_string_literal: true

module FeatureEnvy
  # Inspect method.
  #
  # ### Definition
  #
  # The inspect method is a helper method, inspired by `inspect/2` in Elixir,
  # aimed at making print debugging easier with minimal disruption to
  # surrounding code.
  #
  # ### Applications
  #
  # Quick inspection of intermediate values during development; **not intended
  # for use in production**.
  #
  # ### Usage
  #
  # 1. Proceed with the remaining steps **only in non-production** environments.
  # 2. Set an inspector by calling {FeatureEnvy::Inspect.inspector=}.
  #    This is a method taking the object being inspected at as the argument and
  #    returning its string representation. You can use the built-in
  #    {InspectInspector} as the starting point.
  # 3. Set an output by calling {FeatureEnvy::Inspect.output=}. This is an object
  #    implementing `#puts` that will be called with the inspector result, so
  #    IO objects like `$stdout` and `$stderr` can be used.
  # 4. Call {inspect} on objects you want to inspect at.
  #
  # A custom inspector and output can be provided. The examples below have
  # templates that can be used as starting points in development. There's also
  # an example showing how to enable the module in a Rails app.
  #
  # ### Discussion
  #
  # Elixir makes it easy to print objects of interest, including intermediate
  # ones, by passing them through `Kernel.inspect/2`. This function prints the
  # object's representation and returns the object itself, so that it can be
  # called on intermediate results without disrupting the remaining
  # instructions.
  #
  # For example, the instruction below instantiates `Language`, prints its
  # representation, and then passes that language to `Language.create!/1`:
  #
  # ```elixir
  # %Language{name: "Ruby"} |>
  #   inspect() |>
  #   Language.create!()
  # ```
  #
  # {FeatureEnvy::Inspect} is a Ruby counterpart of Elixir's `inspect/2`.
  # `#inspect!` was chosen since `#inspect` is already defined by Ruby and the
  # `!` suffix indicates a "dangerous" method.
  #
  # The syntax `object.inspect!` was chosen over `inspect!(object)` as it's
  # easier to insert in the middle of complicated method calls by requiring less
  # modifications to the surrounding code. The difference is best illustrated
  # in the following example:
  #
  # ```ruby
  # # If we start with ...
  # User.create!(user_attributes(request))
  #
  # # ... then it's easier to do to this ...
  # User.create!(user_attributes(request).inspect)
  #
  # # ... than this:
  # User.create!(inspect(user_attributes(request)))
  # ```
  #
  # ### Implementation Notes
  #
  # 1. Refinement-based activation would require the developer to add
  #    `using FeatureEnvy::Inspect` before calling `inspect!`, which would be
  #    extremely inconvenient. Since the feature is intended for non-production
  #    use only monkey-patching is the only way to activate it.
  #
  # @example Enabling Inspect in a Rails app
  #   # Inspect should be activated only in non-production environments.
  #   unless Rails.env.production?
  #     # To make the method available on all objects, BasicObject must be
  #     # reopened and patched.
  #     class BasicObject
  #       include FeatureEnvy::Inspect
  #     end
  #
  #     # Setting a inspector is required. Below, we're using a built-in inspector
  #     # that calls #inspect on the object being inspected at.
  #     FeatureEnvy::Inspect.inspector = FeatureEnvy::Inspect::InspectInspector
  #
  #     # Results should be printed to stderr.
  #     FeatureEnvy::Inspect.output = $stderr
  #   end
  #
  # @example Inspector and output class templates
  #   class CustomInspector
  #     def call(object)
  #       # object is the object on which inspect! was called. The method should
  #       # return the string that should be passed to the output.
  #     end
  #   end
  #
  #   class CustomOutput
  #     def puts(string)
  #       # string is the return value of #call sent to FeatureEnvy::Inspect.inspector.
  #       # The output object is responsible for showing this string to the
  #       # developer.
  #     end
  #   end
  #
  # @example Sending output to a logger
  #   # Assuming logger is an instance of the built-in Logger class, an adapter
  #   # is needed to make it output inspection results.
  #   FeatureEnvy::Inspect.output = FeatureEnvy::Inspect::LoggerAdapter.new logger
  module Inspect
    # A base class for errors related to the inspect method.
    class Error < FeatureEnvy::Error; end

    # An error raised when {#inspect!} is called but no inspector has been set.
    class NoInspectorError < Error
      # @!visibility private
      def initialize
        super(<<~ERROR)
          No inspector has been set. Ensure that FeatureEnvy::Inspect.inspector is set
          to an object responding to #call(object) somewhere early during
          initialization.
        ERROR
      end
    end

    # An error raised when {#inspect!} is called but no output has been set.
    class NoOutputError < Error
      # @!visibility private
      def initialize
        super(<<~ERROR)
          No output has been set. Ensure that FeatureEnvy::Inspect.output is set
          to an object responding to #puts(string) somewhere early during
          initialization.
        ERROR
      end
    end

    # Inspect the object and return it.
    #
    # The method inspects the object by:
    #
    #   1. Passing the object to `#inspect` defined on {.inspector}, producing a
    #      string representation of the object.
    #   2. Passing that string to `#puts` defined on {.output}.
    #
    # @return [self] The object on which {#inspect!} was called.
    def inspect!
      if FeatureEnvy::Inspect.inspector.nil?
        raise NoInspectorError.new
      end
      if FeatureEnvy::Inspect.output.nil?
        raise NoOutputError.new
      end

      result = FeatureEnvy::Inspect.inspector.call self
      FeatureEnvy::Inspect.output.puts result

      self
    end

    class << self
      # The inspector converting objects to string representations.
      #
      # The inspector **must** respond to `#call` with the object being
      # inspected as the only argument, and **must** return a string, that will
      # then be sent to {FeatureEnvy::Inspect.output}.
      #
      # @return [#call] The inspector currently in use.
      attr_accessor :inspector

      # The output object sending inspection results to the developer.
      #
      # The output object **must** respond to `#puts` with the string to print
      # as its only argument. This implies all IO objects can be used, as well
      # as custom classes implementing that interface.
      #
      # @return [#puts] The output object currently in use.
      #
      # @see FeatureEnvy::Inspect::LoggerAdapter
      attr_accessor :output
    end

    # An inspect-based inspector.
    #
    # This is an inspector that calls `#inspect` on objects being inspected.
    InspectInspector = ->(object) { object.inspect }

    # An adapter class enabling the user of loggers for output.
    #
    # {FeatureEnvy::Inspect.output} must respond to `#puts`, which precludes
    # loggers. This adapter can be used to make loggers usable as outputs by
    # logging at the desired level.
    #
    # @example
    #   # Given a logger, it can be used as inspection output by setting:
    #   FeatureEnvy::Inspect.output = FeatureEnvy::Inspect::LoggerAdapter.new logger
    #
    # @example Changing the log level
    #   FeatureEnvy::Inspect.output =
    #     FeatureEnvy::Inspect::LoggerAdapter.new logger,
    #                                             level: Logger::INFO
    class LoggerAdapter
      # Initializes a new adapter for the specified logger.
      #
      # @param logger [Logger] logger to use for output
      # @param level [Logger::DEBUG | Logger::INFO | Logger::WARN | Logger::ERROR | Logger::FATAL | Logger::UNKNOWN]
      #   level at which inspection results should be logged.
      def initialize logger, level: Logger::DEBUG
        @logger = logger
        @level  = level
      end

      # @api private
      def puts string
        @logger.add @level, string
        nil
      end
    end
  end
end
