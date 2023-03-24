# frozen_string_literal: true

module FeatureEnvy
  # @private
  module Internal
    # Returns all subclasses of the given class.
    def self.subclasses parent_class
      subclasses = []
      ObjectSpace.each_object(Class) do |klass|
        subclasses << klass if klass.superclass.equal? parent_class
      end
      subclasses
    end

    # Returns a user-friendly class name.
    def self.class_name klass
      klass.name || ANONYMOUS_CLASS_NAME
    end

    ANONYMOUS_CLASS_NAME = "anonymous class"
    private_constant :ANONYMOUS_CLASS_NAME
  end
end
