require 'test_helper'

class FactoryTest < MiniTest::Unit::TestCase

  def setup
    create_tree
  end

  def test_tree_creation
    assert_equal ResqueJobsTree::Factory.trees.values.first.name, @tree_definition.name
  end

  def test_find
    assert_equal ResqueJobsTree::Factory.find(@tree_definition.name).name, @tree_definition.name
  end

end
