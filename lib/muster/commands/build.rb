require 'muster/project'
module Muster::Commands
  class Build < ::Muster::Command
    def initialize( opts = {} )
      @directory = opts['directory']
    end
    def run_command
      Dir.chdir( @directory ) do
        Muster::Project.run( File.join( @directory, "Muster" ) )
      end
    end
  end
end
