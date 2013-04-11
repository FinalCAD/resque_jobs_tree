require 'test_helper'

class TreeTest < MiniTest::Unit::TestCase

  def setup
    create_tree
  end

  def test_name
    assert_equal @tree.name, 'tree1'
  end

  def test_jobs
    assert_equal @tree.jobs, []
  end

  def test_root
    assert @tree.root.kind_of? ResqueJobsTree::Node
  end

  def test_enqueue
    job_args = [:job4, ['Model', 1], 123]
    @tree.enqueue *job_args
    assert_equal @tree.jobs.first, ['tree1', :job4, ['Model', 1], 123]
  end

  def test_find_node_by_name
    assert_equal 'job2', @tree.find_node_by_name('job2').name
    create_nested_tree
    assert_equal 'job4', @tree.find_node_by_name('job4').name
  end

  def test_launch
    resources = [1, 2, 3]
    @tree.launch *resources
    history = ['tree1 job2']*3+['tree1 job1']
    assert_equal history, redis.lrange('history', 0, -1)
  end

  def test_launch_with_no_resources
    @tree.launch
  end

  def test_should_have_root
    assert_raises ResqueJobsTree::TreeInvalid do
      ResqueJobsTree::Factory.create :tree1 do
      end
    end
  end

  def test_on_failure
    create_tree_with_on_failure_hook
    assert_raises RuntimeError, 'called form on_failure block' do
      @tree.launch
    end
  end

  def test_tree_with_resource
    create_tree_with_resources
    @tree.launch Model.new(1)
  end

  def test_nested_tree
    create_nested_tree
    @tree.launch
    assert_raises NoMethodError do
      Resque.enqueue_to 'tree1', ResqueJobsTree::Job, 'tree1', 'job3'
    end
  end

  private

  def create_tree_with_on_failure_hook
    @tree = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform { raise 'expected failure' }
      end
      on_failure do
        raise 'called form on_failure block'
      end
    end
  end

  def create_tree_with_resources
    @tree = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform do |resources|
          raise 'unknown resource' unless resources.first.kind_of?(Model)
        end
      end
    end
  end

end
