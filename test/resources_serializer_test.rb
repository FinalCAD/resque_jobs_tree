require 'test_helper'

class ResourcesSerializerTest < MiniTest::Unit::TestCase

  def test_serialization_deserialization
    model = Model.new 42
    input = [model, :pdf, [1,2]]
    serialized_input = ResqueJobsTree::ResourcesSerializer.argumentize(input)

    assert_equal [['Model', model.id], :pdf, [1,2]], serialized_input

    assert_equal [Model.new(42), :pdf, [1,2]],
      ResqueJobsTree::ResourcesSerializer.instancize(serialized_input)
  end
  
end
