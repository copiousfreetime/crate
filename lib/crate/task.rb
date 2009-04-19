module Crate
  class Task < ::Tap::Task
    def before_execute
      ::Crate::Log.init unless Crate::Log.initialized?
    end

    def logger
      ::Logging::Logger[self]
    end
  end
end
