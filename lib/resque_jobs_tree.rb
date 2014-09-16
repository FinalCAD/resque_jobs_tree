require "resque_jobs_tree/version"
require 'resque'

require 'resque_jobs_tree/storage'
require 'resque_jobs_tree/storage/tree'
require 'resque_jobs_tree/storage/node'

require 'resque_jobs_tree/factory'
require 'resque_jobs_tree/tree'
require 'resque_jobs_tree/node'
require 'resque_jobs_tree/job'
require 'resque_jobs_tree/resources_serializer'
require 'resque_jobs_tree/storage'

require 'resque_jobs_tree/definitions'
require 'resque_jobs_tree/definitions/tree'
require 'resque_jobs_tree/definitions/node'

module ResqueJobsTree
  extend self
  class TreeDefinitionInvalid < Exception ; end
  class NodeDefinitionInvalid < Exception ; end
  class JobNotUniq            < Exception ; end

  def find name
    Factory.find name.to_s
  end

  def launch name, *resources
    tree_definition = find name
    raise("Can't find tree `#{name}`") unless tree_definition
    tree_definition.spawn(resources).launch
  end

  def create *resources
    Factory.create(*resources)
  end
end
