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
require 'colored'

VERSION = "0.1.0"
RELAX_FILE = 'data/tdl.rng'

class TDLVerify < Thor
  desc "verify [path-to-tdl]", "Verify the tdl specified on the command line"
  def verify(path)
    say "Validating TDL".bold
    xsd = Nokogiri::XML::RelaxNG(File.read(RELAX_FILE))
    doc = Nokogiri::XML(File.open(path))
    errs = xsd.validate(doc)
    if errs.empty?
      say " TDL is valid".bold.green
    else
      say " Errors in TDL".bold.red
      errs.each { |err|
        say "  #{err.message}".red
      }
    end
  end

  map "--version" => :__version
  desc "--version", "Version information"
  def __version
    say "tdl-tools verify #{VERSION}"
  end

  desc "help", "Command usage and other information"
  def help
    say 'Verify a TDL'
    super
  end
end

TDLVerify.start(ARGV)
