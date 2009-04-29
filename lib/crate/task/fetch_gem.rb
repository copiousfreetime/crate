module Crate
  class Task
    class FetchGem < ::Crate::Task

      # The name of the gem to fetch
      config 'gem'

      def initialize( *args )
        super
      end

      def process( *args )
        logger.info "fetching gem #{config[:gem] || args.first}"
        return "gem/path"
      end
    end
  end
end
