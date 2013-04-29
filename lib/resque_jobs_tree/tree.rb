class ResqueJobsTree::Tree

  include ResqueJobsTree::Storage::Tree

  attr_reader :definition, :resources, :nodes

  def initialize definition, resources
    @definition = definition
    @resources = resources
    @nodes = []
  end

  def name
    @definition.name
  end

  def launch
    if uniq?
      before_perform
      store
      root.register
      enqueue_jobs
    end
  end

  %w(before_perform after_perform).each do |callback|
    class_eval %Q{def #{callback} ; run_callback :#{callback} ; end}
  end

  def on_failure
    run_callback :on_failure
  rescue
    puts "[ResqueJobsTree::Tree] on_failure callback of tree #{name} has failed. Continuing for cleanup."
  end

  def root
    @root ||= ResqueJobsTree::Node.new(definition.root, resources, nil, self)
  end

  def register_node node
    @nodes << node
  end

  def inspect
    "<ResqueJobsTree::Tree @name=#{name} @resources=#{resources} >"
  end

  def finish
    after_perform
    unstore
  end

  private

  def enqueue_jobs
    @nodes.each do |leaf|
      leaf.enqueue unless leaf.definition.options[:async]
    end
  end

  def run_callback callback
    callback = definition.send(callback)
    callback.call(*resources) if callback.kind_of? Proc
  end

end
