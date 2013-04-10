require 'test_helper'

class JobTest < MiniTest::Unit::TestCase
	
	def setup
		create_tree
		@args = [@tree.name, @tree.find_node_by_name('job1').name, 1, 2, 3]
	end

	def test_tree_node_and_resources
		result = [@tree.find_node_by_name('job1'), [1, 2, 3]]
		assert_equal result, ResqueJobsTree::Job.send(:node_and_resources, @args)
	end

end
