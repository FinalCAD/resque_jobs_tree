# put expire on every key
module ResqueJobsTree::Storage
  extend self

  PARENTS_KEY = "ResqueJobsTree:Node:Parents" 
  LAUNCHED_TREES = "ResqueJobsTree:Tree:Launched"

  def store node, resources, parent, parent_resources
    node_key = key node, resources
    parent_key = key parent, parent_resources
    redis.hset PARENTS_KEY, node_key, parent_key
    childs_key = childs_key parent, parent_resources
    unless redis.sadd childs_key, node_key
      raise ResqueJobsTree::JobNotUniq,
        "Job #{parent.name} already has the child #{node.name} with resources: #{resources}"
    end
  end

  def remove node, resources
    lock node, resources do
      siblings_key = siblings_key node, resources
      redis.srem siblings_key, key(node, resources)
      yield if redis.scard(siblings_key) == 0 && block_given?
    end
  end

  def failure_cleanup node, resources, options={}
    cleanup_childs node, resources
    if node.root?
      release_launch node.tree, resources
    else
      remove_from_siblings node, resources
      options[:global] ?  cleanup_parent(node, resources, options) : remove_parent_key(node, resources)
    end
  end

  def parent_job_args node, resources
    args_from_key parent_key(node, resources)
  end

  def track_launch *tree_info
    yield if redis.sadd LAUNCHED_TREES, tree_reference(*tree_info)
  end

  def release_launch *tree_info
    redis.srem LAUNCHED_TREES, tree_reference(*tree_info)
  end

  private

  def key node, resources
    job_args = ResqueJobsTree::ResourcesSerializer.to_args(resources)
    job_args.unshift node.name
    job_args.unshift node.tree.name
    "ResqueJobsTree:Node:#{job_args.to_json}"
  end

  def childs_key node, resources
    "#{key node, resources}:childs"
  end

  def parent_key node, resources
    node_key = key node, resources
    redis.hget PARENTS_KEY, node_key
  end

  def siblings_key node, resources
    "#{parent_key node, resources}:childs"
  end

  def parent_lock_key node, resources
    "#{parent_key node, resources}:lock"
  end

  def lock *node_info
    key = parent_lock_key *node_info
    while !redis.setnx(key, 'locked')
      sleep 0.05 # 50 ms
    end
    yield
  ensure
    redis.del key
  end

  def cleanup_childs *node_info
    key = childs_key *node_info
    redis.smembers(key).each do |child_key|
      failure_cleanup *node_info_from_key(child_key)
    end
    redis.del key
  end

  def cleanup_parent node, resources, options
    parent, parent_resources = node_info_from_key(parent_key(node, resources))
    remove_parent_key node, resources
    failure_cleanup parent, parent_resources, options
  end

  def remove_parent_key *node_info
    redis.hdel PARENTS_KEY, key(*node_info)
  end

  def remove_from_siblings *node_info
    redis.srem siblings_key(*node_info), key(*node_info)
  end

  def args_from_key key
    JSON.load key.gsub(/ResqueJobsTree:Node:/, '')
  end

  def node_info_from_key key
    tree_name, node_name, *resources = args_from_key(key)
    node = ResqueJobsTree::Factory.find_tree_by_name(tree_name).find_node_by_name(node_name)
    [node, resources]
  end

  def redis
    Resque.redis
  end

  def tree_reference tree, resources
    [tree.name, ResqueJobsTree::ResourcesSerializer.to_args(resources)].to_json
  end

end
