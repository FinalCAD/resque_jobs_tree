# put expire on every key
module ResqueJobsTree::Storage
  extend self

  PARENTS_KEY = "JobsTree:Node:Parents" 

  def store node, resources, parent, parent_resources
    node_key = key node, resources
    parent_key = key parent, parent_resources
    Resque.redis.hset PARENTS_KEY, node_key, parent_key
    childs_key = childs_key parent, parent_resources
    unless Resque.redis.sadd childs_key, node_key
      raise ResqueJobsTree::JobNotUniq,
        "Job #{parent.name} already has the child #{node.name} with resources: #{resources}"
    end
  end

  def remove node, resources
    lock_with parent_lock_key(node, resources) do
      siblings_key = siblings_key node, resources
      Resque.redis.srem siblings_key, key(node, resources)
      yield if Resque.redis.scard(siblings_key) == 0 && block_given?
    end
  end

  def cleanup node, resources, option={}
    cleanup_childs node, resources
    unless node.root?
      remove_from_siblings node, resources
      option[:global] ?  cleanup_parent(node, resources) : remove_parent_key(node, resources)
    end
  end

  def parent_job_args node, resources
    args_from_key parent_key(node, resources)
  end

  private

  def key node, resources
    job_args = ResqueJobsTree::ResourcesSerializer.to_args(resources)
    job_args.unshift node.name
    job_args.unshift node.tree.name
    "JobsTree:Node:#{job_args.to_json}"
  end

  def childs_key node, resources
    "#{key node, resources}:childs"
  end

  def parent_key node, resources
    node_key = key node, resources
    Resque.redis.hget PARENTS_KEY, node_key
  end

  def siblings_key node, resources
    "#{parent_key node, resources}:childs"
  end

  def parent_lock_key node, resources
    "#{parent_key node, resources}:lock"
  end

  def lock_with key
    while !Resque.redis.setnx(key, 'locked')
      sleep 0.05 # 50 ms
    end
    yield
  ensure
    Resque.redis.del key
  end

  def cleanup_childs *node_info
    key = childs_key *node_info
    Resque.redis.smembers(key).each do |child_key|
      cleanup *node_info_from_key(child_key)
    end
    Resque.redis.del key
  end

  def cleanup_parent *node_info
    parent, parent_resources = node_info_from_key(parent_key(*node_info))
    remove_parent_key *node_info
    cleanup parent, parent_resources
  end

  def remove_parent_key *node_info
    Resque.redis.hdel PARENTS_KEY, key(*node_info)
  end

  def remove_from_siblings *node_info
    Resque.redis.srem siblings_key(*node_info), key(*node_info)
  end

  def args_from_key key
    JSON.load key.gsub(/JobsTree:Node:/, '')
  end

  def node_info_from_key key
    tree_name, node_name, resources = args_from_key(key)
    node = ResqueJobsTree::Factory.find_tree_by_name(tree_name).find_node_by_name(node_name)
    [node, resources]
  end

end
