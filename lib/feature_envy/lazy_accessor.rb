# frozen_string_literal: true

module FeatureEnvy
  # Lazy accessors.
  #
  # ### Definition
  #
  # A lazy **attribute** is an attribute whose value is determined on first
  # access. The same value is used on all subsequent access without running the
  # code to determine its value again.
  #
  # Lazy attributes are impossible in Ruby (see the discussion below), but
  # lazy **accessors** are, and are provided by this module.
  #
  # ### Applications
  #
  # Deferring expensive computations until needed and ensuring they're performed
  # at most once.
  #
  # ### Usage
  #
  # 1. Enable the feature in a specific class via `extend FeatureEnvy::LazyAccessor` or ...
  # 2. Enable the feature in a specific **scope** (given module and all modules
  #    and classes contained within) using a refinement via `using FeatureEnvy::LazyAccessor`.
  # 3. Define one or more lazy attributes via `lazy(:name) { definition }`.
  # 4. Do **NOT** read or write to the underlying attribute, e.g. `@name`;
  #    always use the accessor method.
  # 5. Lazy accessors are **thread-safe**: the definition block will be called
  #    at most once; if two threads call the accessor for the first time one
  #    will win the race to run the block and the other one will wait and reuse
  #    the value produced by the first.
  # 6. It's impossible to reopen a class and add new lazy accessors after **the
  #    any class using lazy accessors has been instantiated**. Doing so would
  #    either make the code thread-unsafe or require additional thread-safety
  #    measures, potentially reducing performance.
  #
  # ### Discussion
  #
  # Ruby attributes start with `@` and assume the default value of `nil` if not
  # assigned explicitly. Real lazy attributes are therefore impossible to
  # implement in Ruby. Fortunately **accessors** (i.e. methods used to obtain
  # attribute values) are conceptually close to attributes and can be made lazy.
  #
  # A naive approach found in many Ruby code bases looks like this:
  #
  # ```ruby
  # def highest_score_user
  #   @highest_score_user ||= find_highest_score_user
  # end
  # ```
  #
  # It's simple but suffers from a serious flaw: if `nil` is assigned to the
  # attribute then subsequent access will result in another attempt to determine
  # the attribute's value.
  #
  # The proper approach is much more verbose:
  #
  # ```ruby
  # def highest_score_user
  #   # If the underlying attribute is defined then return it no matter its value.
  #   return @highest_score_user if defined?(@highest_score_user)
  #
  #   @highest_score_user = find_highest_score_user
  # end
  # ```
  #
  # ### Implementation Notes
  #
  # 1. Defining a lazy accessor defines a method with that name. The
  #    corresponding attribute is **not** set before the accessor is called for
  #    the first time.
  # 2. The first time a lazy accessor is added to a class a special module
  #    is included into it. It provides an `initialize` method that sets
  #    `@lazy_attributes_mutexes` - a hash of mutexes protecting each lazy
  #    accessor.
  #
  # @example
  #   class User
  #     # Enable the feature via refinements.
  #     using FeatureEnvy::LazyAccessor
  #
  #     # Lazy accessors can return nil and have it cached and reused in
  #     # subsequent calls.
  #     lazy(:full_name) do
  #       "#{first_name} #{last_name}" if first_name && last_name
  #     end
  #
  #     # Lazy accessors are regular methods, that follow a specific structure,
  #     # so they can call other methods, including other lazy accessors.
  #     lazy(:letter_ending) do
  #       if full_name
  #         "Sincerely,\n#{full_name}"
  #       else
  #         "Sincerely"
  #       end
  #     end
  #   end
  module LazyAccessor
    # A class representing an error related to lazy-accessors.
    class Error < FeatureEnvy::Error; end

    refine Class do
      def lazy name, &definition
        LazyAccessor.define self, name, &definition
      end
    end

    # Defines a lazy accessor.
    #
    # The `definition` block will be called once when the accessor is used for
    # the first time. Its value is returned and cached for subsequent accessor
    # use.
    #
    # @param name [String|Symbol] accessor name.
    # @return [Array<Symbol>] the array containing the accessor name as a
    #   symbol; this is motivated by the built-in behavior of `attr_reader` and
    #   other built-in accessor definition methods.
    # @yieldreturn the value to store in the underlying attribute and return on
    #   subsequent accessor use.
    def lazy name, &definition
      LazyAccessor.define self, name, &definition
    end

    # A class for creating mutexes for classes that make use of lazy accessors.
    #
    # The class keeps a hash that maps modules and classes to arrays of lazy
    # accessor names defined therein.
    #
    # @private
    class MutexFactory
      def initialize
        @mutexes_by_class = Hash.new { |hash, klass| hash[klass] = [] }
      end

      # Register a new lazy attribute.
      #
      # @return [Symbol] The name of the mutex corresponding to the specified
      #   lazy accessor.
      #
      # @private
      def register klass, lazy_accessor_name
        ObjectSpace.each_object(klass) do # rubocop:disable Lint/UnreachableLoop
          raise Error.new(<<~ERROR)
            An instance of #{klass.name} has been already created, so it's no longer
            possible to define a new lazy accessor, due to thread-safety reasons.
          ERROR
        end

        mutex_name = :"@#{lazy_accessor_name}_mutex"
        @mutexes_by_class[klass] << mutex_name
        mutex_name
      end

      # Create mutexes for lazy accessor supported on a given instance.
      #
      # @private
      def initialize_mutexes_for instance
        current_class = instance.class
        while current_class
          @mutexes_by_class[current_class].each do |mutex_name|
            instance.instance_variable_set mutex_name, Thread::Mutex.new
          end
          current_class = current_class.superclass
        end

        instance.class.included_modules.each do |mod|
          @mutexes_by_class[mod].each do |mutex_name|
            instance.instance_variable_set mutex_name, Thread::Mutex.new
          end
        end
      end
    end
    private_constant :MutexFactory

    @mutex_factory = MutexFactory.new

    class << self
      # A mutex factory used by the lazy accessors feature.
      #
      # @private
      attr_reader :mutex_factory

      # Defines a lazy accessor.
      #
      # Required to share the code between the extension and refinement.
      #
      # @private
      def define klass, name, &definition
        name = name.to_sym
        variable_name = :"@#{name}"
        mutex_name = LazyAccessor.mutex_factory.register klass, name

        klass.class_eval do
          # Include the lazy accessor initializer to ensure state related to
          # lazy accessors is initialized properly. There's no need to include
          # this module more than once.
          #
          # Question: is the inclusion check required? Brief testing indicates
          # it's not.
          if !include? Initialize
            include Initialize
          end

          [
            define_method(name) do
              mutex = instance_variable_get(mutex_name)
              if mutex # rubocop:disable Style/SafeNavigation
                mutex.synchronize do
                  if instance_variable_defined?(mutex_name)
                    instance_variable_set variable_name, instance_eval(&definition)
                    remove_instance_variable mutex_name
                  end
                end
              end

              instance_variable_get variable_name
            end
          ]
        end
      end
    end

    # A module included in all classes that use lazy accessors responsible for
    # initializing a hash of mutexes that guarantee thread-safety on first call.
    #
    # @private
    module Initialize
      def initialize ...
        super

        LazyAccessor.mutex_factory.initialize_mutexes_for self
      end
    end
    private_constant :Initialize
  end
end
