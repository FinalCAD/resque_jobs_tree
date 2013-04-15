class ResqueJobsTree::Tree

  include ResqueJobsTree::Storage::Tree

  attr_reader :definition, :resources, :leaves

  def initialize definition, resources
    @definition = definition
    @resources = resources
    @leaves = []
  end

  def name
    @definition.name
  end

  def launch
    if uniq?
      before_perform
      store
      root.launch
      enqueue_leaves_jobs
    end
  end

  %w(before_perform after_perform on_failure).each do |callback|
    class_eval %Q{def #{callback} ; run_callback :#{callback} ; end}
  end

  def root
    @root ||= ResqueJobsTree::Node.new(definition.root, resources, nil, self)
  end

  def register_a_leaf node
    @leaves << node
  end

  def inspect
    "<ResqueJobsTree::Tree @name=#{name} @resources=#{resources} >"
  end

  def finish
    after_perform
    unstore
  end

  private

  def enqueue_leaves_jobs
    @leaves.each do |leaf|
      leaf.enqueue unless leaf.definition.options[:async]
    end
  end

  def run_callback callback
    callback = definition.send(callback)
    callback.call(*resources) if callback.kind_of? Proc
  end

end
