#!/usr/bin/ruby
# Utility to convert tdls/etdls
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

class TDLConvert < Thor
  desc "convert", "convert tdl to/from etdl"
  def convert(source)
    extname = File.extname(source)
    output  = File.read(source)
    if extname == ".etdl"
      etdl2tdl(output)
    else
      tdl2etdl(output)
    end
  end

  map "--version" => :__version
  desc "--version", "Version information"
  def __version
    say "tdl-tools convert #{VERSION}"
  end

  desc "help", "Command usage and other information"
  def help
    say 'Convert a tdl to / from an etdl'
    super
  end

  private
  def etdl2tdl(output)
    xml = Nokogiri::XML(output)

    xml.xpath('/template/cloud').remove
    xml.xpath('/template/verify').remove

    puts xml.to_s
  end

  def tdl2etdl(output)
    xml = Nokogiri::XML(output)

    cloudn  = Nokogiri::XML::Node.new('cloud', xml)
    cloudn << "\n"
    cloud_nodes = ['type',  'provider', 'username', 'password',
                   'image', 'keyname',  'ssh_cmd',  'scp_cmd'].each { |cn|
                     cnn = Nokogiri::XML::Node.new(cn, xml)
                     cnn << " "
                     cloudn << "\t\t"
                     cloudn << cnn
                     cloudn << "\n"
                  }
    cloudn << "\t"

    verifycmdn = Nokogiri::XML::Node.new('command', xml)
    verifycmdn['name'] = ''
    verifyn    = Nokogiri::XML::Node.new('verify', xml)
    verifyn << "\n\t\t"
    verifyn << verifycmdn
    verifyn << "\n\t"

    xml.xpath('/template').first << "\t"
    xml.xpath('/template').first << cloudn
    xml.xpath('/template').first << "\n\n\t"
    xml.xpath('/template').first << verifyn
    xml.xpath('/template').first << "\n"
    puts xml.to_s
  end

end

TDLConvert.start(ARGV)
