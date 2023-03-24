# frozen_string_literal: true

module Assertions
  def assert_mapping callable, mapping
    Hash(mapping).each do |input, output|
      arguments = input.is_a?(Array) ? input : [input]

      assert_equal output, callable.call(*arguments)
    end
  end
end
