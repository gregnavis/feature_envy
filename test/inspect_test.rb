# frozen_string_literal: true

require "logger"

require "test_helper"

class InspectTest < Minitest::Test
  # Inspect is usually included into BasicObject, but in order to reduce test case
  # interference it's included in a dedicated test class defined below, so that
  # BasicObject remains intact during the test suite run.
  class Inspectable
    include FeatureEnvy::Inspect

    # #inspect is used for testing InspectInspector
    def inspect = object_id.to_s
  end

  def test_inspect!
    object                         = Inspectable.new
    inspected_objects              = []
    FeatureEnvy::Inspect.inspector = ->(argument) { inspected_objects << argument; argument.object_id.to_s }
    FeatureEnvy::Inspect.output    = StringIO.new

    assert_same object,
                object.inspect!,
                "inspect! should have returned the object being inspected"
    assert_equal [object],
                 inspected_objects,
                 "inspect! should have passed the object to the inspector"

    assert_equal "#{object.object_id}\n",
                 FeatureEnvy::Inspect.output.string.force_encoding("US-ASCII"),
                 "#puts should have been called on the output with the value returned by the inspector"
  end

  def test_logger_adapter
    io                             = StringIO.new
    logger                         = Logger.new io
    FeatureEnvy::Inspect.inspector = FeatureEnvy::Inspect::InspectInspector
    FeatureEnvy::Inspect.output    = FeatureEnvy::Inspect::LoggerAdapter.new logger
    object                         = Inspectable.new

    object.inspect!

    assert_match /^D, \[.*\] DEBUG -- : #{object.inspect}\n$/,
                 io.string,
                 "inspect! should have logged the inspector result"
  end

  def test_inspector_and_output_required
    FeatureEnvy::Inspect.inspector = nil
    FeatureEnvy::Inspect.output    = nil

    object = Inspectable.new

    assert_raises(FeatureEnvy::Inspect::NoInspectorError, <<~ERROR) { object.inspect! }
      inspect! should raise an error if no inspector is set
    ERROR

    FeatureEnvy::Inspect.inspector = FeatureEnvy::Inspect::InspectInspector

    assert_raises(FeatureEnvy::Inspect::NoOutputError, <<~ERROR) { object.inspect! }
      inspect! should raise an error if no output is set
    ERROR
  end
end
