# frozen_string_literal: true

module FeatureEnvy
  # Final classes.
  #
  # ### Definition
  #
  # A final class is a class that cannot be inherited from. In other words, a
  # final class enforces the invariant that it has no subclasses.
  #
  # ### Applications
  #
  # Preventing subclassing of classes that weren't specifically designed for
  # handling it.
  #
  # ### Usage
  #
  # 1. Enable the feature in a specific class via `extend Feature::FinalClass`.
  #    The class has been marked final and there's nothing else to do.
  #    Alternatively, ...
  # 2. Enable the feature in a specific **scope** using a refinement via
  #    `using FeatureEnvy::FinalClass` and call `final!` in all classes that
  #    should be marked final.
  #
  # ### Discussion
  #
  # A class in Ruby can be made final by raising an error in its `inherited`
  # hook. This is what this module does. However, this is **not** enough to
  # guarantee that no subclasses will be created. Due to Ruby's dynamic nature
  # it'd be possible to define a class, subclass, and then reopen the class and
  # mark it final. This edge **is** taken care of and would result in an
  # exception.
  #
  # @example
  #   module Models
  #     # Use the refinement within the module, so that all classes defined
  #     # within support the final! method.
  #     using FeatureEnvy::FinalClass
  #
  #     class User < Base
  #       # Mark the User class final.
  #       final!
  #     end
  #   end
  module FinalClass
    # An error representing a final class invariant violation.
    class Error < FeatureEnvy::Error
      def initialize final_class:, subclasses:
        super(<<~ERROR)
          Class #{FeatureEnvy::Internal.class_name final_class} is final but the following subclasses were defined:

          #{subclasses.map { "- #{FeatureEnvy::Internal.class_name _1}" }.join("\n")}
        ERROR
      end
    end

    refine Class do
      def final!
        extend FinalClass
      end

      def final?
        FinalClass.final? self
      end
    end

    # The array of classes that were marked as final.
    @classes = []

    class << self
      def extended final_class
        # The class must be marked final first, before we check whether there
        # are already existing subclasses. If the error were raised first then
        # .final? would return +false+ causing confusion: if the class isn't
        # final then why was the error raised?
        @classes << final_class

        subclasses = Internal.subclasses final_class
        return if subclasses.empty?

        raise Error.new(final_class:, subclasses:)
      end

      # Determines whether a given class is marked final.
      #
      # @param klass [Class] The class whose finality should be checked.
      # @return [Boolean] +true+ if +klass+ is final, +false+ otherwise.
      def final? klass
        @classes.include? klass
      end
    end

    # @private
    def inherited klass # rubocop:disable Lint/MissingSuper
      raise Error.new(final_class: self, subclasses: [klass])
    end
  end
end
