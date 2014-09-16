require 'test_helper'

class DefinitionsTest < MiniTest::Test

  def setup
    @tree = ResqueJobsTree::Definitions::Tree.new :tree1
    @root = ResqueJobsTree::Definitions::Node.new :node1, @tree
    @tree.root = @root
    @leaf = ResqueJobsTree::Definitions::Node.new :node2, @tree, @root
    @root.node_children = [@leaf]
  end

  def test_perform
    variable = 1
    @root.perform do |n|
      variable = n
    end
    @root.perform.call 2
    assert_equal variable, 2
  end

  def test_children
    variable = 1
    @leaf.children do |n|
      variable = n
    end
    @leaf.children.call 2
    assert_equal variable, 2
  end

  def test_node
    node3 = @root.node :node3
    assert_equal @root.find('node3').object_id, node3.object_id
  end

  def test_leaf
    assert @leaf.leaf?
    assert !@root.leaf?
  end

  def test_root
    assert @root.root?
    assert !@leaf.root?
  end

  def test_siblings
    node3 = ResqueJobsTree::Node.new :node3, @tree, @root
    assert @leaf.siblings, [node3]
  end

  def test_children_validation
    assert_raises ResqueJobsTree::NodeDefinitionInvalid do
      ResqueJobsTree::Factory.create :tree1 do
        root :job1 do
          perform {}
          children {}
        end
      end
    end
    ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform {}
      end
    end
  end

  def test_perform_validation
    assert_raises ResqueJobsTree::NodeDefinitionInvalid do
      ResqueJobsTree::Factory.create :tree1 do
        root :job1 do
        end
      end
    end
  end

  def test_perform_validation
    assert_raises ResqueJobsTree::NodeDefinitionInvalid do
      ResqueJobsTree::Factory.create :tree1 do
        root :job1 do
          perform {}
          children {}
          node :job2 do
            perform {}
          end
          node :job2 do
            perform {}
          end
        end
      end
    end
  end

  def test_options
    options = { triggerable: true }
    @leaf.options = options
    assert_equal options, @tree.find(:node2).options
  end

  def test_find
    tree_definition = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform {}
        children { [:job4] }
        node :job2 do
          perform {}
        end
      end
    end
    assert_raises ResqueJobsTree::TreeDefinitionInvalid do
      tree_definition.spawn([]).launch
    end
  end

end
