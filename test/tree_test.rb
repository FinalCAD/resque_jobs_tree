require 'test_helper'

class TreeTest < MiniTest::Unit::TestCase

  def setup
    create_tree
  end

  def test_name
    assert_equal @tree_definition.name, 'tree1'
  end

  def test_nodes
    assert_equal @tree_definition.spawn([]).nodes, []
  end

  def test_root
    assert @tree_definition.root.kind_of? ResqueJobsTree::Definitions::Node
  end

  def test_register_node
    leaf = 'leaf'
    tree = @tree_definition.spawn []
    tree.register_node leaf
    assert_equal tree.nodes, [leaf]
  end

  def test_find
    assert_equal 'job2', @tree_definition.find(:job2).name
    tree_definition = create_nested_tree_with_job_failure 
    assert_equal 'job4', tree_definition.find(:job4).name
  end

  def test_should_have_root
    assert_raises ResqueJobsTree::TreeDefinitionInvalid do
      ResqueJobsTree::Factory.create :tree1 do
      end
    end
  end

end
