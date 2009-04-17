#--
# Copyright (c) 2008, 2009 Jeremy Hinegardner
# All rights reserved.  See LICENSE and/or COPYING for details.
#++


begin
  require 'rubygems'
rescue LoadError
  abort "rubygems required"
end
  
module Crate
  class Error < StandardError; end
end

require 'rubygems'
require 'crate/paths'
require 'crate/version'
require 'crate/log'
