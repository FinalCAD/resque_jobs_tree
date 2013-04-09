# put expire on every key
module ResqueJobsTree::Storage
  extend self

  PARENTS_KEY = "JobsTree:Node:Parents" 

  def store node, resources, parent, parent_resources
    node_key = key node, resources
    parent_key = key parent, parent_resources
    Resque.redis.hset PARENTS_KEY, node_key, parent_key
    childs_key = childs_key parent, parent_resources
    Resque.redis.sadd childs_key, node_key
  end

  def remove node, resources
    lock_with parent_lock_key(node, resources) do
      siblings_key = siblings_key node, resources
      Resque.redis.srem siblings_key, key(node, resources)
      yield if Resque.redis.scard(siblings_key) == 0 && block_given?
    end
  end

  def parent_job_args node, resources
    JSON.load parent_key(node, resources).gsub(/JobsTree:Node:/, '')
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

end
