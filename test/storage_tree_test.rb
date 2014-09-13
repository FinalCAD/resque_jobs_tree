require 'test_helper'

class StorageTreeTest < MiniTest::Test

	def setup
		create_tree
		@resources = [Model.new(42), 2, 3]
		@tree = @tree_definition.spawn @resources
	end

	def test_serialize
		assert_equal '["tree1",["Model",42],2,3]', @tree.send(:serialize)
	end

	def test_key
		assert_equal 'ResqueJobsTree:Tree:["tree1",["Model",42],2,3]', @tree.key
	end

	def test_storing
		@tree.store
		assert_equal ["ResqueJobsTree:Tree:[\"tree1\",[\"Model\",42],2,3]"],
			redis.smembers(ResqueJobsTree::Storage::LAUNCHED_TREES)
		@tree.unstore
		assert_equal [], redis.smembers(ResqueJobsTree::Storage::LAUNCHED_TREES)
	end

end
