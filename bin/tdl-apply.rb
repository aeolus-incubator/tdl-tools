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
    puts `tdl-launch.rb #{tetdl}`
  end

  desc "image", "create a new image from the tdl"
  def image(tdl)
    config = get_config

    base_output = `imagefactory base_image     #{tdl}`
    puts base_output

    base_image = # ...

    target_output = `imagefactory target_image   --id #{base_image} #{config[:type]}`
    puts target_output

    target_image = #...

    # convert config to imagefactory cloud credentials to provider/credentials config
    provider_config, credential_config = config2imgfac(config)

    `imagefactory provider_image --id #{target_image} #{provider_config.path} #{credential_config.path}`
  end

  map "--server" => :__server
  desc "--server", "Run Server"
  def __server
    # TODO use sinatra to listen for rest requests on /images /instances w/ tdl
  end

  map "--version" => :__version
  desc "--version", "Version information"
  def __version
    say "tdl-tools apply #{VERSION}"
  end

  desc "help", "Command usage and other information"
  def help
    say 'Proxy a tdl to cloud instance / image services'
    super
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

  def config2imgfac(config)
    provider_config    = Tempfile.new
    credentials_config = Tempfile.new

    if config[:type] == :ec2
      #provider_config.write
      credentials_config.write "<provider_credentials><ec2_credentials><account_number>#{config[:account]}</account_number><access_key>#{config[:access_key]}</access_key><secret_access_key>#{config[:secret_access_key]}</secret_access_key><certificate>#{config[:certificate]}</certificate><key>#{config[:key]}</key></ec2_credentials></provider_credentials>"
    elsif config[:type] == :openstack
      provider_config.write "{ 'glance-host' : '#{config[:glance_host]}', 'glance_port' : '#{config[:glance_port]}' }";
      credentials_config.write "<provider_credentials><openstack_credentials><username>#{config[:username]}</username><password>#{config[:password]}</password><strategy>#{config[:strategy]}</strategy><auth_url>#{config[:auth_url]}</auth_url></openstack_credentials></provider_credentials>"
    elsif config[:type] == :rhevm
      provider_config.write "{ 'api-url' : '#{config[:api_url]}', 'username' : '#{config[:username]}', 'password' : '#{config[:password}', 'nfs-path' : '#{config[:nfs_path]}', 'nfs-host' : '#{config[:nfs_host]}', 'cluster' : '#{config[:cluster]}', 'timeout' : '#{config[:timeout]}' }";
      credentials_config.write "<provider_credentials><rhevm_credentials><username>#{config[:username]}</username><password>#{config[:password]}</password></rhevm_credentials></provider_credentials>"
    elsif config[:type] == :vsphere
      provider_config.write "{ 'api-url' : '#{config[:api_url]}', 'username' : '#{config[:username]}', 'password' : '#{config[:password}', 'datastore' : '#{config[:datastore]}', 'computer_resource' : '#{config[:compute_resource]}', 'network_name' : '#{config[:network_name]}' }";
      credentials_config.write "<provider_credentials><vsphere_credentials><username>#{config[:username]}</username><password>#{config[:password]}</password></vsphere_credentials></provider_credentials>"
    end

    provider_config.close
    credentials_config.close
    [provider_config, credentials_config]
  end
end

TDLApply.start(ARGV)
