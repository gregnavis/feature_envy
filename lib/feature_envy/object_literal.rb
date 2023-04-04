# frozen_string_literal: true

module FeatureEnvy
  # Object literals.
  #
  # ### Definition
  #
  # An expression that results in creating of an object with a predefined set of
  # attributes and methods, without having to define and instantiated a class.
  #
  # ### Applications
  #
  # Defining singleton objects, both state and methods, without having to define
  # their class explicitly.
  #
  # ### Usage
  #
  # 1. Enable the feature in a specific class via `include FeatureEnvy::ObjectLiteral`
  #    or ...
  # 2. Enable the feature in a specific scope via `using FeatureEnvy::ObjectLiteral`.
  # 3. Create objects by calling `object { ... }`.
  #
  # ### Discussion
  #
  # Ruby does not offer literals for defining arbitrary objects. Fortunately,
  # that gap is easy to fill with a helper method. The snippet below is
  # literally how Feature Envy implements object literals:
  #
  # ```ruby
  # def object &definition
  #   object = Object.new
  #   object.instance_eval &definition
  #   object
  # end
  # ```
  #
  # All attributes set and methods defined inside the block will be set on
  # `object`.
  #
  # @example
  #   # Enable the feature in the current scope.
  #   using FeatureEnvy::ObjectLiteral
  #
  #   # Assuming `database` and `router` are already defined.
  #   app = object do
  #     @database = database
  #     @router   = router
  #
  #     def start
  #       @database.connect
  #       @router.activate
  #     end
  #   end
  #
  #   app.start
  module ObjectLiteral
    refine Kernel do
      def object ...
        ObjectLiteral.object(...)
      end
    end

    # Defines an object literal.
    #
    # @yield The block is evaluated in the context of a newly created object.
    #   Instance attributes and methods can be defined within the block and will
    #   end up being set on the resulting object.
    # @return [Object] The object defined by the block passed to the call.
    def object ...
      ObjectLiteral.object(...)
    end

    # @private
    def self.object &definition
      result = Object.new
      result.instance_eval &definition
      result
    end
  end
end
