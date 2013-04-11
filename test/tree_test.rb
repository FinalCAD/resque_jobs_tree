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
    assert_raises ExpectedException do
      @tree.launch
    end
  end

  def test_tree_with_resource
    create_tree_with_resources
    @tree.launch Model.new(1)
  end

  def test_nested_tree
    create_nested_tree
    assert_raises RuntimeError do # job4 error !
      @tree.launch
    end
    assert_raises NoMethodError do # job3 error !
      Resque.enqueue_to 'tree1', ResqueJobsTree::Job, 'tree1', 'job3'
    end
  end

  def test_async_tree
    tree = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform { raise 'should not arrive here' }
        childs { [ [:job2], [:job3] ] }
        node :job2, async: true do
          perform {}
        end
        node :job3 do
          perform {}
        end
      end
    end
    tree.launch
    assert_equal ["ResqueJobsTree:Node:[\"tree1\",\"job2\"]"],
      Resque.redis.smembers("ResqueJobsTree:Node:[\"tree1\",\"job1\"]:childs")
    parents_hash = { 'ResqueJobsTree:Node:["tree1","job2"]'=>'ResqueJobsTree:Node:["tree1","job1"]' }
    assert_equal parents_hash, Resque.redis.hgetall(ResqueJobsTree::Storage::PARENTS_KEY)
  end

  def test_async_tree_with_fail
    tree = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform { raise 'should not arrive here' }
        childs { [ [:job2], [:job3] ] }
        node :job2, async: true do
          perform {}
        end
        node :job3, continue_on_failure: true do
          perform { raise ExpectedException, 'an expected failure' }
        end
      end
    end
    assert_raises ExpectedException do
      tree.launch
    end
    assert_equal ["ResqueJobsTree:Node:[\"tree1\",\"job2\"]"],
      Resque.redis.smembers("ResqueJobsTree:Node:[\"tree1\",\"job1\"]:childs")
  end

  private

  def create_tree_with_on_failure_hook
    @tree = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform { raise ExpectedException, 'job1' }
      end
      on_failure do
        raise ExpectedException, 'called from on_failure block'
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
