require 'test_helper'

class JobTest < MiniTest::Test

	def test_node
		create_tree
		args = [@tree_definition.name, @tree_definition.find('job1').name, 1, 2, 3]
    redis.sadd ResqueJobsTree::Storage::LAUNCHED_TREES, @tree_definition.spawn([1,2,3]).key
		assert_equal @tree_definition.find(:job1), ResqueJobsTree::Job.send(:node, *args).definition
		assert_equal ResqueJobsTree.find(:tree1), ResqueJobsTree::Job.send(:node, *args).definition.tree
		assert_equal [1, 2, 3], ResqueJobsTree::Job.send(:node, *args).resources
	end

  def test_unregistred_node
		create_tree
		args = [@tree_definition.name, @tree_definition.find('job1').name, 1, 2, 3]
    silenced_stdout do
		  assert ResqueJobsTree::Job.send(:node, *args).kind_of?(ResqueJobsTree::Job::FakeNode)
    end
  end

end
