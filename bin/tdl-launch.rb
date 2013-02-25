#!/usr/bin/ruby
# Utility to read in eTDLs and use Deltacloud to launch them
# Run with the path to the eTDL like so:
#    ./tdl-launch.rb <path-to-etdl>
#
# The etdls are the same format as the TDLs supported by imagefactory/oz
# with additional ('extended') data pertaining to the cloud provider to
# deploy to and the environment to setup.
#
# Assumes instances are started on clouds w/ a public accessible
# address and with the ability to ssh in and run operations
# (eTDLs must specify ssh and scp commands  to use)
#
# Part of the Aeolus suite http://aeolusproject.org
# Licensed under the MIT license
# Copyright (C) 2012 Red Hat, Inc.
# Written By Mo Morsi <mmorsi@redhat.com>
#
###########################################################

require 'pp'
require 'colored'
require 'nokogiri'
require 'tempfile'

require 'etdl'
require 'etdl_processor'

###############################################################
# Read in configuration from cmd line and xml file

if ARGV.size != 1
  puts "Usage: tdl-launch.rb <path-to-tdl>".red
  exit 1
end

ETDL = ARGV.first

unless File.readable?(ETDL)
  puts "eTDL #{ETDL} is not readable".red
  exit 1
end

doc  = Nokogiri::XML(open(ARGV.first))
etdl = TDLTools::ETDL.parse(doc)

launch = ETDLProcessor.new

etdl.process(launch)

puts "Done!".bold
