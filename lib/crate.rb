#--
# Copyright (c) 2008, 2009 Jeremy Hinegardner
# All rights reserved.  See LICENSE and/or COPYING for details.
#++


begin
  require 'rubygems'
rescue LoadError
  abort "rubygems required"
end

begin
  require 'tap'
rescue LoadError
  abort 'sudo gem install tap'
end
  
module Crate
  class Error < StandardError; end
end

require File.join( File.expand_path(__FILE__).sub(/\.rb$/,''), "paths" )

require Crate.lib_path( 'version' )
require Crate.lib_path( 'log' )
require Crate.lib_path( 'task' )
require Crate.lib_path( 'ify' )
