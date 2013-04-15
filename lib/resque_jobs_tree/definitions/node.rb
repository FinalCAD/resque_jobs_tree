class ResqueJobsTree::Definitions::Node < ResqueJobsTree::Definitions

  attr_accessor :tree, :parent, :name, :node_childs, :options

  def initialize name, tree, parent=nil
    @tree        = tree
    @name        = name.to_s
    @parent      = parent
    @node_childs = []
    @options     = {}
  end

  def node name, options={}, &block
    ResqueJobsTree::Definitions::Node.new(name, tree, self).tap do |node|
      node.options = options
      @node_childs << node
      node.instance_eval(&block) if block_given?
    end
  end

	def spawn resources, parent=nil
		ResqueJobsTree::Node.new self, resources, parent
	end

  def childs &block
    @childs ||= block
  end

	def perform &block
    @perform ||= block
	end

  def leaf?
		@node_childs.empty?
  end

  def root?
    parent.nil?
  end

  def siblings
    root? ? [] : (parent.node_childs - [self])
  end

  def find _name
    if name == _name.to_s
      self
    else
      node_childs.inject(nil){|result,node| result ||= node.find _name }
    end
  end

  def validate!
    if (childs.kind_of?(Proc) && node_childs.empty?) || (childs.nil? && !node_childs.empty?)
      raise ResqueJobsTree::NodeDefinitionInvalid,
        "node `#{name}` from tree `#{tree.name}` should defines childs and child nodes"
    end
    unless perform.kind_of? Proc
      raise ResqueJobsTree::NodeDefinitionInvalid,
        "node `#{name}` from tree `#{tree.name}` has no perform block"
    end
    if (tree.nodes - [self]).map(&:name).include? name
      raise ResqueJobsTree::NodeDefinitionInvalid,
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
