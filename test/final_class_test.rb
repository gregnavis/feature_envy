# frozen_string_literal: true

require "test_helper"

class FinalClassTest < Minitest::Test
  using FeatureEnvy::FinalClass

  def test_non_refinement_final_class_cannot_be_inherited
    user = Class.new do
      extend FeatureEnvy::FinalClass
    end

    assert_raises FeatureEnvy::FinalClass::Error,
                  "Subclassing a final class should have raised an exception" do
      Class.new user
    end
    assert user.final?,
           "A final class should have been reported as final but was not"
  end

  def test_refinement_final_class_cannot_be_inherited
    user = Class.new do
      final!
    end

    assert_raises FeatureEnvy::FinalClass::Error,
                  "Subclassing a final class should have raised an exception" do
      Class.new user
    end
    assert user.final?,
           "A final class should have been reported as final but was not"
  end

  def test_error_when_superclass_made_final
    model = Class.new
    user = Class.new model # rubocop:disable Lint/UselessAssignment

    assert_raises FeatureEnvy::FinalClass::Error,
                  "Making a superclass final should have raised an exception" do
      model.extend FeatureEnvy::FinalClass
    end
  end
end
