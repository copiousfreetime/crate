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

    def process( gem_or_dir )
      if stat = File.stat( gem_or_dir ) then
        if stat.file? and File.extname( gem_or_dir ) == ".gem" then
          self.seq( ::Crate::Task::Unpack.new( :file => gem_or_dir ) )
        elsif stat.directory? then
          self.enq( ::Crate::Task::InstallCratefile.new( :directory => gem_or_dir ) )

          logger.info "crateify directory #{gem_or_dir}"
        else
          raise ArgumentError, "#{gem_or_dir} is not a gem or a directory"
        end
      else
        logger.info "crateify remote gem #{gem_or_dir}"
      end
    end

    def workflow
      fetch_start = ::Crate::Task::FetchGem.new
      fetch_start.sequence(
        ::Crate::Task::Unpack.new,
        ::Crate::Task::InstallCratefile.new )

      unpack_start = ::Crate::Task::Unpack.new
      unpack_start.sequence( ::Crate::Task::InstallCratefile.new )

      install_start = ::Crate::Task::InstallCratefile.new

      switch( fetch_start, unpack_start, install_start) do |audit|
        case audit.trail.last.value
        when :remote_gem
          return 0
        when :local_gem
          return 1
        end

      end
    end

  end

  # put a handle into the top level.
  def self.ify( argv = ARGV )
    Ify.execute( argv )
  end
end
