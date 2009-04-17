module Crate
  module Paths
    # The root directory of the project is considered to be the parent directory
    # of the 'lib' directory.
    #   
    def root_dir
      @root_dir ||= (
        path_parts = ::File.expand_path(__FILE__).split(::File::SEPARATOR)
        lib_index  = path_parts.rindex("lib")
        path_parts[0...lib_index].join(::File::SEPARATOR) + ::File::SEPARATOR
      )
    end 

    def root_path( sub, *args )
      sub_path( root_dir, sub, *args )
    end

    def bin_path( *args )
      root_path( 'bin', *args )
    end

    def lib_path( *args )
      root_path( "lib", *args )
    end 

    def spec_path( *args )
      root_path( "spec", *args )
    end

    # The home dir is the home directory of snip while it is running, by default
    # this the same as the root_dir.  But if this value is set then it affects
    # other paths
    def home_dir
      @home_dir ||= root_dir
    end

    def home_dir=( other )
      @home_dir = File.expand_path( other )
    end

    def home_path( sub, *args )
      sub_path( home_dir, sub, *args )
    end

    def config_path( *args )
      home_path( "config", *args )
    end 

    def data_path( *args )
      home_path( "data", *args )
    end 

    def log_path( *args )
      home_path( "log", *args )
    end

    def tmp_path( *args )
      home_path( "tmp", *args )
    end

    def sub_path( parent, sub, *args )
      sp = ::File.join( parent, sub ) + File::SEPARATOR
      sp = ::File.join( sp, *args ) if args
    end

    extend self
  end
  extend Paths
end
