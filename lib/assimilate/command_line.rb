require 'main'
require 'assimilate/command'
module Assimilate
  ##
  # ::Main.create creates a class that does command line parsing
  #
  CommandLine = ::Main.create {
    author "Copyright (c) 2008 Jeremy Hinegardner"
    version ::Assimilate::Version.to_s

    description <<-txt
    The Assimilate command line tool for generating custom static ruby builds.

    run 'assimilate help modename' for more info
    txt

    examples <<-txt
      . assimilate init project
      . assimilate build
    txt

    run { help! }

    ## initialize a new assimilate project
    mode( "init" ) {
      description <<-txt
      Create a new assimilate based project.
      txt

      argument( :project ) { 
        required
        description "the name of the project"
      }

      option( :directory ) {
        argument :required
        description "The parent directory of the project"
        default Dir.pwd
        validate { |d| File.directory?( d ) }
      }

      run { Assimilate::Commands::Init.new( CommandLine.params_to_options( params ) ).run }
    }

    ## build the project
    mode( "build" ) {
      description <<-txt
      Build the assimilate project.
      txt

      option( :directory ) {
        argument :required
        description "A directory with an 'Assimilate' file in int"
        default Dir.pwd
        validate { |d| File.exist?( File.join( d, "Assimilate") ) }
      }

      run { Assimilate::Commands::Build.new.run }
    }
  }

  #
  # Convert the Parameters::List that exists as the parameters from Main
  #
  def CommandLine.params_to_options( params )
    ( opts = params.to_hash ).keys.each { |key| opts[key] = opts[key].value }
    return opts
  end
end
