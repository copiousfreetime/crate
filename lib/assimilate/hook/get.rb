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
  module Hook
    class << self
      def recipe_path
        Assimilate.project.recipe_path
      end
    end
    
    class Recipe
      def self.run(file)
        new.run(file)
      end

      def initialize
        @hooked_in = false
        @commands = []
      end

      def run(file)
        file = File.expand_path(file)
        Dir.chdir(File.dirname(file)) {
          instance_eval File.read(file), file, 1
          hookin  unless hooked_in?
        }
      end

      def sh(*args)
        @commands << lambda {
          puts args.join(" ")
          system(*args)
        }
      end

      def build(*args)
        @commands << lambda { Dir.chdir(pkgpath) { sh(*args) } }
      end

      def darcs(repo, tag=nil)
        if tag
          sh "darcs", "get", "--partial", "--tag=#{tag}", repo, pkgpath
        else
          sh "darcs", "get", "--partial", repo, pkgpath
        end
      end

      def git(repo, head="HEAD")
        sh "git", "clone", "-n", repo, pkgpath
        sh "GIT_DIR=#{pkgpath} git checkout #{head}"
      end

      def svn(url)
        sh "svn", "co", "-q", url, pkgpath
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
        @pkgname = name
        @pkgversion = version
        @pkgpath = name + (version ? "-#{version}" : "")
      end

      def result( name )
        @result = name
      end

      attr_reader :pkgpath, :pkgversion, :pkgname
      def hooked_in?
        File.exist?( @result )
        @hooked_in
      end

      def hookin(name=pkgpath, paths=[pkgpath + "/lib"])
        until @commands.empty?
          l = @commands.shift
          l.call
        end
      end

      def depend(expr)
        installed = Hook::Database.installed
        package = expr[/^([\w-]*)(-[^-]*)?$/, 1]
        versions = installed.grep(/^#{package}(-[^-]*)?$/)

        chosen = choose_version(expr, versions)
        if chosen
          puts "dependency #{expr} satisfied: found #{chosen}"
        else
          available = {}
          p Dir.pwd
          Dir["{#{.join(",")}}/#{package}/#{package}*.rport"].each { |port|
            available[File.basename(port, ".rport")] = port
          }
          to_install = choose_version(expr, available.keys)
          if to_install
            puts "hook-get #{to_install}  # satisfies #{expr}"
            HookGet.run available[to_install]
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
end
