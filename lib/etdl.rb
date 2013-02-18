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
  #attr_reader :name, :description, :hostname, :firewall, :packages, :services, :files, :dirs, :commands
  attr_reader :instance_attributes

  def initialize(args = {})
    @cloud_attributes    = args[:cloud_attributes]    || {}
    @instance_attributes = args[:instance_attributes] || {}
  end

  # Parse / return new eTDL instance from xml document
  def self.parse(doc)
    cloud_attributes    = {}
    instance_attributes = {}

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
            instance_attributes[:firewall] ||= []
            instance_attributes[:firewall] << {:proto => rule.name, :value => rule.text}
          end
        }

      elsif c.name == 'packages'
        c.children.each { |pkg|
          unless pkg['name'].nil?
            instance_attributes[:packages] ||= []
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
            instance_attributes[:services] ||= []
            instance_attributes[:services] << {:name => srv['name'], :pre => pre_cmds, :post => post_cmds}
          end
        }

      elsif c.name == 'dirs'
        c.children.each { |dir|
          owner = dir['owner'] || 'root'
          group = dir['group'] || 'root'
          remove = dir['remove'] || false
          instance_attributes[:dirs] ||= []
          instance_attributes[:dirs] << {:name => dir.text, :owner => owner, :group => group, :remove => remove} if dir.text.strip != ""
        }

      elsif c.name == 'files'
        c.children.each { |file|
          unless file['name'].nil?
            mode = file['mode'] || '644'
            owner = file['owner'] || 'root'
            group = file['group'] || 'root'
            instance_attributes[:files] ||= []
            instance_attributes[:files] << {:name => file['name'], :mode => mode, :append => file['append'],
                                            :owner => owner, :group => group,
                                            :contents => file.text}
          end
        }

      elsif c.name == 'commands'
        c.children.each { |cmd|
          unless cmd.name != "command"
            user = cmd['user'] || 'root'
            instance_attributes[:commands] ||= []
            instance_attributes[:commands] << {:cmd => cmd.text, :user => user}
          end
        }
      end
    }
    pp instance_attributes
    #pp cloud_attributes

    etdl = ETDL.new :cloud_attributes    => cloud_attributes,
                    :instance_attributes => instance_attributes
  end

  def process(processor)
    instance = processor.launch_instance(self)
    processor.process(self, instance)
    processor.verify(self, instance)
    processor.terminate_instance(instance)
  end

end
end
