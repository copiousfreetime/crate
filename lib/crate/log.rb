require 'logging'
require 'crate'

module Crate

  ::Logging::Logger[self].level = :info

  # Return the top level logger, initializing the Crate logging system if
  # necessary.
  def self.logger
    Crate::Log.init unless Crate::Log.initialized?
    self._logger
  end

  def self._logger # :nodoc:
    ::Logging::Logger[self]
  end

  module Log

    # Initialize the top level logger.  This should not be done until after
    # the global configuration is parsed and loaded
    def init

      if defined? @initialized and ( not @appender.nil? ) then
        Crate._logger.remove_appenders( @appender )
        @appender.close
        @appender = nil
      end

      # TODO move these into a crate commandline
      #FileUtils.mkdir_p( directory ) unless File.directory?( directory )
      #Crate.logger.add_appenders( self.appender )
      #Crate.logger.info "Crate version #{Crate::VERSION}"
      #self.level = configuration.level
      Crate._logger.add_appenders( Logging::Appender.stdout )
      Logging::Appender.stdout.layout = self.console_layout
      Logging::Appender.stdout.level = :info

      @initialized = true
    end

    def silence!
      Logging::Appender.stdout.level = :off
    end

    def initialized?
      @initialized
    end

    def configuration
      @configuration ||= ::Configuration.for("logging")
    end

    def level
      ::Logging::Logger[Crate].level
    end

    def level=( l )
      ::Logging::Logger[Crate].level = l
      appender.level = l
    end

    def console=( level )
      Logging::Appender.stdout.level = level
    end

    def default_directory
      configuration.dirname || ::Crate::Paths.log_path
    end


    def directory
      @directory ||= default_directory
      if @directory != default_directory then
        # directory has changed on us
        @directory = default_directory
      end
      return @directory
    end

    def filename
      File.join( self.directory, ( configuration.filename || "crate.log" ) )
    end

    def layout
      @layout ||= Logging::Layouts::Pattern.new(
        :pattern      => "[%d] %5l %6p %c : %m\n",
        :date_pattern => "%Y-%m-%d %H:%M:%S"
      )
    end

    def appender
      @appender ||= ::Logging::Appenders::RollingFile.new(
          'crate',
          :filename => self.filename,
          :layout   => self.layout,
          :size     => 1024**2 * 25 # 25 MB
      )
    end

    def console_layout
      @console_layout ||= Logging::Layouts::Pattern.new(
        :pattern      => "%d %5l : %m\n",
        :date_pattern => "%H:%M:%S"
      )
    end

    extend self

  end
end
