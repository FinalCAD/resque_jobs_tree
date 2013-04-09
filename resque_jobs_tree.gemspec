# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'resque_jobs_tree/version'

Gem::Specification.new do |spec|
  spec.name          = "resque_jobs_tree"
  spec.version       = ResqueJobsTree::VERSION
  spec.authors       = ["Antoine Qu'hen"]
  spec.email         = ["antoinequhen@gmail.com"]
  spec.description   = %q{To manage complexe background job processes, this gem simplify the task of creating sequences of Resque jobs by putting them into a tree.}
  spec.summary       = %q{Organise Resque jobs as a tree.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'mock_redis'
  spec.add_dependency 'resque', '~> 1.24'
end
