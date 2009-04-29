module Crate
  class Task
    class Unpack < ::Crate::Task
      # The File to unpack
      config 'file'

      def initialize( *args )
        super
      end

      def process( *args )
        logger.info "unpacking #{config[:file] || args.first}"  
        return 'here/there'
      end
    end
  end
end
