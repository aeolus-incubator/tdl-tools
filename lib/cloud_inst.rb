# tdl-tools cloud instance representation
#
# Part of the Aeolus suite http://aeolusproject.org
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.
# Written By Mo Morsi <mmorsi@redhat.com>
#
###########################################################

require 'deltacloud'

module TDLTools
class CloudInst
  DC_URL = "http://localhost:3002/api"

  NO_START = false # set to true to disable creation of instances

  # ssh address of the instance
  attr_reader :address

  # ssh command to use
  attr_reader :ssh

  # scp command to use
  attr_reader :scp

  def initialize(cloud_attributes)
    # Use deltacloud to launch and setup instance
    @cloud_type = cloud_attributes[:type].intern

    @image   = cloud_attributes[:image]
    @keyname = cloud_attributes[:keyname]

    @dc = DeltaCloud.new(cloud_attributes[:username],
                         cloud_attributes[:password],
                         DC_URL)
    @dc.use_driver @cloud_type

    @dc.instance_variable_set :@api_provider,
                              cloud_attributes[:provider] if @cloud_type == :openstack # XXX needed for openstack

    @ssh = cloud_attributes[:ssh_cmd]
    @scp = cloud_attributes[:scp_cmd]
  end

  def launch
    # startup cloud instance
    unless NO_START
      dc_inst = @dc.create_instance(@image, :keyname => @keyname)
      sleep 300 # 5 minutes
    end

    # set various propertries from the instance
    dc_inst = (@cloud_type == :openstack ? @dc.instances.first : @dc.instances.last) # XXX for openstack its first, for ec2 its last
    address =  dc_inst.public_addresses.first
    address = dc_inst.private_addresses.first if address.nil?
    @address = address[:address]

    @ssh = @ssh.gsub(/\[address\]/, address)
    @scp = @scp.gsub(/\[address\]/, address)

    self
  end

  def exec(cmd)
    `#{@ssh} #{cmd}`
  end

  def cp(from, to, append=false)
    scpf = @scp.gsub(/\[source\]/, from).
               gsub(/\[dst\]/,    from)
    `#{scpf}`
    if append
      `#{ssh} sudo 'cat #{to} #{from} > #{from}.new'`
      `#{ssh} sudo mv #{from}.new #{to}`
    else
    `#{ssh} sudo mv #{from} #{to}`
    end
  end
end
end
