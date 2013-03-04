# tdl-tools etdl representation
#
# Part of the Aeolus suite http://aeolusproject.org
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.
# Written By Mo Morsi <mmorsi@redhat.com>
#
###########################################################

module TDLTools
class ETDL
  # cloud attributes
  #attr_reader :type, :provider, :username, :password, :keyname, :image, :ssh_cmd, :scp_cmd
  attr_reader :cloud_attributes

  # instance attributes
  #attr_reader :name, :description, :os, :repositories, :disk, :packages, :files, :commands
  attr_reader :instance_attributes

  # additional commands to verify instance
  attr_reader :verify_cmds

  def initialize(args = {})
    @cloud_attributes    = args[:cloud_attributes]    || {}
    @instance_attributes = args[:instance_attributes] || {}
    @verify_cmds         = args[:verify_cmds]         || []
  end

  # Parse / return new eTDL instance from xml document
  def self.parse(doc)
    cloud_attributes    = {}
    instance_attributes = { :repositories => [], :packages => [],
                            :files        => [], :commands => [] }
    verify_cmds         = []

    doc.children.last.children.each { |c|
      if c.name == 'name'
        instance_attributes[:name] = c.text.strip

      elsif c.name == 'description'
        instance_attributes[:description] = c.text.strip

      elsif c.name == 'cloud'
        c.children.each { |ca|
          cloud_attributes[ca.name.intern] = ca.text.strip
        }

      elsif c.name == 'os'
        instance_attributes[:os] = {}
        c.children.each { |cc|
          instance_attributes[:os][cc.name] = cc.text.strip
        }

      # TODO c.name == 'disk'

      elsif c.name == 'repositories'
        c.children.each { |repo|
          unless repo['name'].nil?
            instance_attributes[:repositories] << { :name => repo['name'],
                                                    :url  => repo['url'] }
          end
        }

      elsif c.name == 'packages'
        c.children.each { |pkg|
          unless pkg['name'].nil?
            instance_attributes[:packages] << pkg['name']
          end
        }

      elsif c.name == 'files'
        c.children.each { |file|
          unless file['name'].nil?
            instance_attributes[:files] << {:name => file['name'],
                                            :contents => file.text.strip}
          end
        }

      elsif c.name == 'commands'
        c.children.each { |cmd|
          unless cmd.name != "command"
            instance_attributes[:commands] << {:cmd => cmd.text.strip}
          end
        }

      elsif c.name == 'verify'
        c.children.each { |cmd|
          unless cmd.name != "command"
            verify_cmds << cmd.text.strip
          end
        }

      end
    }
    #pp instance_attributes
    #pp cloud_attributes
    #pp verify_cmds

    etdl = ETDL.new :cloud_attributes    => cloud_attributes,
                    :instance_attributes => instance_attributes,
                    :verify_cmds => verify_cmds
  end

  def process(processor)
    instance = processor.launch_instance(self)
    processor.process(self, instance)
    processor.verify(self, instance)
    processor.terminate_instance(instance)
  end

end
end
