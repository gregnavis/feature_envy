# frozen_string_literal: true

require "test_helper"

class LazyAccessorTest < Minitest::Test
  class RefinementTest < Minitest::Test
    using FeatureEnvy::LazyAccessor

    def test_using
      test_class = Class.new do
        lazy(:zero) { 0 }
      end

      assert_equal 0, test_class.new.zero
    end
  end

  def test_lazy
    # The number of times the lazy accessor block was executed.
    accessor_calls = 0

    # The return value of lazy (the accessor definition method).
    lazy_return_value = nil

    # A test class with a lazy accessor returning a new object. That object's
    # identity is then used to ensure the same value is reused on subsequent
    # accessor calls.
    test_class = Class.new do
      extend FeatureEnvy::LazyAccessor

      lazy_return_value = lazy(:object) do
        accessor_calls += 1
        Object.new
      end
    end

    assert_equal [:object],
                 lazy_return_value,
                 "Calling lazy should have returned the accessor name wrapped in an array"

    instance = test_class.new
    assert_equal 0,
                 accessor_calls,
                 "The accessor shouldn't have been called before first use"

    # The original accessor return value; needed to test subsequent calls.
    return_value = instance.object

    assert_instance_of Object,
                       return_value,
                       "An object should have been returned"
    assert_same return_value,
                instance.object,
                "The same object should have been returned on a subsequent call"
    assert_equal 1,
                 accessor_calls,
                 "The accessor block shouldn't have been executed"
  end
end
