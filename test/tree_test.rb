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
    assert_equal @tree.find_node_by_name('job2').name, 'job2'
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

end
