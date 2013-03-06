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

# use fedora api to verify packages
require 'pkgwat'

require 'tdl_gem_path'

VERSION = "0.0.2"

class TDLCreate < Thor
  desc "tdl", "create a new TDL"
  method_options :interactive => :boolean
  method_options :verify      => :boolean
  def tdl
    output = get_sample_tdl
    output = run_interactive(output, options) if options[:interactive]
    puts output
  end

  desc "etdl", "create a new eTDL"
  method_options :interactive => :boolean
  method_options :verify      => :boolean
  def etdl
    output = get_sample_etdl
    output = run_interactive(output, options) if options[:interactive]
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
  def run_interactive(output, options = {})
    xml = Nokogiri::XML(output)
    say "CTRL-D at any point to terminate prompts and output (e)tdl"

    begin
      packages   = []
      name        = ask("Template Name:")
      description = ask("Template Description:")
      os_name    = ask("OS Name:")
      os_version = ask("OS Version:")
      while true
        package = ask('Package:')
        packages << package
      end
      # TODO also files and commands
      # TODO also cloud and verify for etdls
    rescue Exception => e
      say "\n"
    end

    xml.xpath('/template/name').first.content = name
    xml.xpath('/template/description').first.content = description
    xml.xpath('/template/os/name').first.content = os_name
    xml.xpath('/template/os/version').first.content = os_version
    pkgnode = xml.xpath('/template/packages').first
    pkgnode.children[0..1].remove
    packages.each { |pkg|
      # verify
      if options[:verify]
        fpkg = Pkgwat.get_package(pkg)
        raise "Could not find package #{pkg} in Fedora" if fpkg.nil?
      end

      node = Nokogiri::XML::Node.new('package', xml)
      node['name'] = pkg
      pkgnode << node

      node = pkgnode.children.first.clone
      pkgnode << node
    }

    output = xml.to_s
  end

  private
  def get_sample_tdl
    tdl = nil
    [TDLTools.gem_path + 'data/sample.tdl', './data/sample.tdl'].each { |t|
      begin
        tdl = File.read(t)
      rescue Exception => e
      end
    }
    tdl
  end

  def get_sample_etdl
    etdl = nil
    [TDLTools.gem_path + 'data/sample.etdl', './data/sample.etdl'].each { |t|
      begin
        etdl = File.read(t)
      rescue Exception => e
      end
    }
    etdl
  end

end

TDLCreate.start(ARGV)
