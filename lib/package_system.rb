# tdl-tools package system representation
#
# Part of the Aeolus suite http://aeolusproject.org
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.
# Written By Mo Morsi <mmorsi@redhat.com>
#
###########################################################

# TODO use libosinfo to pull os information
#      support os's other than rpm based ones

module TDLTools
class PackageSystem
  # return command to install the specified packages on the local system
  def self.install_pkg_cmd(packages)
    "sudo yum install -y --nogpgcheck #{packages}"
  end
end
end
