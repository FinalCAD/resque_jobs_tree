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

Resque.inline = true

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


# Run resque callbacks in inline mode
class ResqueJobsTree::Job
  class << self
    def perform_with_hook *args
      begin
        perform_without_hook *args
        after_perform_enqueue_parent *args
      rescue => exception
        on_failure_cleanup exception, *args
      end
    end
    alias_method :perform_without_hook, :perform
    alias_method :perform, :perform_with_hook
  end
end

class MiniTest::Unit::TestCase

  def teardown
    redis.keys.each{ |key| redis.del key }
  end

  def create_tree
    @tree = ResqueJobsTree::Factory.create :tree1 do
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

  def redis
    Resque.redis
  end

end
