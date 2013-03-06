# tdl-tools helper utility, return path to tdl-tools gem
#
# Part of the Aeolus suite http://aeolusproject.org
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.
# Written By Mo Morsi <mmorsi@redhat.com>
#
###########################################################

module TDLTools
  def self.gem_path
    File.dirname(File.expand_path(__FILE__)) + "/../"
  end
end
