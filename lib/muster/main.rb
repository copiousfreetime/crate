require 'muster'

require 'rubygems'
require 'optparse'
require 'find'
require 'fileutils'

module Muster
  # The Muster::Main class contains all the functionality needed by the +muster+
  # command line application.  Much of this code is derived from the Webby::Main
  # class
  class Main

    # Directory where the Muster project will be created
    attr_accessor :project

    # Directory where the template Muster project is located
    attr_accessor :data

    #
    # Create a new instance of Muster and run with the command line _args_.
    #
    def self.run( args )
      m = self.new
      m.parse( args )
      m.create_project
    end

    #
    # Create a new Muster object
    #
    def initialize
      @log = Logging::Logger[self]
    end

    #
    # The option parser for Muster
    #
    def option_parser
      OptionParser.new do |op|
        op.banner << "  project"

        op.separator ""
        op.separator "common options:"
        op.on_tail( "-h", "--help", "show this message") do
          puts op
          exit 0
        end

        op.on_tail( "--version", "show version" ) do
          puts "Muster #{::Muster::VERSION}"
          exit 0
        end
      end
    end

    # 
    # Parse the command line arguments
    #
    def parse( argv )
      self.data = ::Muster.data_path
      opts = option_parser
      begin
        opts.parse!( argv )
        self.project = argv.shift

        if project.nil?
          puts opts
          exit 1
        end
      rescue ::OptionParser::ParseError => pe
        puts "#{opts.program_name}: #{pe}"
        puts "Try `#{opts.program_name} --help` for more information"
        exit 1
      end
    end

    #
    # Create a new Muster project
    #
    def create_project
      abort "'#{project}' already exists" if File.exist?( project )

      # copy over files from the master project data diretory in muster
      files = project_files
      files.keys.sort.each do |dir|
        mkdir dir
        files[dir].sort.each do |file|
          cp file 
        end
      end
    end

    #
    # Make a directory in the specified directory under the project directory
    # and display a message on the screen indicating that the directory is being
    # created.
    #
    def mkdir( dir )
      dir = dir.empty? ? project : ::File.join( project, dir )
      unless File.directory?( dir )
        creating dir
        FileUtils.mkdir_p dir
      end
    end

    #
    # Copy a file from the Muster prototype location to the project location.
    # Display a message that the file is being created.
    #
    def cp( file )
      src = ::File.join( data, file )
      dest = ::File.join( project, file )
      creating dest
      FileUtils.cp( src, dest )
    end

    #
    # log a creating message
    #
    def creating( msg )
      @log.info "creating #{msg}"
    end

    #
    # log a fatal message and abort
    #
    def abort( msg )
      @log.fatal msg
      exit 1
    end

    #
    # Iterate over all the feils in the Muster project template directory and
    # store them in a hash
    #
    def project_files
      keep       = %r/.rake$|Rakefile$/
      strip_path = %r/\A#{data}?/o
      paths      = Hash.new { |h,k| h[k] = [] }
      Find.find( data ) do |path|
        next unless keep =~ path

        if File.directory?( path ) then
          paths[ path.sub( strip_path, '' ) ]
          next
        end
        dir = ::File.dirname( path ).sub( strip_path, '' )
        paths[dir] << path.sub( strip_path, '' )
      end

      return paths
    end
  end
end
