#!/usr/bin/ruby
# Utility to read in eTDLs and use Deltacloud to launch them
# Run with the path to the eTDL like so:
#    ./mycloud.rb <path-to-etdl>
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
require 'deltacloud'

###############################################################
# Read in configuration from cmd line and xml file
if ARGV.size != 1
  puts "Usage: mycloud.rb <path-to-tdl>".red
  exit 1
end

ETDL = ARGV.first

unless File.readable?(ETDL)
  puts "eTDL #{ETDL} is not readable".red
  exit 1
end

NO_START = false # set to true to disable creation of instances

DC_URL = "http://localhost:3001/api"

cloud_attributes = { :type => nil, :provider => nil,
                     :username => nil, :password => nil, :keyname => nil,
                     :image => nil, :ssh_cmd => nil, :scp_cmd => nil }

instance_attributes = { :name => nil, :description => nil, :hostname => nil,
                        :firewall => [], :packages => [],
                        :services => [], :files => [],
                        :dirs => [], :commands => []}

doc = Nokogiri::XML(open(ARGV.first))
doc.children.last.children.each { |c|
  if c.name == 'name'
    instance_attributes[:name] = c.text

  elsif c.name == 'description'
    instance_attributes[:description] = c.text

  elsif c.name == 'hostname'
    instance_attributes[:hostname] = c.text

  elsif c.name == 'cloud'
    c.children.each { |ca|
      cloud_attributes[ca.name.intern] = ca.text
    }

  elsif c.name == 'firewall'
    c.children.each { |rule|
      if rule.name == "tcp" || rule.name == "udp"
        instance_attributes[:firewall] << {:proto => rule.name, :value => rule.text}
      end
    }

  elsif c.name == 'packages'
    c.children.each { |pkg|
      unless pkg['name'].nil?
        instance_attributes[:packages] << pkg['name']
      end
    }

  elsif c.name == 'services'
    c.children.each { |srv|
      unless srv['name'].nil?
        pre_cmds = []
        post_cmds = []
        srv.children.each { |s|
          if s.name == "before"
            pre_cmds << s.text
          elsif s.name == "after"
            post_cmds << s.text
          end
        }
        instance_attributes[:services] << {:name => srv['name'], :pre => pre_cmds, :post => post_cmds}
      end
    }

  elsif c.name == 'dirs'
    c.children.each { |dir|
      owner = dir['owner'] || 'root'
      group = dir['group'] || 'root'
      remove = dir['remove'] || false
      instance_attributes[:dirs] << {:name => dir.text, :owner => owner, :group => group, :remove => remove} if dir.text.strip != ""
    }

  elsif c.name == 'files'
    c.children.each { |file|
      unless file['name'].nil?
        mode = file['mode'] || '644'
        owner = file['owner'] || 'root'
        group = file['group'] || 'root'
        instance_attributes[:files] << {:name => file['name'], :mode => mode, :append => file['append'],
                                        :owner => owner, :group => group,
                                        :contents => file.text}
      end
    }

  elsif c.name == 'commands'
    c.children.each { |cmd|
      unless cmd.name != "command"
        user = cmd['user'] || 'root'
        instance_attributes[:commands] << {:cmd => cmd.text, :user => user}
      end
    }
  end
}
pp instance_attributes
#pp cloud_attributes


###############################################################
# Use deltacloud to launch and setup instance
puts "Connecting to deltacloud instance at #{DC_URL}...".green
cloud_type = cloud_attributes[:type].intern
dc = DeltaCloud.new(cloud_attributes[:username], cloud_attributes[:password], DC_URL)
dc.use_driver cloud_type
dc.instance_variable_set :@api_provider, cloud_attributes[:provider] if cloud_type == :openstack # XXX needed for openstack

# startup cloud instance
unless NO_START
  puts "Booting up cloud instance".green
  puts "  This will take a few minutes to become fully accessible".green
  # TODO how to specify keyname
  dc_inst = dc.create_instance(cloud_attributes[:image], :keyname => cloud_attributes[:keyname])
  sleep 300 # 5 minutes
end
dc_inst = (cloud_type == :openstack ? dc.instances.first : dc.instances.last) # XXX for openstack its first, for ec2 its last

address = dc_inst.public_addresses.first
address = dc_inst.private_addresses.first if address.nil?
if address.nil?
  puts "could not find address to access instance with".red
  exit 1
end
address = address[:address]

ssh = cloud_attributes[:ssh_cmd].gsub(/\[address\]/, address)
scp = cloud_attributes[:scp_cmd].gsub(/\[address\]/, address)

puts "using address #{address}\nssh:#{ssh}\nscp:#{scp}".green

# set hostname
unless instance_attributes[:hostname].nil?
  puts "Setting hostname to #{instance_attributes[:hostname]}".green
  `#{ssh} sudo hostname #{instance_attributes[:hostname]}`
  instance_attributes[:files] << {:name => '/etc/hosts', :append => true,
                                  :owner => 'root', :group => 'root', :mode => 644,
                                  :contents => "#{address} #{instance_attributes[:hostname]}"}
end

# FIXME open firewall ports (we have to open them manually now)

# yum install packages
packages = instance_attributes[:packages].join(" ")
puts "installing #{packages}".green
puts `#{ssh} sudo yum install -y --nogpgcheck #{packages}`.blue

# start services
instance_attributes[:services].each { |s|
  puts "starting/enabling service #{s[:name]}".green
  s[:pre].each { |cmd|
     puts " running precommand #{cmd}".green
    puts `#{ssh} sudo #{cmd}`.blue
  }
  puts `#{ssh} sudo service #{s[:name]} start`.blue
  puts `#{ssh} sudo chkconfig --levels 35 #{s[:name]} on`.blue
  s[:post].each { |cmd|
     puts " running postcommand #{cmd}".green
    puts `#{ssh} sudo #{cmd}`.blue
  }
}

instance_attributes[:dirs].each { |d|
  puts "creating dir #{d[:name]}".green
  `#{ssh} sudo rm -rf #{d[:name]}` if d[:remove]
  `#{ssh} sudo mkdir -p #{d[:name]}`
  `#{ssh} sudo chown #{d[:owner]}.#{d[:group]} #{d[:name]}`
}

# create dirs
# copy files over
instance_attributes[:files].each { |f|
  tf = Tempfile.new('mycloud')
  tf.write f[:contents]
  tf.close
  scpf = scp.gsub(/\[source\]/, tf.path).
             gsub(/\[dst\]/, tf.path)
  puts "creating file #{f[:name]}".green
  `#{scpf}`
  if f[:append]
    `#{ssh} sudo 'cat #{f[:name]} #{tf.path} > #{tf.path}.new'`
    `#{ssh} sudo mv #{tf.path}.new #{f[:name]}`
  else
    `#{ssh} sudo mv #{tf.path} #{f[:name]}`
  end
  `#{ssh} sudo chown #{f[:owner]}.#{f[:group]} #{f[:name]}`
  `#{ssh} sudo chmod #{f[:mode]} #{f[:name]}`
}

# execute commands
instance_attributes[:commands].each { |c|
  puts "running command #{c[:cmd]} as #{c[:user]}"
  puts `#{ssh} sudo -u #{c[:user]} -i #{c[:cmd]}`.blue
}

###########################################
puts "Done!".bold
