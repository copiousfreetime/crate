#
# Recipe is heavily inspired by HookGet 
#
#   http://github.com/chneukirchen/rubyports/tree/master/hook-get.rb
#
module Assimilate
  class Recipe
    def self.run(file)
      new.run( file )
    end
    
    attr_reader :version
    attr_reader :name
    attr_reader :file
    attr_reader :build_dir
    attr_reader :build_commands
    attr_reader :install_commands
    attr_reader :dependencies
    attr_reader :pkg_dir
    attr_reader :url

    def initialize
      @build_commands   = []
      @install_commands = []
      @dependencies     = []
    end

    def run( file )
      @file = File.expand_path(file)
      @build_dir = File.join(Assimilate.project.build_dir, File.basename( file, ".recipe" ))
      FileUtils.mkdir_p self.build_dir, :verbose => true
      Dir.chdir( self.build_dir ) do
        self.instance_eval File.read(file), file, 1
        deploy
      end
    end

    def recipe_dir
      Assimilate.project.recipe_dir
    end

    def install_dir
      Assimilate.project.install_dir
    end

    def sh(*args)
      @build_commands << lambda {
        puts args.join(" ")
        system(*args)
      }
    end

    def build(*args)
      @build_commands << lambda { Dir.chdir( pkg_dir ) { sh(*args) } }
    end

    def install(*args) 
      @install_commands << lambda{ Dir.chdir( pkg_dir ) { sh(*args) } } 
    end

    def upstream_source( url )
      @url = url
    end
    
    def package(name, version=nil)
      @name    = name
      @version = version
      @pkg_dir = File.join( build_dir, "#{name + ( version ? "-#{version}" : "" ) }" )
    end

    def depend(name, version)
      @dependencies << { :name => name, :version => version }
    end

    private

    def tar_gz(url)
      sh "curl -L #{url} | tar xz"
    end

    def tar_bz2(url)
      sh "curl -L #{url} | tar xj"
    end

    def gem(url)
      sh "mkdir -p #{pkg_dir} && curl -L #{url} | tar xO data.tar.gz | tar xzm -C #{pkg_dir}"
    end


    def installed?
      File.exist?( File.join( self.build_dir, ".installed" ) )
    end

    def deploy
      satisfy_dependencies
      download
      verify
      unpack
      patch
      until @build_commands.empty?
        l = @build_commands.shift
        l.call
      end

      until @install_commands.empty?
        l = @install_commands.shift
        l.call
      end
      File.open( File.join( pkgpath, ".installed") , "w") { |f| f.puts Time.now }
    end


    def satisfy_dependencies
      installed = Assimilate.project.installed_recipes
      @dependencies.each do |dep|
        satisfied = false
        installed.each do |recipe|
          if (recipe[:name] == dep[:name]) and  (dep[:version] == recipe[:version] ) then
            satisfied = true
            break
          end
        end
        Recipe.run File.join( recipe_dir, "#{dep[:name]}.recipe" ) unless satisfied
      end
    end

    def download
      puts "fetching #{url}"
    end

    def verify
      puts "verifying #{url} if there is a checksum"
    end

    def unpack
      puts "unpacking #{url}"
    end
    
    def patch
      puts "patching #{url}"
    end
  end
end
