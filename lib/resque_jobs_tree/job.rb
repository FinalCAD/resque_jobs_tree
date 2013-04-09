class ResqueJobsTree::Job

  class << self

    def perform *args
      tree, node, resources = tree_node_and_resources(*args)
      node.perform.call resources
    end

    private

    def after_perform_enqueue_parent *args
      tree, node, resources = tree_node_and_resources(*args)
      unless node.root?
        parent_job_args = ResqueJobsTree::Storage.parent_job_args node, resources
        ResqueJobsTree::Storage.remove(node, resources) do
          Resque.enqueue_to tree.name, ResqueJobsTree::Job, *parent_job_args
        end
      end
    end

    def tree_node_and_resources *args
      tree_name , job_name = args.shift(2)
      tree                 = ResqueJobsTree::Factory.find_tree_by_name tree_name
      node                 = tree.find_node_by_name job_name
      resources            = ResqueJobsTree::ResourcesSerializer.to_resources args
      [tree, node, resources]
    end

  end

end
