require 'test_helper'

class StorageTest < MiniTest::Unit::TestCase

	def setup
    @tree = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform do |*args|
          puts 'FactoryTest job1'
        end
        childs do |resources|
          [].tap do |childs|
            3.times do
              childs << [:job2, resources.last]
            end
          end
        end
        node :job2 do
          perform do |*args|
            puts 'FactoryTest job2'
          end
        end
      end
    end
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

	private

	def store
		ResqueJobsTree::Storage.store @leaf, @resources, @leaf.parent, @resources
	end

end
