require 'crate/dependency'
require 'crate/gem_integration'

module Crate
  class Ruby < Dependency
    #
    # Create a Crate Ruby with the given name and version
    #
    def initialize( name = nil, version = nil )
      @name = name
      @version = version
      @install_commands = []
      @build_commands = []
      yield self if block_given?
      @upstream_source = URI.parse( @upstream_source )
      define unless name.nil? or version.nil?
      ::Crate.ruby = self
    end


    #
    # Define all the tasks in the namespace of the +name+ of this task.
    #
    # The dependency chain is:
    #
    #   :install => :build => :integration => :extensions => :patch => :unpack => :verify => :download
    #
    #
    def define
      logger.debug "Defining tasks for #{name} #{version}"

      namespace name do
        define_download
        define_verify
        define_unpack
        define_patch
        define_extensions
        define_integration

        desc "Integrate ruby modules into final source" 
        task :integration => "#{name}:patch"
        file dotfile('build') => "#{name}:integration"


        define_build

        define_install

        task :done    => "#{name}:install"
        task :default => "#{name}:done"
      end

      desc "Build and Integrate #{name} #{version}"
      task name => "#{name}:default"
    end

    def lib_dir
      File.join( pkg_dir, "lib" )
    end

    def ext_dir
      File.join( pkg_dir, "ext" )
    end

    def ext_setup_file
      File.join( ext_dir, "Setup" )
    end

    # 
    # Define the task that overwrites the ext/Setup file
    #
    def define_extensions
      desc "Overwrite the ext/Setup file"
      task :extensions => "#{name}:patch" do
        logger.info "Rewriting ext/Setup file"
        File.open( ext_setup_file, "w") do |f|
          f.puts "option nodynamic"
          f.puts
          ::Crate.project.extensions.each do |e|
            f.puts e
          end
        end
      end
    end

    #
    # Add in an integration task that depends on all the Integeration object's
    # name:default task
    #
    def define_integration
    end

    def integrates( other )
      task "#{name}:integration" => "#{other}:integration"
      task "#{other}:integration" => "#{name}:extensions"
    end
  end
end
