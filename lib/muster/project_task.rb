require 'rake'

module Muster
  class ProjectTask < ::Rake::TaskLib
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
      @name        = name
      @project_dir = File.expand_path( File.dirname( Rake.application.rakefile )
      @recipe_dir  = 'recipe'
      @build_dir   = 'build'
      @install_dir = 'fakeroot'
      yield self if block_given?
    end
  end
end
__END__
    class << self
      def run( file )
        Project.new( file ).run
      end
    end

    attr_reader :project_root
    attr_reader :target
    attr_reader :recipe_dir
    attr_reader :build_dir
    attr_reader :install_dir

    def initialize( file )
      @project_file = File.expand_path( file )
      @project_root = File.dirname( @project_file )
      @recipe_dir = File.join( self.project_root, "recipes" )
      @build_dir  = File.join( self.project_root, "build" )
      @install_dir = File.join( self.project_root, "fakeroot" )
      ::Muster.project = self
    end

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
