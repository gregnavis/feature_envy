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

  # The idea behind the thread-safety test is the following:
  #
  # 1. Instantiate an object with a lazy accessor.
  # 2. The block is written so that it pauses the current thread; this way all
  #    threads are put "on the starting line" so to speak.
  # 3. Several threads are spun up and made call the accessor; they're all
  #    waiting for the signal to go.
  # 4. Threads are run and their return values are collected.
  #
  # If the code is thread-safe then only one object instance should be returned
  # to all threads. If more than one object was returned then a race-condition
  # occurred.
  def test_thread_safety
    test_class = Class.new do
      extend FeatureEnvy::LazyAccessor
      lazy(:object) { Object.new }
    end
    instance = test_class.new

    # Spin up a few threads all trying to call the accessor.
    threads = (1..5).map do
      thread = Thread.new { Thread.stop; instance.object }

      # A brief pause may be needed to ensure the thread was put to sleep.
      sleep 0.05 while thread.status != "sleep"

      thread
    end

    # Run the threads and check how many objects they received.

    threads.each(&:run)

    assert_equal 1,
                 threads.uniq(&:value).count,
                 "The same object should have been returned to all threads"
  end

  def test_thread_safety_in_subclass
    base_class = Class.new do
      extend FeatureEnvy::LazyAccessor
      lazy(:base_class_object) { Object.new }
    end
    subclass = Class.new base_class do
      extend FeatureEnvy::LazyAccessor
      lazy(:subclass_object) { Object.new }
    end

    instance = subclass.new

    assert instance.instance_variable_defined?(:@subclass_object_mutex),
           "The mutex for a lazy attribute from the subclass should have been defined"
    assert instance.instance_variable_defined?(:@base_class_object_mutex),
           "The mutex for a lazy attribute from the base class should have been defined"
  end

  def test_reopen_class_before_instantiation_is_allowed
    klass = Class.new

    klass.class_eval do
      extend FeatureEnvy::LazyAccessor
      lazy(:object) { Object.new }
    end

    instance = klass.new
    assert_instance_of Object, instance.object
  end

  def test_reopen_class_after_instantiation_raises_error
    klass = Class.new
    _instance = klass.new

    assert_raises FeatureEnvy::LazyAccessor::Error do
      klass.class_eval do
        extend FeatureEnvy::LazyAccessor
        lazy(:object) { Object.new }
      end
    end
  end
end
