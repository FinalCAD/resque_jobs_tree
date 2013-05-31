require 'test_helper'

class ProcessTest < MiniTest::Unit::TestCase

  def test_launch_without_uniq
    create_tree
    assert_raises ResqueJobsTree::JobNotUniq do
      resque_jobs_tree = @tree_definition.spawn [1, 2, 3]
      resque_jobs_tree.stub :uniq?, false do
        resque_jobs_tree.launch
      end
    end
  end

  def test_launch
    create_tree
    resources = [1, 2, 3]
    resque_jobs_tree = @tree_definition.spawn(resources)
    resque_jobs_tree.stub :uniq?, true do
      resque_jobs_tree.launch
    end
    history = ['tree1 job2']*3+['tree1 job1']
    assert_equal history, redis.lrange('history', 0, -1)
  end

  def test_launch_with_no_resources
    create_tree
    @tree_definition.spawn([]).launch
  end

  def test_leaf_failure
    tree_definition = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform {}
        childs { [:job2] }
        node :job2 do
          perform { raise ExpectedException, 'an expected exception'}
        end
      end
    end
    assert_raises ExpectedException do
      tree_definition.spawn([1, 2, 3]).launch
    end
    assert_redis_empty
  end

  def test_can_more_one_triggerable_job
    assert_not_raises do
      tree_definition = ResqueJobsTree::Factory.create :tree1 do
        root :job1 do
          perform { puts 'job1' }
          childs { [:job2, :job3] }
          node :job2, triggerable: true do
            perform {}
          end
          node :job3, triggerable: true
        end
      end
      tree = tree_definition.spawn [1, 2, 3]
      tree.launch
    end
  end

  def test_launch_triggerable
    tree_definition = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform { raise 'should not arrive here' }
        childs { [:job2] }
        node :job2, triggerable: true do
          perform {}
        end
      end
    end
    tree = tree_definition.spawn [1, 2, 3]
    tree.launch
  end

  def test_launch_continue_on_failure
    tree_definition = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform do
          Resque.redis.rpush 'history', 'tree1 job1'
          raise ExpectedException, 'an expected failure'
        end
        childs { [:job2] }
        node :job2, continue_on_failure: true do
          perform do
            Resque.redis.rpush 'history', 'tree1 job2'
            raise 'an expected failure'
          end
        end
      end
    end
    assert_raises ExpectedException do
      tree = tree_definition.spawn [1, 2, 3]
      tree.launch
    end
    assert_equal ['tree1 job2','tree1 job1'], redis.lrange('history', 0, -1)
    redis.del 'history'
    assert_redis_empty
  end

  def test_launch_continue_on_failure_with_on_failure_block
    Resque.inline = false
    tree_definition = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform do
          Resque.redis.rpush 'history', 'tree1 job1 perform'
        end
        childs { [:job2] }
        node :job2, continue_on_failure: true do
          perform do
            Resque.redis.rpush 'history', 'tree1 job2 perform'
            raise 'an expected failure'
          end
          on_failure do
            Resque.redis.rpush 'history', 'tree1 job2 on_failure'
          end
        end
      end
    end
    tree_definition.spawn([1, 2, 3]).launch
    assert_raises RuntimeError, 'an expected failure' do
      run_resque_workers tree_definition.name
    end
    run_resque_workers tree_definition.name
    assert_equal ['tree1 job2 perform','tree1 job2 on_failure', 'tree1 job1 perform'], redis.lrange('history', 0, -1)
    redis.del 'history'
  end

  def test_root_failure
    Resque.inline = false
    tree_definition = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform do
          Resque.redis.rpush 'history', 'tree1 job1'
          raise ExpectedException, 'an expected exception'
        end
        childs { [:job2] }
        node :job2 do
          perform do
            Resque.redis.rpush 'history', 'tree1 job2'
          end
        end
      end
    end
    tree = tree_definition.spawn [1,2,3]
    tree.launch
    run_resque_workers tree_definition.name
    assert_raises ExpectedException do
      run_resque_workers tree_definition.name
    end
    assert_equal ['tree1 job2','tree1 job1'], redis.lrange('history', 0, -1)
    redis.del 'history'
    assert_redis_empty
  end

	def test_store_already_stored
		wrong_tree_definition = ResqueJobsTree::Factory.create :tree1 do
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
			wrong_tree_definition.spawn([1]).launch
		end
	end

  def test_on_failure
    tree_definition = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform { raise }
      end
      on_failure do
        raise ExpectedException, 'called from on_failure block'
      end
    end
    assert_raises ExpectedException do
      tree_definition.spawn([1]).launch
    end
  end

  def test_tree_with_resource
    tree_definition = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform do |resource, number|
          raise 'unknown resource' unless resource.kind_of?(Model)
          raise 'unknown resource' unless number.kind_of?(Integer)
        end
      end
    end
    ResqueJobsTree.launch tree_definition.name, Model.new(1), 1
  end

  def test_nested_tree_with_job_failure
    Resque.inline = false
    create_nested_tree_with_job_failure
    @tree_definition.spawn([1,2,3]).launch
    assert_raises RuntimeError do # job4 error
      run_resque_workers @tree_definition.name
    end
    Resque.enqueue_to 'tree1', ResqueJobsTree::Job, 'tree1', 'job3'
    run_resque_workers @tree_definition.name # job3 error
    assert_raises RuntimeError do # job2 error
      run_resque_workers @tree_definition.name
    end
    assert_raises ExpectedException do # job1 error
      run_resque_workers @tree_definition.name
    end
  end

  def test_triggerable_tree
    tree_definition = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform { raise 'should not arrive here' }
        childs { [ [:job2], [:job3] ] }
        node :job2, triggerable: true do
          perform {}
        end
        node :job3 do
          perform {}
        end
      end
    end
    ResqueJobsTree.launch tree_definition.name
    assert_equal ["ResqueJobsTree:Node:[\"tree1\",\"job2\"]"],
      Resque.redis.smembers("ResqueJobsTree:Node:[\"tree1\",\"job1\"]:childs")
    parents_hash = { 'ResqueJobsTree:Node:["tree1","job2"]'=>'ResqueJobsTree:Node:["tree1","job1"]' }
    assert_equal parents_hash, Resque.redis.hgetall(ResqueJobsTree::Storage::PARENTS_KEY)
  end

  def test_triggerable_tree_with_fail
    Resque.inline = false
    tree_definition = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        perform { raise 'should not arrive here' }
        childs { [ [:job2], [:job3] ] }
        node :job2, triggerable: true do
          perform {}
        end
        node :job3, continue_on_failure: true do
          perform { raise ExpectedException, 'an expected failure' }
        end
      end
    end
    tree_definition.spawn([]).launch
    assert_raises ExpectedException do # job3 exception
      run_resque_workers tree_definition.name
    end
    assert_equal ["ResqueJobsTree:Node:[\"tree1\",\"job2\"]"],
      Resque.redis.smembers("ResqueJobsTree:Node:[\"tree1\",\"job1\"]:childs")
  end

  def test_exception_in_on_failure_callback
    Resque.inline = false
    tree_definition = ResqueJobsTree::Factory.create :tree1 do
      on_failure { raise 'an unexpected exception' }
      root :job1 do
        perform { raise ExpectedException, 'an expected exception'}
      end
    end
    tree_definition.spawn([]).launch
    assert_raises ExpectedException do
      silenced_stdout do
        run_resque_workers tree_definition.name
      end
    end
    assert_equal ['queues'], Resque.redis.keys
  end

  def test_exception_in_after_perform_callback
    Resque.inline = false
    tree_definition = ResqueJobsTree::Factory.create :tree1 do
      root :job1 do
        after_perform { raise 'an unexpected exception'  }
        perform {}
      end
    end
    assert tree_definition.find(:job1).after_perform.kind_of?(Proc)
    tree_definition.spawn([]).launch
    silenced_stdout do
      run_resque_workers tree_definition.name
    end
    assert_equal [], Resque.redis.keys
  end

  private

  def assert_redis_empty
    assert_equal [], Resque.keys
  end

  # Inline mode is messy when dealing with on failure callbacks.
  def run_resque_workers queue_name
    Resque::Job.reserve(queue_name).perform
    redis.srem 'queues', queue_name
  end

end
