module ResqueJobsTree::ResourcesSerializer

  extend self

  # in: [<Localisation id=1>, :pdf]
  # out: [[Localisation, 1], :pdf]
  def to_args resources
    resources.to_a.map do |resource|
      resource.respond_to?(:id) ? [resource.class.name, resource.id] : resource
    end
  end

  # in: [['Localisation', 1], :pdf]
  # out: [<Localisation id=1>, :pdf]
  def to_resources args
    args.to_a.map do |arg|
      if arg.kind_of? Array
        eval(arg[0]).find(arg[1]) rescue arg
      else
        arg
      end
    end
  end

end
