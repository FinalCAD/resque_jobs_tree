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
      if block_given?
        node.instance_eval &block
      elsif options.has_key? :triggerable
        node.perform {}
      end
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

  def find _name, first=true
    return self if name == _name.to_s
    node_childs.inject(nil){|result,node| result ||= node.find(_name, false) } ||
      (first && raise(ResqueJobsTree::TreeDefinitionInvalid, "Cannot find node #{_name} in #{tree.name}"))
  end

  def validate!
    # Should have a child's naming [:job1, ...] and node childs Proc implementation associated
    # node :job1 do
    #  perform {}
    # end
    # ...
    if (childs.kind_of?(Proc) && node_childs.empty?) || (childs.nil? && !node_childs.empty?)
      raise ResqueJobsTree::NodeDefinitionInvalid,
        "node `#{name}` from tree `#{tree.name}` should defines childs and child nodes"
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

    # Only one job can be trigger tree
    if node_childs.select { |entry| entry.options.has_key?(:triggerable) }.size > 1
      raise ResqueJobsTree::NodeDefinitionInvalid,
        "Only one job must be declared to be triggerable into an definition, tree `#{tree.name}`"
    end

    # Recursive call for validate all of tree
    node_childs.each &:validate!
  end

  def nodes
    node_childs+node_childs.map(&:nodes)
  end

  def inspect
    "<ResqueJobsTree::Node @name=#{name}>"
  end

end
