#--
# Copyright (c) 2008 Jeremy Hinegardner
# All rights reserved.  See LICENSE and/or COPYING for details
#++

module Crate
  module Version
    MAJOR   = 1
    MINOR   = 0
    BUILD   = 0

    def to_a 
      [MAJOR, MINOR, BUILD]
    end

    def to_s
      to_a.join(".")
    end

    def to_hash
      { :major => MAJOR, :minor => MINOR, :build => BUILD }
    end

    STRING = Version.to_s
    extend self
  end
  VERSION = Version.to_s

  extend Version
end
