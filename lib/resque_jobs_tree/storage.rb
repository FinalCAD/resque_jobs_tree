module ResqueJobsTree::Storage

  PARENTS_KEY = "ResqueJobsTree:Node:Parents" 
  LAUNCHED_TREES = "ResqueJobsTree:Tree:Launched"

  private

  def serialize
    argumentize.to_json
  end

  def argumentize
    main_arguments + ResqueJobsTree::ResourcesSerializer.argumentize(resources)
  end

  def redis
    Resque.redis
  end
end
