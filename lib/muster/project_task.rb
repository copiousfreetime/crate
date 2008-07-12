require 'rake'
require 'rake/tasklib'

module Muster
  class ProjectTask < ::Rake::TaskLib
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

    def initialize( name ) 
      raise "Muster Project already initialized" if ::Muster.project
      @name         = name
      @project_root = File.expand_path( File.dirname( Rake.application.rakefile ) )
      @recipe_dir   = File.join( @project_root, 'recipes' )
      @build_dir    = File.join( @project_root, 'build' )
      @install_dir  = File.join( @project_root, 'fakeroot' )
      yield self if block_given?
      ::Muster.project = self
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

    #
    # define the project task
    #
    def define
      desc "Build #{name}"
      task :build

      load_recipes
    end

    #
    # Load all .rake files that are in a recipe sub directory
    #
    def load_recipes
      Dir["#{recipe_dir}/*/*.rake"].each do |recipe|
        load recipe
      end
    end
  end
end
__END__

    def installed_recipes
      installed = []
      Dir.entries( build_dir ).each do |d|
        next if d.index(".") == 0
        installed_file = File.join( build_dir, d, ".installed" )
        if File.exist?( installed_file ) then
          installed << YAML::load_file( installed_file ) 
        end
      end
      return installed
    end

    def default_target( arg )
      @target = arg
    end

    def recipe_subdir( arg )
      @recipe_dir = File.expand_path( File.join( self.project_root, arg ) )
    end

    def build_subdir( arg )
      @build_dir = File.expand_path( File.join( self.project_root, arg ) )
    end

    def install_subdir( arg )
      @install_dir = File.expand_path( File.join( self.project_root, arg ) )
    end

    def run
      self.instance_eval File.read(@project_file), @project_file, 1
      Recipe.run File.expand_path( File.join( @recipe_dir, target, "#{target}.recipe" ) )
    end
  end
end
