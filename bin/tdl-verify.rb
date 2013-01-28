#!/usr/bin/ruby
# Utility to verify a specified (e)TDL 
#
# Part of the Aeolus suite http://aeolusproject.org
# Licensed under the MIT license
# Copyright (C) 2012 Red Hat, Inc.
# Written By Mo Morsi <mmorsi@redhat.com>
#
###########################################################

require 'thor'
require 'nokogiri'

class TDLVerify < Thor
  desc "verify", "verify the tdl specified on the command line"
  def verify(path)
    puts "TODO verify #{path}"
  end
end

TDLVerify.start(ARGV)
