# ResqueJobsTree -- Resque jobs as a tree

To manage complexe background job processes, this gem simplify the task of creating
sequences of [Resque](https://github.com/resque/resque) jobs by putting them into a tree.

## Installation

Add this line to your application's Gemfile:

    gem 'resque'
    gem 'resque_jobs_tree'

And then execute:

    $ bundle

## Usage

Organise each sequences of jobs into a single file

``` ruby
    my_tree = ResqueJobsTree::Factory.create :my_complex_process do
      root :send_my_email do
        perform do |*args|
          # your code goes here...
        end
        childs do |resources|
          user = resources.first
          [].tap do |jobs|
            jobs << [:my_fetch_on_an_outside_slowish_api, user.company, user.group]
            user.comments.each do |comment|
              jobs << [:my_precomputation_of_data, comment]
            end
          end
        end
        node :my_fetch_on_an_outside_slowish_api do
          perform do |*args|
            # your code goes here...
          end
        end
        node :my_precomputation_of_data do
          perform do |*args|
            # your code goes here...
          end
        end
      end
    end

    my_tree.launch User.find(1)
```

This code is defining the tree, then when it launches the sequence of jobs, it:
* stocks in Redis all the Resque jobs which needs to be done including the needed parameters to run them.
* stocks in Redis the childhood relationsips between them.
* enqueues in Resque the jobs which are the nodes of the tree

Limitations:

* the name of a tree of jobs should be uniq
* the name of a node should be uniq in a scope of a tree.
* the running jobs are identified by a their tree, their name and their resources.
So they should not overlap. In other words, for the same node,
you can't enqueue 2 times `[:mail, User.first]`

Node options:

* `{ async: true }` if you need your process to wait for an outsider to continue.
* `{ continue_on_fail: true}` if your process can continue even after a fail during a job.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
