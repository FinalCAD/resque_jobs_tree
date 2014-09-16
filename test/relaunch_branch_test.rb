require 'test_helper'

class RelaunchBranchTest < MiniTest::Test

  def test_relaunch_branch
    Resque.inline = false
    create_tree
    @tree_definition.spawn([]).launch
    run_resque_workers @tree_definition.name
    job1_serialized =
      ["{\"class\":\"ResqueJobsTree::Job\",\"args\":[\"tree1\",\"job1\"]}"]
    assert_equal job1_serialized, redis.lrange(resque_queue, 0, -1)
    redis.del resque_queue
    node = @tree_definition.find(:job1).spawn([])
    node.relaunch_branch
    job2_serialized =
      ["{\"class\":\"ResqueJobsTree::Job\",\"args\":[\"tree1\",\"job2\",null]}"]
    assert_equal job2_serialized, redis.lrange(resque_queue, 0, -1)
    2.times{run_resque_workers @tree_definition.name}
    assert redis.lrange(resque_queue, 0, -1).empty?
    logs = [
      'tree1 job2',
      'tree1 job2',
      'tree1 job1'
    ]
    assert_equal logs, redis.lrange('history', 0, -1)
    assert_equal ['history'], redis.keys
  end

  private
  
  def resque_queue
    "queue:#{@tree_definition.name}"
  end

  def create_tree
    @tree_definition = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform do |*args|
          Resque.redis.rpush 'history', 'tree1 job1'
        end
        childs do |resources|
          [[:job2, nil]]
        end
        node :job2 do
          perform do
            Resque.redis.rpush 'history', 'tree1 job2'
          end
        end
      end
    end
  end
end
