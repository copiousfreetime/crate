require 'main'
require 'muster/command'
module Muster
  ##
  # ::Main.create creates a class that does command line parsing
  #
  CommandLine = ::Main.create {
    author "Copyright (c) 2008 Jeremy Hinegardner"
    version ::Muster::Version.to_s

    description <<-txt
    The Muster command line tool for generating custom static ruby builds.

    run 'muster help modename' for more info
    txt

    examples <<-txt
      . muster init project
      . muster build
    txt

    run { help! }

    ## initialize a new muster project
    mode( "init" ) {
      description <<-txt
      Create a new muster based project.
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

      run { Muster::Commands::Init.new( CommandLine.params_to_options( params ) ).run }
    }

    ## build the project
    mode( "build" ) {
      description <<-txt
      Build the muster project.
      txt

      option( :directory ) {
        argument :required
        description "A directory with an 'Muster' file in int"
        default Dir.pwd
        validate { |d| File.exist?( File.join( d, "Muster") ) }
      }

      run { Muster::Commands::Build.new( CommandLine.params_to_options( params ) ).run }
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
