require 'test_helper'

class ResourcesSerializerTest < MiniTest::Unit::TestCase

  def test_serialization_deserialization
    model = Model.new 42
    input = [model, :pdf, [1,2]]
    serialized_input = ResqueJobsTree::ResourcesSerializer.to_args(input)
    result = [['Model', model.id], :pdf, [1,2]]
    assert_equal serialized_input, result
    deserialized = ResqueJobsTree::ResourcesSerializer.
      to_resources(serialized_input)
    assert_equal deserialized, [Model.new(42), :pdf, [1,2]]
  end
  
end
