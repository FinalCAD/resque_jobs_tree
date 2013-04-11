class ResqueJobsTree::Tree

  attr_accessor :name
  attr_reader :jobs

  def initialize name
    @name = name.to_s
    @jobs = []
  end

  def root name=nil, &block
    @root ||= ResqueJobsTree::Node.new(name, self).tap do |root|
      root.instance_eval &block
    end
  end

  def on_failure &block
    @on_failure ||= block
  end

  def launch *resources
    ResqueJobsTree::Storage.track_launch self, resources do
      @root.launch resources
      enqueue_leaves_jobs
    end
  end

  def enqueue job_name, *resources
    @jobs << ([name, job_name] + ResqueJobsTree::ResourcesSerializer.to_args(resources))
  end

  def find_node_by_name name
    root.find_node_by_name name.to_s
  end

  def validate!
    raise(ResqueJobsTree::TreeInvalid, "`#{name}` has no root node") unless @root
    root.validate!
  end

  def nodes
    [root, root.nodes].flatten
  end

  def inspect
    "<ResqueJobsTree::Tree @name=#{name}>"
  end

  private

  def enqueue_leaves_jobs
    @jobs.each{ |job_args| Resque.enqueue_to name, ResqueJobsTree::Job, *job_args }
  end

end
