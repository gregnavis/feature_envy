# frozen_string_literal: true

require "test_helper"

class ObjectLiteralTest < Minitest::Test
  class RefinementsTest < Minitest::Test
    using FeatureEnvy::ObjectLiteral

    def test_object
      person = object do
        def hello; end
      end

      assert_respond_to person,
                        :hello,
                        "The object should have been defined"
    end
  end

  include FeatureEnvy::ObjectLiteral

  def test_object
    person = object do
      @first_name = "Greg"
      @last_name  = "Navis"

      def full_name; "#{@first_name} #{@last_name}"; end
    end

    assert_equal      %i[@first_name @last_name],
                      person.instance_variables,
                      "The object should have had its attributes set"
    assert_equal      "Greg",
                      person.instance_variable_get(:@first_name),
                      "The object should have had its attributes set to the right values"
    assert_respond_to person,
                      :full_name,
                      "The object should have responded to methods defined in the literal"
    assert_equal      "Greg Navis",
                      person.full_name,
                      "The object should have evaluated its methods in its context"
  end
end
