module ResqueJobsTree::Factory
  extend self

  def create name, &block
    name = name.to_s
    @trees ||= {}
    ResqueJobsTree::Definitions::Tree.new(name).tap do |tree|
      tree.instance_eval &block
      tree.validate!
      @trees[name] = tree
    end
  end

  def trees
    @trees ||= {}
  end

  def find name
    trees[name.to_s]
  end

end
