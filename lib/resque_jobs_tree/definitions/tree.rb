class ResqueJobsTree::Definitions::Tree < ResqueJobsTree::Definitions

  attr_accessor :name, :root

  def initialize name
    @name = name
  end

	def spawn resources
		ResqueJobsTree::Tree.new self, resources
	end

  def root name=nil, &block
    @root ||= Node.new(name, self).tap do |root|
      root.instance_eval &block
    end
  end

  def find name
    root.find name.to_s
  end

  def validate!
		if @root
			root.validate!
		else
    	raise ResqueJobsTree::TreeDefinitionInvalid, "`#{name}` has no root node"
		end
  end

  def nodes
    [root, root.nodes].flatten
  end

  def inspect
    "<ResqueJobsTree::Definitions::Tree @name=#{name}>"
  end

end
