require 'rbconfig'

module Crate

  # Crate::Ify::manifest analyze and setup an existing gem or projct into a crateified system
  # Manage the anlysis and setup of an existing gem or project into a crateified
  # system.
  #
  # When called from the commandline, There is a single required parameter.  The
  # name of gem, the gem file, or the application directory.  Generally
  # executed as :
  #
  #   crateify somegem-1.0.0.gem # A gem that exists on the commandline
  #   crateify mygem             # this will look for it in repositories
  #   crateify ./myapp           # Crateify the given directory
  #
  class Ify < ::Crate::Task
    # The version of ruby in which to run the application.
    config 'target_ruby', "1.8.6"

    # The target platform on which the application will run.
    config 'target_platform', ::Config::CONFIG['arch']

    # define :identify_source,  IdentifySource, { :source => process_arg }
    # define :setup_

    def process( gem_or_dir )
      logger.info "Crateifing #{gem_or_dir}"
    end

    def workflow
    end

  end

  # put a handle into the top level.
  def self.ify( argv = ARGV )
    Ify.execute( argv )
  end
end
