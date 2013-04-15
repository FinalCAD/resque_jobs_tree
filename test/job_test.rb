require 'test_helper'

class JobTest < MiniTest::Unit::TestCase

	def test_node
		create_tree
		args = [@tree_definition.name, @tree_definition.find('job1').name, 1, 2, 3]
		assert_equal @tree_definition.find(:job1), ResqueJobsTree::Job.send(:node, *args).definition
		assert_equal ResqueJobsTree.find(:tree1), ResqueJobsTree::Job.send(:node, *args).definition.tree
		assert_equal [1, 2, 3], ResqueJobsTree::Job.send(:node, *args).resources
	end

end
