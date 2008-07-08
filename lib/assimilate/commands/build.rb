require 'assimilate/project'
module Assimilate::Commands
  class Build < ::Assimilate::Command
    def initialize( opts = {} )
      @directory = opts['directory']
    end
    def run_command
      Dir.chdir( @directory ) do
        Assimilate::Project.run( File.join( @directory, "Assimilate" ) )
      end
    end
  end
end
