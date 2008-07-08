#++
# HookGet is originally :
#
# Copyright (C) 2008  Christian Neukirchen <http://purl.org/net/chneukirchen>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#--
#
# Customizations added for Assimilate integration by Jeremy Hinegardner
#

module Assimilate
  class Recipe
    def self.run(file)
      new.run(file)
    end

    def initialize
      @build_commands = []
      @install_commands = []
    end

    def run(file)
      file = File.expand_path(file)
      build_dir = File.join(Assimilate.build_dir, File.basename( file, ".recipe" ))
      Dir.chdir( build_dir ) do
        instance_eval File.read(file), file, 1
        hookin  unless hooked_in?
      end
    end

    def recipe_dir
      Assimilate.project.recipe_dir
    end

    def dest_dir
      Assimilate.project.dest_dir
    end

    def sh(*args)
      @build_commands << lambda {
        puts args.join(" ")
        system(*args)
      }
    end

    def build(*args)
      @build_commands << lambda { Dir.chdir(pkgpath) { sh(*args) } }
    end

    def install(*args) 
      @install_commands << lambda{ Dir.chdir( pkgpath ) { sh(*args) } } 
    end

    def source( url )
      @url = url
    end
    
    def tar_gz(url)
      sh "curl -L #{url} | tar xz"
    end

    def tar_bz2(url)
      sh "curl -L #{url} | tar xj"
    end

    def gem(url)
      sh "mkdir -p #{pkgpath} && curl -L #{url} | tar xO data.tar.gz | tar xzm -C #{pkgpath}"
    end

    def package(name, version=nil)
      @pkgname    = name
      @pkgversion = version
      @pkgpath    = name + (version ? "-#{version}" : "")
    end

    attr_reader :pkgpath, :pkgversion, :pkgname
    def installed?
      File.exist?( File.join( pkgpath, ".installed" )
    end

    def hookin(name=pkgpath, paths=[pkgpath + "/lib"])
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

    def depend(expr)
      installed = Assimilate.project.installed_recipes
      package = expr[/^([\w-]*)(-[^-]*)?$/, 1]
      versions = installed.grep(/^#{package}(-[^-]*)?$/)

      chosen = choose_version(expr, versions)
      if chosen
        puts "dependency #{expr} satisfied: found #{chosen}"
      else
        available = {}
        p Dir.pwd
        Dir["#{Assimilate.project.recipe_dir}/#{package}/#{package}*.recipe"].each { |recipe|
          available[File.basename(port, ".recipe")] = recipe
        }
        to_install = choose_version(expr, available.keys)
        if to_install
          puts "recipe  #{to_install}  # satisfies #{expr}"
          Recipe.run available[to_install]
        else
          if available.empty?
            abort "can't find any package for #{expr}"
          else
            abort "version conflict: unable to satisfy #{expr}"
          end
        end
      end
    end

    def version2array(version)
      if version =~ /\d+(\.\d+)*$/
        $&.split('.').map { |f| f.to_i }
      else
        [1.0/0]                   # Infinity
      end
    end

    def choose_version(expr, available)
      min, max = expr.split("...", 2)
      max ||= min
      min = version2array min
      max = version2array max

      # just "pkg" means "any version"
      min = [-1.0/0]  if min == [1.0/0]
      if max == [1.0/0]
        range = min..max
      else
        max[-1] += 1
        range = min...max         # Exclusive!
      end

      available.select { |v| range.include? version2array(v) }.
        sort_by { |v| version2array(v) }.
        last
    end
  end
end
