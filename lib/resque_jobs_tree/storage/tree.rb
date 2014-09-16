module ResqueJobsTree::Storage::Tree
	include ResqueJobsTree::Storage

  # TODO 21_600 in config
  def store
    redis.sadd(LAUNCHED_TREES, key).tap do
		  redis.expire LAUNCHED_TREES, 21_600
    end
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

  def exists?
    redis.sismember LAUNCHED_TREES, key
  end
  
  private

	def main_arguments
		[name]
	end
end
