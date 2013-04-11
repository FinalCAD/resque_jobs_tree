class ResqueJobsTree::Node

  attr_accessor :tree, :parent, :name, :node_childs, :options

  def initialize name, tree, parent=nil
    @tree        = tree
    @name        = name.to_s
    @parent      = parent
    @node_childs = []
    @options     = {}
  end

  def resources &block
    @resources_block ||= block
  end

  def perform &block
    @perform_block ||= block
  end

  def childs &block
    @childs ||= block
  end

  # Defines a child node.
  def node name, options={}, &block
    ResqueJobsTree::Node.new(name, tree, self).tap do |node|
      node.options = options
      @node_childs << node
      node.instance_eval(&block) if block_given?
    end
  end

  def leaf? resources
    childs.kind_of?(Proc) ?  childs.call(resources).empty? : true
  end

  def root?
    parent == nil
  end

  def siblings
    return [] unless parent
    parent.node_childs - [self]
  end

  def launch resources, parent_resources=nil
    unless root?
      ResqueJobsTree::Storage.store self, resources, parent, parent_resources
    end
    if node_childs.empty?
      @tree.enqueue(name, *resources) unless options[:async]
    else
      childs.call(resources).each do |name, *child_resources|
        find_node_by_name(name).launch child_resources, resources
      end
    end
  end

  def find_node_by_name _name
    if name == _name.to_s
      self
    else
      node_childs.inject(nil){|result,node| result ||= node.find_node_by_name _name }
    end
  end

  def validate!
    if (childs.kind_of?(Proc) && node_childs.empty?) || (childs.nil? && !node_childs.empty?)
      raise ResqueJobsTree::NodeInvalid,
        "node `#{name}` from tree `#{tree.name}` should defines childs and child nodes"
    end
    unless perform.kind_of? Proc
      raise ResqueJobsTree::NodeInvalid,
        "node `#{name}` from tree `#{tree.name}` has no perform block"
    end
    if (tree.nodes - [self]).map(&:name).include? name
      raise ResqueJobsTree::NodeInvalid,
        "node name `#{name}` is already taken in tree `#{tree.name}`"
    end
    node_childs.each &:validate!
  end

  def nodes
    node_childs+node_childs.map(&:nodes)
  end

  def inspect
    "<ResqueJobsTree::Node @name=#{name}>"
  end

end
