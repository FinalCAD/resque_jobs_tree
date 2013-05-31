class ResqueJobsTree::Node

  include ResqueJobsTree::Storage::Node

  attr_reader :resources, :definition, :tree

  def initialize definition, resources, parent=nil, tree=nil
    @childs     = []
    @definition = definition
    @resources  = resources
    @parent     = parent
    @tree       = tree
  end

  def enqueue
    Resque.enqueue_to definition.tree.name, ResqueJobsTree::Job, *argumentize
  end

  def perform
    definition.perform.call *resources
  end

  def before_perform
    run_callback :before_perform
  end

  def after_perform
    run_callback :after_perform
    if root?
      tree.finish
    else
      lock do
        parent.enqueue if only_stored_child?
        unstore
      end
    end
  end

  def on_failure
    if definition.options[:continue_on_failure]
      run_callback :on_failure
      after_perform
    else
      root.tree.on_failure
      root.cleanup
    end
  end

  def tree
    @tree ||= root? ? definition.tree.spawn(resources) : @parent.tree
  end

  def name
    definition.name
  end

  def leaf?
    childs.empty?
  end

  def root?
    definition.root?
  end

  def root
    @root ||= root? ? self : parent.root
  end

  def childs
    return @childs unless @childs.empty?
    @childs = definition.leaf? ?  [] : definition.childs.call(*resources)
  end

  def register
    store unless root?
    if leaf?
      tree.register_node self
    else
      childs.each do |node_name, *resources|
        node = definition.find(node_name).spawn resources, self
        node.register
      end
    end
  end

  def inspect
    "<ResqueJobsTree::Node @name=#{name} @resources=#{resources}>"
  end

  private

  def run_callback callback
    callback_block = definition.send callback
    callback_block.call(*resources) if callback_block.kind_of? Proc
  rescue
    if [:after_perform, :on_failure].include? callback
      puts "[ResqueJobsTree::Tree] after_perform callback of node #{definition.tree.name}##{name} has failed."\
           " Continuing for cleanup."
    else
      raise
    end
  end

end
