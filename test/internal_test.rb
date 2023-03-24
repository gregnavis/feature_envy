# frozen_string_literal: true

require "test_helper"

class InternalTest < Minitest::Test
  class Model; end
  class User < Model; end
  class Project < Model; end
  class AdminUser < User; end

  def test_subclasses
    assert_equal [User, Project].sort_by(&:name),
                 FeatureEnvy::Internal.subclasses(Model).sort_by(&:name),
                 "All subclasses and no other descendants should have been returned"
  end

  def test_class_name
    assert_equal "InternalTest::Model",
                 FeatureEnvy::Internal.class_name(Model)
    assert_equal "InternalTest::User",
                 FeatureEnvy::Internal.class_name(User)
    assert_equal "anonymous class",
                 FeatureEnvy::Internal.class_name(Class.new)
  end
end
