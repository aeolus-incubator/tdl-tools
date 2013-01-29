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

RELAX_FILE = 'data/tdl.rng'

class TDLVerify < Thor
  desc "verify", "verify the tdl specified on the command line"
  def verify(path)
    say "Validating TDL"
    xsd = Nokogiri::XML::RelaxNG(File.read(RELAX_FILE))
    doc = Nokogiri::XML(File.open(path))
    errs = xsd.validate(doc)
    if errs.empty?
      say "TDL is valid"
    else
      say "Errors in TDL"
      errs.each { |err|
        say err.message
      }
    end
  end
end

TDLVerify.start(ARGV)
