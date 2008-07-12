require 'muster/dependency'
require 'muster/gem_integration'

module Muster
  class Ruby < Dependency
    #
    # Define all the tasks in the namespace of the +name+ of this task.
    #
    # The dependency chain is:
    #
    #   :install => :build => :integration => :patch => :unpack => :verify => :download
    #
    #
    def define
      logger.debug "Defining tasks for #{name} #{version}"

      namespace name do
        define_download
        define_verify
        define_unpack
        define_patch
        define_integration

        define_build
        task :build => "#{name}:integration"

        define_install

        task :done    => "#{name}:install"
        task :default => "#{name}:done"
      end

      desc "Build and Integrate #{name} #{version}"
      task name => "#{name}:default"
    end


    #
    # Add in an integration task that depends on all the Integeration object's
    # name:default task
    #
    def define_integration
      desc "Integrate ruby modules into final source" 
      task :integration => "#{name}:patch"
    end

    def integrates( other )
      task "#{name}:integration" => "#{other}:integration"
    end
  end
end
