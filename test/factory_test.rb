require 'test_helper'

class FactoryTest < MiniTest::Unit::TestCase

  def setup
    create_tree
  end

  def test_tree_creation
    assert_equal ResqueJobsTree::Factory.trees.values.first.name, @tree_definition.name
  end

  def test_find
    assert_equal ResqueJobsTree::Factory.find(@tree_definition.name).name, @tree_definition.name
  end

  def test_without_perform
    assert_not_raises do
      ResqueJobsTree::Factory.create :tree_with_job_without_perform do
        root :job_without_perform
      end
    end.must_equal 'ok'
  end

  def assert_not_raises
    begin
      yield
      'ok'
    rescue
      $!
    end
  end

end
