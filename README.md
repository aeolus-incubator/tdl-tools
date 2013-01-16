# Background

The [Aeolus](http://aeolusproject.org) [Template Description Language](https://github.com/clalancette/oz/wiki/Oz-template-description-language) is used by [Oz](https://github.com/clalancette/oz), [Imagefactory](https://github.com/aeolusproject/imagefactory), and [Snap](https://github.com/movitto/snap) to describe operating systems and the components and configurations installed on them for useful purposes. 

Oz and imagefactory use the TDL format in conjunction with native system tooling to bootstrap environments to be used as the basis of cloud images, while Snap uses native system tooling to deconstruct cloud instances into a TDLs which can be used on other cloud providers.

The problem at hand is that constructing these TDLs currently is a resource-intensive operation, as building these from scratch takes lots of time and bandwidth, a detriment to growing the Aeolus community. TDLs are built through a manual trial and error process, and even one small mistake in a TDL might not be discovered for hours and after alot of bandwidth is used.

tdl-tools aims to provide a few simple tools which makes TDL creation simple and easy. Furthermore these same tools can be used to facilitate systems and service orchestration using the Aeolus TDL format, which combined w/ the image creation capabilities provided by Oz/Imagefactory leads to a unique and easy-to-understand selling point for the Aeolus framework.

# Solution

We are proposing adding the following tools to the Aeolus suite to facilitate the creation and management of these TDLs:

* tdl-create: simple tool used to prompt the end user for a few optional fields and create a barebones TDL with blanks for the user to fill in
* tdl-verify: verified a tdl is in the correct format and is standards compliant
* tdl-launch: the main utility script which will launch a cloud instance using [Deltacloud](http://deltacloud.apache.org/) and execute the commands on the newly created instance. For the time being tdl-launch will only support rpm and deb based Linux instances, though other package systems and windows support may eventually be added

Furthermore, going forward we may add the following to the tdl-tools project:

* tdl-diff: a utility to compare tdls for differences
* web-tdl: A RESTful frontend to tdl-launch which will provide the capability to construct TDLs on the fly and automatically launch them on the cloud
* hostmytdl: a wrapper to the [Aeolus Templates Git Repository](https://github.com/aeolus-incubator/templates) which allows for the simple uploading and downloading of TDLs
* img2tdl: a utility similar to Snap but geared towards deconstructing a cloud image into a TDL
* tdl-update: a mechanism to update an instance launched by tdl-launch so as to incorporate new additions to a modified TDL

This set of utilities are still in the conceptual stage and will be flushed out further before proceeding. For now the first set (tdl-create, tdl-launch, and tdl-verify) are the main components that constitute the tdl-tools project.


# eTDLs

tdl-tools will require data pertaining to cloud provider credentials so as to launch new instances on that provider. To keep things simple, these will be added to the TDL files themselves as new fields under a 'cloud' tag so as to not overlap w/ the existing attributes. To prevent confusion, these TDLs will be known as 'extended TDLs', or eTDLs.

Besides these attributes, the TDL format will be left unchanged. The standard TDL fields will all be used to setup the cloud instance, with the exception of the 'os' fields which will have no material effect on the new instance, though will be used for comparison and reporting purposes (eg if set 'os' will be read and compared against the local cloud instance, with a warning being displayed if there is a mismatch).

At some point tdl-tools may also support reading cloud provider credentials from a file of the local filesystem (such as /etc/tdl-tools and/or ~/.tdl-tools) and/or from the command line so that standard TDLs can be launched on the cloud as is.

The eTDL fields will contain:

* type - the type of cloud provider to launch instance against
* provider - the deltacloud provider id to launch instance against
* username - the cloud username to use when launching the instance
* password - the cloud password to use when launching the instance
* image - the cloud image to base the instance off of
* keyname - the name of the key on the cloud provider to access the instance
* ssh_cmd - the command to run to use to ssh into the instance and run commands
* scp_cmd - the command to run to use to scp files to the instance

ssh_cmd and scp_cmd are templates with variables such as [address], [source] and [dst] which will be filled in on the fly with values representing the address of the cloud instance, and the source and destination filenames.

An example cloud section in an eTDL is as following

    <cloud>
      <type>ec2</type>
      <provider>ec2-east-1</provider>
      <username>ABCDEF</username>
      <password>FEDCBA</password>
      <image>ami-2ea50247</image>
      <keyname>MYKEY</keyname>
      <ssh_cmd>ssh -q -o StrictHostKeyChecking=no -t ec2-user@[address] -i ~/.ssh/my.key</ssh_cmd>
      <scp_cmd>scp -o StrictHostKeyChecking=no -i ~/.ssh/my.key [source] ec2-user@[address]:[dst]</scp_cmd>
    </cloud>


This of course relies on a few assumptions, namely the end user has access to the cloud provider they will be running instances on before hand, the specified image and key exists, and instances come up w/ a publically available ip address. Though these are the same assumptions that hold for various other Aeolus components.


# Going forward

The tdl-launch utility (in a previous incantation called 'mycloud') was already demonstrated in action to deploy various instances to facilitate a cross-cloud koji installation ( [screencast here](http://www.youtube.com/watch?v=qF2ctg7ItNc) ).

The tdl-launch utility needs to be cleaned up and optimized / abstracted a bit, and packaged into gem, rpm, and deb packages. Furthuremore the create-tdl utility needs to be written to facilitate setting up a tdl from scratch.
