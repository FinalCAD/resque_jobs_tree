require 'test_helper'

class FactoryTest < MiniTest::Unit::TestCase

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
  end

  def test_tree_creation
    assert_equal ResqueJobsTree::Factory.trees.first.object_id, @tree.object_id
  end

  def test_find_by_name
    assert_equal ResqueJobsTree::Factory.find_tree_by_name(@tree.name).object_id,
      @tree.object_id
  end

end
