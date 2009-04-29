module Crate
  class Task
    class InstallCratefile < ::Crate::Task
      # The directory to install the cratefile
      config 'directory'

      # The version of ruby in which to run the application.
      config 'target_ruby', "1.8.6"

      # The target platform on which the application will run.
      config 'target_platform', ::Config::CONFIG['arch']

      def initialize( *args )
        super
      end

      def process( *args )
        logger.info "config : #{config.inspect}"
        logger.info "installing cratefile into #{config[:directory] || args.first}"
        return "dest/path"
      end
    end
  end
end
