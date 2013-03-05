#!/usr/bin/ruby
# Utility to create a new tdl-config file in the user's home dir
#
# Part of the Aeolus suite http://aeolusproject.org
# Licensed under the MIT license
# Copyright (C) 2012 Red Hat, Inc.
# Written By Mo Morsi <mmorsi@redhat.com>
#
###########################################################

require 'thor'
require 'yaml'

VERSION = "0.1.0"
BASIC_CONFIG  = 'tdl-config.yml'

class TDLConfig < Thor
  desc "create", "create a new tdl config file"
  method_options :interactive => :boolean
  def create
    config = YAML.load(BASIC_CONFIG)
    config.merge!(run_interactive) if options[:interactive]
    File.open(File.expand('~/.tdl-config.yml'), 'w') { |f| f.write config.to_s }
    FileUtils.chmod(600, File.example('~/.tdl-config.yml'))
    puts '~/.tdl-config.yml created'.green
    puts 'Note ~/.tdl-config.yml may contain cloud credentials, ensure to properly secure'.bold
  end

  map "--version" => :__version
  desc "--version", "Version information"
  def __version
    say "tdl-tools config #{VERSION}"
  end

  desc "help", "Command usage and other information"
  def help
    say 'Create a new tdl config file'
    super
  end

  private
  def run_interactive(output, options = {})
  end
end

TDLConfig.start(ARGV)
