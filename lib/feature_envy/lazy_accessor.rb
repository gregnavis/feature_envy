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

    # Defines a lazy accessor.
    #
    # Required to share the code between the extension and refinement.
    #
    # @private
    def self.define klass, name, &definition
      variable_name = :"@#{name}"

      klass.class_eval do
        [
          define_method(name) do
            if instance_variable_defined? variable_name
              instance_variable_get variable_name
            else
              instance_variable_set variable_name, instance_eval(&definition)
            end
          end
        ]
      end
    end
  end
end
