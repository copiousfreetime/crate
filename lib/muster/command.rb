module Muster
  class Command
    class << self
      def inherited(sub_class)
        @commands = (@commands ||= []) << sub_class
      end

      def commands
        @commands
      end
    end


    def pre_run
    end

    def run
      pre_run
      run_command
      post_run
    end

    def post_run
    end

    def run_command
      raise NotImplementedError, "Command #{self.class.name} should have implemented the 'run_command' method"
    end
  end
  module Commands; end
end
%w[ init build ].each { |c| require "muster/commands/#{c}" }
