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
require 'nokogiri'

VERSION = "0.1.0"
SAMPLE_TDL  = 'data/sample.tdl'
SAMPLE_ETDL = 'data/sample.etdl'

class TDLCreate < Thor
  desc "tdl", "create a new TDL"
  method_options :interactive => :boolean
  def tdl
    output = File.read(SAMPLE_TDL)
    output = run_interactive(output) if options[:interactive]
    puts output
  end

  desc "etdl", "create a new eTDL"
  method_options :interactive => :boolean
  def etdl
    output = File.read(SAMPLE_ETDL)
    output = run_interactive(output) if options[:interactive]
    puts output
  end

  map "--version" => :__version
  desc "--version", "Version information"
  def __version
    say "tdl-tools create #{VERSION}"
  end

  desc "help", "Command usage and other information"
  def help
    say 'Create a new TDL from scratch'
    super
  end

  private
  def run_interactive(output)
    xml = Nokogiri::XML(output)
    say "CTRL-D at any point to terminate prompts and output (e)tdl"

    begin
      name        = ask("Template Name:")
      description = ask("Template Description:")
      os_name    = ask("OS Name:")
      os_version = ask("OS Version:")
    rescue Exception => e
      say "\n"
    end

    xml.xpath('/template/name').first.content = name
    xml.xpath('/template/description').first.content = description
    xml.xpath('/template/os/name').first.content = os_name
    xml.xpath('/template/os/version').first.content = os_version
    output = xml.to_s
  end

end

TDLCreate.start(ARGV)
