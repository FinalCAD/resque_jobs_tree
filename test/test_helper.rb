require 'rubygems'
gem 'minitest' # ensures you're using the gem, and not the built in MT
require 'minitest/autorun'
require 'bundler/setup'
require 'minitest/unit'

$dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift $dir + '/../lib'
require 'resque_jobs_tree'
$TESTING = true

require 'mock_redis'
Resque.redis = MockRedis.new

#
# Fixtures
#
class Model
  def initialize id
    @id = id
  end
  def id
    @id ||= rand 1000
  end
  def self.find id
    new id
  end
  def == other
    id == other.id
  end
end

class ExpectedException < Exception ; end

class MiniTest::Unit::TestCase

  def setup
    Resque.inline = true
  end

  private

  def teardown
    redis.keys.each{ |key| redis.del key }
  end

  def redis
    Resque.redis
  end

  def create_tree
    @tree_definition = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform do |*args|
          Resque.redis.rpush 'history', 'tree1 job1'
        end
        childs do |resources|
          [].tap do |childs|
            3.times do |n|
              childs << [:job2, n]
            end
          end
        end
        node :job2 do
          perform do |*args|
            Resque.redis.rpush 'history', 'tree1 job2'
          end
        end
      end
    end
  end

  def create_nested_tree
    @tree_definition = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform { raise ExpectedException, 'job1' }
        childs { [ [:job2] ] }
        node :job2, continue_on_failure: true do
          perform { raise 'job2' }
          childs { [ [:job3], [:job4] ] }
          node :job3, async: true do
            perform {}
          end
          node :job4, continue_on_failure: true do
            perform { raise 'job4' }
          end
        end
      end
    end
  end

end
