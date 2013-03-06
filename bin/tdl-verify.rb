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

require 'tdl_gem_path'

VERSION = "0.0.2"

class TDLVerify < Thor
  desc "verify [path-to-tdl]", "Verify the tdl (or etdl) specified on the command line"
  def verify(path)
    say "Validating (e)TDL".bold
    rng = get_rng_for(path)
    xsd = Nokogiri::XML::RelaxNG(rng)
    doc = Nokogiri::XML(File.open(path))
    errs = xsd.validate(doc)
    if errs.empty?
      say " TDL is valid".bold.green
      exit 0

    else
      say " Errors in TDL".bold.red
      errs.each { |err|
        say "  #{err.message}".red
      }
      exit 1

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

  private
  def get_rng_for(path)
    rng  = nil
    rngf = (File.extname(path) == ".etdl" ? 'etdl.rng' : 'tdl.rng')
    dirs = [TDLTools.gem_path + 'data/', './'].each { |d|
      begin
        rng = File.read(d + rngf)
      rescue Exception => e
      end
    }
    rng
  end
end

TDLVerify.start(ARGV)
