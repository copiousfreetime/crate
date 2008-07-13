require 'muster/dependency'
require 'rubygems/format'
module Muster
  class GemIntegration < Dependency
    #
    # Define all the tasks in the namespace of the +name+ of this task.
    #
    # The dependency chain is:
    #
    #   :integrate => :patch => :unpack => :verify => :download
    #
    #
    def define
      logger.debug "Defining tasks for #{name} #{version}"

      namespace name do
        define_download
        define_verify
        define_unpack
        define_patch
        define_integration

        task :done    => :integrate
        task :default => :done
      end

      desc "Build and Integrate #{name} #{version}"
      task name => "#{name}:default"
    end

    #
    # Define how the gem integrates into the ruby installation
    #
    def define_integration
      desc "Integrate #{name} into ruby's build tree"
      task :integration => [ "#{name}:patch", "ruby:patch" ] do |t|
        logger.info "Integrating #{name} into ruby's tree"
        format = Gem::Format.from_file_by_path( local_source )

        require_paths = format.spec.require_paths.dup
        integration_info = {}

        format.spec.extensions.each do |ext|
          logger.info "integrating #{name} extension #{ext}"
          ext_dirname = File.dirname( ext ) + File::SEPARATOR
          dest_ext_dir = File.join( Muster.ruby.ext_dir, name )
          integration_info[ ext_dirname ] = dest_ext_dir
          require_paths.delete( File.dirname( ext ) )
        end

        require_paths.each do |rp|
          logger.info "integrating #{name} '#{rp}' files "
          integration_info[ rp + File::SEPARATOR ] = Muster.ruby.lib_dir
        end

        install_integration_files( integration_info )

        setup_lines = IO.readlines( Muster.ruby.ext_setup_file )
        if setup_lines.grep(/^#{name}/).empty? then
          File.open( Muster.ruby.ext_setup_file, "a+" ) do |f|
            logger.info "updating ext/Setup file to add #{name}"
            f.puts name
          end
        end
      end
    end

    #
    # each of the key value pairs indicates an matching path (the key)  from the
    # gemspec that should be installed into the designated destiation path (the
    # value)
    #
    def install_integration_files( info )
      format = Gem::Format.from_file_by_path( local_source )
      info.each_pair do |from, to|
        Dir.chdir( File.join( pkg_dir, from ) ) do
          format.spec.files.each do |f|
            if f.index( from ) == 0 then
              src_file = f.sub( from, '' )
              dest_file = File.join( to, src_file ) 
              dest_dir = File.dirname( dest_file )
              logger.debug "copy #{src_file} to #{dest_file}"
              FileUtils.mkdir_p dest_dir unless File.directory?( dest_dir )
              FileUtils.cp src_file, dest_file
            end
          end
        end
      end
    end
  end
end
