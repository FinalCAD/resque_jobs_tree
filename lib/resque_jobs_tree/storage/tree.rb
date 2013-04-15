module ResqueJobsTree::Storage::Tree
	include ResqueJobsTree::Storage

  def store
    redis.sadd LAUNCHED_TREES, key
  end

  def unstore
    redis.srem LAUNCHED_TREES, key
  end

  def key
    "ResqueJobsTree:Tree:#{serialize}"
  end

  def uniq?
    !redis.sismember LAUNCHED_TREES, key
  end
  
  private

	def main_arguments
		[name]
	end
  
end
