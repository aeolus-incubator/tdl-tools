#!/usr/bin/ruby
# Utility to create a barebones (e)TDL from the command line
#
# Part of the Aeolus suite http://aeolusproject.org
# Licensed under the MIT license
# Copyright (C) 2012 Red Hat, Inc.
# Written By Mo Morsi <mmorsi@redhat.com>
#
###########################################################

require 'thor'

class TDLCreate < Thor
  desc "tdl", "create a new TDL"
  def tdl
    puts File.read('sample.tdl')
  end

  desc "etdl", "create a new eTDL"
  def etdl
    puts File.read('sample.etdl')
  end
end

TDLCreate.start(ARGV)
