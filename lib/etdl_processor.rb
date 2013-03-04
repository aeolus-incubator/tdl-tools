# tdl-tools etdl processor
#
# Part of the Aeolus suite http://aeolusproject.org
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.
# Written By Mo Morsi <mmorsi@redhat.com>
#
###########################################################

require 'cloud_inst'
require 'package_system'

###############################################################
# Use various subsystems to process an etdl

class ETDLProcessor
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

    # TODO compare instance to etdl os

    inst
  end

  def process(etdl, instance)
    # TODO setup repos

    # yum install packages
    packages = etdl.instance_attributes[:packages].join(" ")
      puts "installing #{packages}".green
      puts instance.exec(TDLTools::PackageSystem.install_pkg_cmd(packages)).blue

    # copy files over
    files = etdl.instance_attributes[:files]
      files.each { |f|
        tf = Tempfile.new('tdl-launch')
        tf.write f[:contents]
        tf.close

        instance.cp tf.path, f[:name]
      }

    cmds = etdl.instance_attributes[:commands]
      cmds.each { |c|
        puts "running command #{c[:cmd]}"
        puts instance.exec("sudo -i #{c[:cmd]}").blue
      }
  end

  def verify(etdl, instance)
    etdl.verify_cmds.each { |v|
        puts "running verification #{v}"
        puts instance.exec("sudo -i #{v}").blue # TODO red if failed
    }
  end

  def terminate_instance(instance)
    # TODO
  end
end
