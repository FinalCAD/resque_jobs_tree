class ResqueJobsTree::Definitions::Node < ResqueJobsTree::Definitions

  attr_accessor :tree, :parent, :name, :node_children, :options

  def initialize name, tree, parent=nil
    @tree        = tree
    @name        = name.to_s
    @parent      = parent
    @node_children = []
    @options     = {}
  end

  def node name, options={}, &block
    ResqueJobsTree::Definitions::Node.new(name, tree, self).tap do |node|
      node.options = options
      @node_children << node
      if block_given?
        node.instance_eval(&block)
      elsif options.has_key? :triggerable
        node.perform {}
      end
    end
  end

	def spawn resources, parent=nil
		ResqueJobsTree::Node.new self, resources, parent
	end

  def children &block
    @children ||= block
  end

	def perform &block
    @perform ||= block
	end

  def leaf?
		@node_children.empty?
  end

  def root?
    parent.nil?
  end

  def siblings
    root? ? [] : (parent.node_children - [self])
  end

  def find _name, first=true
    return self if name == _name.to_s
    node_children.inject(nil){|result,node| result ||= node.find(_name, false) } ||
      (first && raise(ResqueJobsTree::TreeDefinitionInvalid, "Cannot find node #{_name.inspect} in #{tree.name}"))
  end

  def validate!
    # Should have a child's naming [:job1, ...] and node children Proc implementation associated
    # node :job1 do
    #  perform {}
    # end
    # ...
    if (children.kind_of?(Proc) && node_children.empty?) || (children.nil? && !node_children.empty?)
      raise ResqueJobsTree::NodeDefinitionInvalid,
        "node `#{name}` from tree `#{tree.name}` should defines children and child nodes"
    end

    # Should have an implementation
    # node :job1 do
    #  perform {}
    # end
    if !perform.kind_of? Proc and !options.has_key? :triggerable
      raise ResqueJobsTree::NodeDefinitionInvalid,
        "node `#{name}` from tree `#{tree.name}` has no perform block"
    end

    # Naming Should be uniq
    if (tree.nodes - [self]).map(&:name).include? name
      raise ResqueJobsTree::NodeDefinitionInvalid,
        "node name `#{name}` is already taken in tree `#{tree.name}`"
    end

    # Recursive call for validate all of tree
    node_children.each &:validate!
  end

  def nodes
    node_children+node_children.map(&:nodes)
  end

  def inspect
    "<ResqueJobsTree::Node @name=#{name}>"
  end

end
