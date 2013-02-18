#!/usr/bin/ruby
# Utility to read in eTDLs and use Deltacloud to launch them
# Run with the path to the eTDL like so:
#    ./tdl-launch.rb <path-to-etdl>
#
# The etdls are the same format as the TDLs supported by imagefactory/oz
# with additional ('extended') data pertaining to the cloud provider to
# deploy to and the environment to setup.
#
# Assumes instances are started on clouds w/ a public accessible
# address and with the ability to ssh in and run operations
# (eTDLs must specify ssh and scp commands  to use)
#
# Part of the Aeolus suite http://aeolusproject.org
# Licensed under the MIT license
# Copyright (C) 2012 Red Hat, Inc.
# Written By Mo Morsi <mmorsi@redhat.com>
#
###########################################################

require 'pp'
require 'colored'
require 'nokogiri'
require 'tempfile'

require 'etdl'
require 'cloud_inst'


###############################################################
# Deploy various subsystems to do work

class TDLLaunch
  def launch_instance(etdl)
    puts "Connecting to deltacloud instance at #{TDLTools::CloudInst::DC_URL}...".green
    inst = TDLTools::CloudInst.new etdl.cloud_attributes

    puts "Booting up cloud instance".green
    puts "  This will take a few minutes to become fully accessible".green
    inst.launch

    if inst.address.nil?
      puts "could not find address to access instance with".red
      exit 1
    end

    puts "using address #{inst.address}\nssh:#{inst.ssh}\nscp:#{inst.scp}".green

    inst
  end

  def process(etdl, instance)
    # TODO need to open firewall ports (we have to open them manually now)

    # set hostname
    hostname = etdl.instance_attributes[:hostname]
      unless hostname.nil?
        puts "Setting hostname to #{hostname}".green
        instance.exec "sudo hostname #{hostname}"

        # append hostname to /etc/hosts/
        etdl.instance_attributes[:files] <<
          {:name => '/etc/hosts', :append => true,
           :owner => 'root', :group => 'root', :mode => 644,
           :contents => "#{instance.address} #{hostname}"}
      end

    # yum install packages
    packages = etdl.instance_attributes[:packages].join(" ")
      puts "installing #{packages}".green
      puts instance.exec("sudo yum install -y --nogpgcheck #{packages}").blue

    # start services
    services = etdl.instance_attributes[:services]
      services.each { |s|
        puts "starting/enabling service #{s[:name]}".green
        s[:pre].each { |cmd|
          puts " running precommand #{cmd}".green
          puts instance.exec("sudo #{cmd}").blue
        }
        puts instance.exec("sudo service #{s[:name]} start").blue
        puts instance.exec("sudo chkconfig --levels 35 #{s[:name]} on").blue
        s[:post].each { |cmd|
          puts " running postcommand #{cmd}".green
          puts instance.exec("sudo #{cmd}").blue
        }
      }

    # create dirs
    dirs = etdl.instance_attributes[:dirs]
      dirs.each { |d|
        puts "creating dir #{d[:name]}".green
        instance.exec("sudo rm -rf #{d[:name]}") if d[:remove]
        instance.exec("sudo mkdir -p #{d[:name]}")
        instance.exec("sudo chown #{d[:owner]}.#{d[:group]} #{d[:name]}")
      }

    # copy files over
    files = etdl.instance_attributes[:files]
      files.each { |f|
        tf = Tempfile.new('tdl-launch')
        tf.write f[:contents]
        tf.close

        instance.cp tf.path, f[:name]
        instance.exec("sudo chown #{f[:owner]}.#{f[:group]} #{f[:name]}")
        instance.exec("sudo chmod #{f[:mode]} #{f[:name]}")
      }

    cmds = etdl.instance_attributes[:commands]
      cmds.each { |c|
        puts "running command #{c[:cmd]} as #{c[:user]}"
        puts instance.exec("sudo -u #{c[:user]} -i #{c[:cmd]}").blue
      }
  end

  def verify_results(etdl, instance)
    # TODO
  end

  def terminate_instance(instance)
    # TODO
  end
end


###############################################################
# Read in configuration from cmd line and xml file

if ARGV.size != 1
  puts "Usage: tdl-launch.rb <path-to-tdl>".red
  exit 1
end

ETDL = ARGV.first

unless File.readable?(ETDL)
  puts "eTDL #{ETDL} is not readable".red
  exit 1
end

doc  = Nokogiri::XML(open(ARGV.first))
etdl = TDLTools::ETDL.parse(doc)

launch = TDLLaunch.new

etdl.process(launch)

puts "Done!".bold
