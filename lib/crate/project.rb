require 'rake'
require 'rake/tasklib'

module Crate
  #
  # the Crate top level task, there should only be one of these in existence at
  # a time.  This task is accessible via Crate.project, and is what is defined
  # in the Rakefile in the project directory.
  #
  class Project < ::Rake::TaskLib
    # Name of the project
    attr_reader :name

    # Top level directory of the project. 
    attr_reader :project_root

    # subdirectory of +project_root+ in which the recipe's are stored.
    # default: 'recipes'
    attr_accessor :recipe_dir

    # subdirectory of +project_root+ where recipes' are built. default: 'build'
    attr_accessor :build_dir

    # subdirectory of +project_root+ representing a fake installation root.
    # default 'fakeroot'
    attr_accessor :install_dir

    # The list of extensions to compile
    attr_reader :extensions

    def initialize( name ) 
      raise "Crate Project already initialized" if ::Crate.project
      @name         = name
      @project_root = File.expand_path( File.dirname( Rake.application.rakefile ) )
      @recipe_dir   = File.join( @project_root, 'recipes' )
      @build_dir    = File.join( @project_root, 'build' )
      @install_dir  = File.join( @project_root, 'fakeroot' )
      yield self if block_given?
      ::Crate.project = self
      define
    end

    def recipe_dir=( rd )
      @recipe_dir = File.join( project_root, rd )
    end

    def build_dir=( bd )
      @build_dir = File.join( project_root, bd)
    end

    def install_dir=( id )
      @install_dir = File.join( project_root, id )
    end

    def extensions=( list )
      @extensions = list.select { |l| l.index("#").nil? }
    end

    #
    # Create a logger for the project
    #
    def logger
      unless @logger 
        @logger = Logging::Logger[name]
        @logger.level = :debug
        @logger.add_appenders

        @logger.add_appenders( 
            Logging::Appenders::File.new( File.join( project_root, "project.log" ), :layout => Logging::Layouts::Pattern.new( :pattern => "%d %5l: %m\n" )),
            Logging::Appenders::Stdout.new( 'stdout', :level => :info,
                                          :layout => Logging::Layouts::Pattern.new( :pattern      => "%d %5l: %m\n",
                                                                                    :date_pattern => "%H:%M:%S") )
        )
      end
      return @logger
    end

    #
    # define the project task
    #
    def define
      desc "Build #{name}"
      task :default => [ :ruby, main_c ] do 
        logger.info "Build #{name}"
        #logger.info ::Crate.ruby.inspect 
      end
      ::CLEAN << self.install_dir
      ::CLEAN << "project.log"
      load_rakefiles
    end

    #
    # Load all .rake files that are in a recipe sub directory
    #
    def load_rakefiles
      Dir["#{recipe_dir}/*/*.rake"].each do |recipe|
        logger.debug "loading #{recipe}"
        import recipe
      end
    end
  end
end
