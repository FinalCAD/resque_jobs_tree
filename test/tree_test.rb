require 'test_helper'

class TreeTest < MiniTest::Unit::TestCase

  def setup
    @tree = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform do |*args|
          # puts 'TreeTest job1'
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
            # puts 'TreeTest job2'
          end
        end
      end
    end
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
  end

end
