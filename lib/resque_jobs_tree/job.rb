class ResqueJobsTree::Job

  class << self

    def perform *args
      node, resources = node_and_resources(args)
      node.perform.call resources
    end

    private

    def after_perform_enqueue_parent *args
      node, resources = node_and_resources(args)
      if node.root?
        ResqueJobsTree::Storage.release_launch node.tree, resources
      else
        ResqueJobsTree::Storage.remove(node, resources) do
          parent_job_args = ResqueJobsTree::Storage.parent_job_args node, resources
          Resque.enqueue_to node.tree.name, ResqueJobsTree::Job, *parent_job_args
        end
      end
    end

    def on_failure_cleanup exception, *args
      node, resources = node_and_resources args
      if node.options[:continue_on_failure]
        begin
          after_perform_enqueue_parent *args
        ensure
          ResqueJobsTree::Storage.failure_cleanup node, resources
        end
      else
        ResqueJobsTree::Storage.failure_cleanup node, resources, global: true
        node.tree.on_failure.call(resources) if node.tree.on_failure.kind_of?(Proc)
        raise exception
      end
    end

    def node_and_resources args
      tree_name , job_name = args[0..1]
      tree                 = ResqueJobsTree::Factory.find_tree_by_name tree_name
      node                 = tree.find_node_by_name job_name
      resources            = ResqueJobsTree::ResourcesSerializer.to_resources args[2..-1]
      [node, resources]
    end

  end

end
