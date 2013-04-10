require 'test_helper'

class StorageTest < MiniTest::Unit::TestCase

	def setup
		create_tree
		@resources = [1, 2, 3]
		@root = @tree.find_node_by_name(:job1)
		@leaf = @tree.find_node_by_name(:job2)
	end

	def test_store
		parents_key = ResqueJobsTree::Storage::PARENTS_KEY
		Resque.redis.del parents_key
		store
		assert_equal 1, Resque.redis.hlen(parents_key)
		childs_key = ResqueJobsTree::Storage.send :childs_key, @root, @resources
		assert_equal 1, Resque.redis.scard(childs_key)
	end

	def test_parent_job_args
		store
		assert_equal ['tree1', 'job1', 1, 2, 3],
			ResqueJobsTree::Storage.parent_job_args(@leaf, @resources)
	end

	def test_remove
		store
		variable = 1
		ResqueJobsTree::Storage.remove @leaf, @resources do
			variable = 2
		end
		assert_equal 2, variable
	end

	def test_store_already_stored
		wrong_tree = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform {}
        childs do |resources|
					[ [:job2], [:job2] ]
        end
        node :job2 do
          perform {}
        end
      end
    end
		assert_raises ResqueJobsTree::JobNotUniq do
			wrong_tree.launch
		end
	end

	def test_node_info_from_key
		key = %Q{ResqueJobsTree:Node:["tree1","job1",1,2,3]}
		result = [@root, [1, 2, 3]]
		assert_equal result, ResqueJobsTree::Storage.send(:node_info_from_key, key)
	end

	def test_track_launch
		resources = [1, 2, 3]
		ResqueJobsTree::Storage.track_launch(@tree, resources) {}
		key = ResqueJobsTree::Storage::LAUNCHED_TREES
    assert_equal [[@tree.name, resources].to_json], redis.smembers(key)
		ResqueJobsTree::Storage.release_launch(@tree, resources)
    assert_equal [], redis.smembers(key)
	end

	private

	def store
		ResqueJobsTree::Storage.store @leaf, @resources, @leaf.parent, @resources
	end

end
