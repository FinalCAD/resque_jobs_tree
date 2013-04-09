module ResqueJobsTree::Factory

  extend self

  def create name, &block
    @trees ||= []
    @trees.delete_if{|tree| tree.name == name.to_s}
    ResqueJobsTree::Tree.new(name).tap do |tree|
      @trees << tree
      tree.instance_eval &block
    end
  end

  def trees
    @trees
  end

  def find_tree_by_name name
    @trees.detect{ |tree| tree.name == name.to_s }
  end

end
