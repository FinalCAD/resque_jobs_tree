require 'test_helper'

class FactoryTest < MiniTest::Unit::TestCase

  def setup
    create_tree
  end

  def test_tree_creation
    assert_equal ResqueJobsTree::Factory.trees.first.object_id, @tree.object_id
  end

  def test_find_by_name
    assert_equal ResqueJobsTree::Factory.find_tree_by_name(@tree.name).object_id,
      @tree.object_id
  end

end
