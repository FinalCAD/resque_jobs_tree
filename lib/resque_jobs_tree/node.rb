class ResqueJobsTree::Node

  attr_accessor :tree, :parent, :name, :node_childs

  def initialize name, tree, parent=nil
    @tree        = tree
    @name        = name.to_s
    @parent      = parent
    @node_childs = []
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
  def node name, &block
    ResqueJobsTree::Node.new(name, tree, self).tap do |node|
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
      @tree.enqueue name, *resources
    else
      childs.call(resources).each do |name, *child_resources|
        find_node_by_name(name).launch child_resources, resources
      end
    end
  end

  def find_node_by_name _name
    return self if name == _name.to_s
    node_childs.detect{ |node| node.find_node_by_name _name }
  end

  def validate!
    if childs.kind_of?(Proc) && node_childs.empty?
      raise ResqueJobsTree::NodeInvalid,
        "node `#{name}` from tree `#{tree.name}` defines childs without child nodes"
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

end
