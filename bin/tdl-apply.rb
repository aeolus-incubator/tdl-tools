#!/usr/bin/ruby
# Utility to proxy a tdl to cloud instance / image services
#
# Part of the Aeolus suite http://aeolusproject.org
# Licensed under the MIT license
# Copyright (C) 2012 Red Hat, Inc.
# Written By Mo Morsi <mmorsi@redhat.com>
#
###########################################################

require 'thor'
require 'yaml'
require 'tempfile'

VERSION = "0.1.0"

class TDLApply < Thor
  desc "instance", "create a new instance from the tdl"
  def instance(tdl)
    # get cloud config
    config = get_config

    # convert tdl to etdl
    etdl   = `tdl-convert.rb #{tdl}`

    # swap config into etdl
    xml = Nokogiri::XML(etdl)
    xml.xpath('/cloud/type').first.content = config['type']
    xml.xpath('/cloud/provider').first.content = config['provider']
    xml.xpath('/cloud/username').first.content = config['username']
    xml.xpath('/cloud/password').first.content = config['password']
    xml.xpath('/cloud/image').first.content = config['image']
    xml.xpath('/cloud/keyname').first.content = config['keyname']
    xml.xpath('/cloud/ssh_cmd').first.content = config['ssh_cmd']
    xml.xpath('/cloud/scp_cmd').first.content = config['scp_cmd']
    etdl = xml.to_s

    tetdl = Tempfile.new(tdl)
    tetdl.write etdl
    tetdl.close

    # launch etdl
    `tdl-launch.rb #{tetdl}`
  end

  desc "image", "create a new image from the tdl"
  def image(tdl)
    config = get_config

    # TODO convert config to imagefactory cloud credentials
    `imagefactory base-image     #{tdl}`
    `imagefactory target-image   #{tdl}`
    `imagefactory provider-image #{tdl}`
  end

  private

  def get_config
    config = {}
    ["/etc/tdl-config.yml", "~/.tdl-config.yml", "./tdl-config.yml"].each { |c|
      begin
        config.merge!(YAML.load(File.expand(c)))
      rescue Exception => e
      end
    }
    config
  end
end

TDLApply.start(ARGV)
