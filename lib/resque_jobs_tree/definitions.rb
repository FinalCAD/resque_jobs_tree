class ResqueJobsTree::Definitions

  def on_failure &block
    @on_failure ||= block
  end
	
	def before_perform &block
    @before_perform ||= block
	end

	def after_perform &block
    @after_perform ||= block
	end

end
