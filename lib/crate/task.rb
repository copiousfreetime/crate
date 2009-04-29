module Crate
  class Task < ::Tap::Task
    def initialize( *args )
      super
    end

    def before_execute
      ::Crate::Log.init unless Crate::Log.initialized?
    end

    def logger
      ::Logging::Logger[self]
    end
  end
end
require 'crate/task/unpack'
require 'crate/task/install_cratefile'
require 'crate/task/fetch_gem'
