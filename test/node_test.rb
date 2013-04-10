require 'test_helper'

class NodeTest < MiniTest::Unit::TestCase

  def setup
    @tree = ResqueJobsTree::Tree.new :tree1
    @root = ResqueJobsTree::Node.new :node1, @tree
    @leaf = ResqueJobsTree::Node.new :node2, @tree, @root
  end

  def test_ressources
    variable = 1
    @root.resources do |n|
      variable = n
    end
    @root.resources.call 2
    assert_equal variable, 2
  end

  def test_perform
    variable = 1
    @root.perform do |n|
      variable = n
    end
    @root.perform.call 2
    assert_equal variable, 2
  end

  def test_childs
    variable = 1
    @leaf.childs do |n|
      variable = n
    end
    @leaf.childs.call 2
    assert_equal variable, 2
  end

  def test_node
    node3 = @root.node :node3
    assert_equal @root.find_node_by_name('node3').object_id, node3.object_id
  end

  def test_leaf
    resources = []
    assert @leaf.leaf?(resources)
    @root.childs do |resources|
      [:node2, resources]
    end
    assert !@root.leaf?(resources)
  end

  def test_root
    assert @root.root?
    assert !@leaf.root?
  end

  def test_siblings
    node3 = ResqueJobsTree::Node.new :node3, @tree, @root
    assert @leaf.siblings, [node3]
  end

  def test_launch
    resources = [1, 2, 3]
    @leaf.launch resources, resources
    assert_equal @tree.jobs.first, ['tree1', 'node2', 1, 2, 3]
  end

  def test_childs_validation
    assert_raises ResqueJobsTree::NodeInvalid do
      ResqueJobsTree::Factory.create :tree1 do
        root :job1 do
          perform {}
          childs {}
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
    assert_raises ResqueJobsTree::NodeInvalid do
      ResqueJobsTree::Factory.create :tree1 do
        root :job1 do
        end
      end
    end
  end

  def test_perform_validation
    assert_raises ResqueJobsTree::NodeInvalid do
      ResqueJobsTree::Factory.create :tree1 do
        root :job1 do
          perform {}
          childs {}
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
    create_async_tree
    options = { async: true }
    assert_equal options, @tree.find_node_by_name(:job2).options
  end

  def test_launch_async
    create_async_tree
    resources = [1, 2, 3]
    @tree.launch resources
    assert @tree.jobs.empty?
  end

  def test_launch_continue_on_failure
    tree = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform { raise 'an unexpected failure' }
        childs { [:job2] }
        node :job2, continue_on_failure: true do
          perform { raise 'an expected failure' }
        end
      end
    end
    resources = [1, 2, 3]
    assert_raises RuntimeError, 'an unexpected failure' do
      tree.launch resources
    end
    assert_equal [], Resque.keys
  end

  def test_leaf_failure
    tree = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform {}
        childs { [:job2] }
        node :job2 do
          perform { raise 'an unexpected failure' }
        end
      end
    end
    resources = [1, 2, 3]
    assert_raises RuntimeError, 'an unexpected failure' do
      tree.launch *resources
    end
    assert_equal [], Resque.keys
  end

  def test_root_failure
    tree = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform { raise 'an unexpected failure' }
        childs { [:job2] }
        node :job2 do
          perform {}
        end
      end
    end
    resources = [1, 2, 3]
    assert_raises RuntimeError, 'an unexpected failure' do
      tree.launch resources
    end
    assert_equal [], Resque.keys
  end

  private

  def create_async_tree
    @tree = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform { raise 'should not arrive here' }
        childs { [:job2] }
        node :job2, async: true do
          perform {}
        end
      end
    end
  end

end
