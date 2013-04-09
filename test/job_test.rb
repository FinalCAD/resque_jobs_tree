require 'test_helper'

class JobTest < MiniTest::Unit::TestCase
	
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
		@args = [@tree.name, @tree.find_node_by_name('job1').name, 1, 2, 3]
	end

	def test_tree_node_and_resources
		result = [@tree, @tree.find_node_by_name('job1'), [1, 2, 3]]
		assert_equal result, ResqueJobsTree::Job.send(:tree_node_and_resources, *@args)
	end

end
