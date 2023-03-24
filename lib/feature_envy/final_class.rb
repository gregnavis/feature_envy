# frozen_string_literal: true

module FeatureEnvy
  # Final classes.
  #
  # A final class is a class that cannot be inherited from. In other words, a
  # final class enforces the invariant that it has no subclasses. Existence of
  # subclasses if checked **at the moment a class is defined final** (to catch
  # cases where a class is reopened and made final after subclasses were
  # defined) and when.
  #
  # The module can be used in two ways:
  #
  # 1. Using it as a refinement and calling +.final!+ in bodies of classes that
  #    should be marked final.
  # 2. Extending the class with {FeatureEnvy::FinalClass}.
  #
  # See the example below for details.
  #
  # @example Final classes with refinements
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
  #
  # @example Final classes without refinements
  #   module Models
  #     class User < Base
  #       # Mark the User class final.
  #       extend FeatureEnvy::FinalClass
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

        raise Error.new(final_class: final_class, subclasses: subclasses)
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
