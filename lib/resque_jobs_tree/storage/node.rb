module ResqueJobsTree::Storage::Node
	include ResqueJobsTree::Storage

  def store
    raise 'Can\'t store a root node' if root?
		redis.setex parent_key_storage_key, 21_600, parent.key
		if redis.sadd parent.children_key, key
		  redis.expire parent.children_key, 21_600
    else
			raise ResqueJobsTree::JobNotUniq,
				"Job #{parent.name} already has the child #{name} with resources:"\
        "#{resources}"
		end
  end

  def unstore
		redis.srem parent.children_key, key
		redis.sadd parent.finished_children_key, key
		redis.expire parent.finished_children_key, 21_600
  end

  def cleanup
		unless definition.leaf?
			stored_children.each(&:cleanup)
			redis.del children_key, finished_children_key
		end
    redis.del parent_key_storage_key
    tree.unstore if root?
  end

  def children_key
    "#{key}:children"
  end

  def finished_children_key
    "#{key}:finished_children"
  end

  def key
    "ResqueJobsTree:Node:#{serialize}"
  end

  def only_stored_child?
    (redis.smembers(parent.children_key) - [key]).empty?
  end

  def stored_children
    redis.sunion(children_key, finished_children_key).map do |_key|
      node_name, _resources = node_info_from_key _key
      definition.find(node_name).spawn _resources, self
    end
  end

  def parent
    @parent ||= definition.parent.spawn node_info_from_key(parent_key).last
  end
  
  def lock_key
    "#{key}:lock"
  end

  def exists?
    if definition.root?
      tree.exists?
    else
      redis.exists(children_key) || redis.exists(parent_key_storage_key)
    end
  end

  def currently_being_retried!
    redis.setex being_retried_key, 21_600, true
  end

  def currently_being_retried?
    redis.del(being_retried_key) == 1
  end

	private

  def lock
    _key = parent.lock_key
    while !redis.setnx(_key, 'locked')
      sleep 0.05 # 50 ms
    end
    yield
  ensure
    redis.del _key
  end

  def parent_key
    redis.get parent_key_storage_key
  end

  def node_info_from_key _key
    tree_name, node_name, *resources_arguments =
      JSON.load(_key.gsub /ResqueJobsTree:Node:/, '')
    _resources = ResqueJobsTree::ResourcesSerializer.instancize(resources_arguments)
		[node_name, _resources]
  end

	def main_arguments
		[definition.tree.name, name]
	end

  def parent_key_storage_key
    @parent_key_storage_key ||= "#{PARENTS_KEY}:#{key}"
  end

  def being_retried_key
    "#{key}:retry"
  end
end
