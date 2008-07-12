require 'muster/dependency'
module Muster
  class GemIntegration < Dependency
    #
    # Define all the tasks in the namespace of the +name+ of this task.
    #
    # The dependency chain is:
    #
    #   :integrate => :patch => :unpack => :verify => :download
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

        task :done    => "#{name}:integrate"
        task :default => "#{name}:done"
      end

      desc "Build and Integrate #{name} #{version}"
      task name => "#{name}:default"
    end

    #
    # Define how the gem integrates into the ruby installation
    #
    def define_integration
      desc "Integrate #{name} into ruby's build tree"
      task :integration => [ "#{name}:patch", "ruby:patch" ] do
        logger.info "Integrating #{name} into ruby's tree"
      end
    end
  end
end
