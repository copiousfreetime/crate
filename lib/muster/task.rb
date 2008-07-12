require 'rake'
require 'rake/tasklib'
require 'open-uri'
require 'progressbar'
require 'zlib'
require 'archive/tar/minitar'

module Muster
  # Create a build task that will download, checksum and build and install an
  # upstream source
  #
  # This task will create the following targets:
  #
  class Task < ::Rake::TaskLib
    # Name of the task, this is also the Rake namespace underwhich all other
    # tasks will follow
    attr_accessor :name

    # Version of the upstream version
    attr_accessor :version

    # Upstream location 
    attr_accessor :upstream_source

    #
    # Create a Muster Task with the given name and version
    #
    def initialize( name = nil, version = nil )
      @name = name
      @version = version
      yield self if block_given?
      @upstream_source = URI.parse( @upstream_source )
      define unless name.nil? or version.nil?
    end

    # 
    # The build directory for this particular task
    #
    def build_dir
      @build_dir ||= File.join(Muster.project.build_dir, name )
    end

    #
    # The recipe directory for this particular task
    #
    def recipe_dir
      @recipe_dir ||= File.join( Muster.project.dir, name )
    end

    #
    # The fake root directory to install into
    # 
    def install_dir
      Muster.project.install_dir
    end

    #
    # The directory this task unpacks into
    #
    def pkg_dir
      @pkg_dir ||= File.join( self.build_dir, "#{name + ( version ? "-#{version}" : "" ) }" )
    end

    #
    # override the directory that the local source unpacks into if it is not
    # +name-version+
    #
    def pkg_dir=( pd )
      @pkg_dir = File.join( self.build_dir, pd )
    end

    #
    # The local on disk copy of the upstream source
    #
    def local_source
      @local_source ||= File.join( build_dir, File.basename( upstream_source.path ) )
    end

    #
    # record the upstream sha1 checksum
    #
    def upstream_sha1=( checksum )
      @checksum = [ ::Digest::SHA1.new, checksum ]
    end
    def upstream_sha1; return @checksum.last ; end

    #
    # record the upstream md5 checksum
    #
    def upstream_md5=( checksum )
      @checksum = [ ::Digest::MD5.new, checksum ]
    end
    def usptream_md5; return @checksum.last ; end

    #
    # Define all the subtasks
    #
    def define
      namespace name do

        file local_source do
          download
        end

        desc "Download #{File.basename( local_source )}"
        task :download => local_source

        desc "Verify source against checksum #{@checksum.last}"
        task :verify => :download do
          raise "#{local_source} does not have checksum #{@checksum.last}"  unless verify
        end

        desc "Unpack #{name} into #{build_dir}"
        task :unpack => :verify do
          unpack
        end

        desc "patch #{name}"
        task :patch => :unpack do
        end

        file built_dotfile => :patch do
          Dir.chdir( pkg_dir ) do
            build
          end
          h = { 'name' => self.name, 'version' => self.version, 'built_at' => Time.now }
          File.open( built_dotfile, "w") { |f| f.puts h.to_yaml }
        end


        desc "Build #{name} #{version}"
        task :build => built_dotfile

        file installed_dotfile => :build do 
          Dir.chdir( pkg_dir ) do
            install
          end
          h = { 'name' => self.name, 'version' => self.version, 'installed_at' => Time.now }
          File.open( installed_dotfile, "w") { |f| f.puts h.to_yaml }
        end

        desc "Install #{name} into #{Muster.project.install_dir}"
        task :install => installed_dotfile do
        end

      end
    end

    def built_dotfile
      File.join( build_dir, ".built" )
    end

    def installed_dotfile
      File.join( build_dir, ".installed" )
    end

    #
    # allow this task to say it depends on something else
    #
    def depends_on( other_task )
      namespace name do
        task :install => "#{other_task}:install"
      end
    end

    #
    # download the +upstream_source+ and save it to +local_source+
    #
    def download
      progress_bar = nil
      pbar = nil 
      FileUtils.mkdir_p File.dirname( local_source ) 
      File.open( local_source , "w" ) do |outf|
        begin
          upstream_source.open( :content_length_proc => lambda { |t| pbar = ::ProgressBar.new( File.basename( local_source ), t ) if  t && 0 < t  },  
                                :progress_proc       => lambda { |s| pbar.set s if pbar } ) do |inf|
            outf.write inf.read
          end 
        rescue => e
          puts
          STDERR.puts "Error downloading #{upstream_source.to_s} : #{e}"
          exit 1
        end
      end
    end

    #
    # verify the +local_source+ against the +checksum+.  If there is no checksum
    # then this just returns true
    #
    def verify
      if @checksum and @checksum.size == 2 then
        digest = @checksum.first
        should_be = @checksum.last
        result = digest.hexdigest( IO.read( local_source ) )
        return should_be == result
      else 
        return true
      end
    end

    #
    # unpack the local source into the build directory
    #
    def unpack
      FileUtils.rm_rf( pkg_dir ) if File.directory?( pkg_dir )
      if local_source.match( /\.tar\.gz\Z/ ) or local_source.match(/\.tgz\Z/) then
        tgz = ::Zlib::GzipReader.new( File.open( local_source, 'rb') )
        ::Archive::Tar::Minitar.unpack( tgz, build_dir )
      else
        raise UnsupportedFormatError, "Unable to extract files from #{File.basename( local_source)} -- unknown format"
      end
    end

    # 
    # patch the upacked source with files that are in the recipe directory
    #
    def patch
      log "Patching #{name}"

      Dir[File.join( recipe_dir, "*.patch")].sort.each do |pfile|
        Dir.chdir( pkg_dir ) do 
          log "applying #{File.basename( pfile ) }"
          %x[ patch -p0 < #{pfile} ]
        end  
      end
    end
  end
end
