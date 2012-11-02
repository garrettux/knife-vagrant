knife-vagrant
========
knife-vagrant tries to mirror the basic command structure of the knife-ec2 plugin for chef. The plugin will manage a series of Vagrantfiles in a tree to simulate a cloud environment.

Requirements
-------------------

- Virtualbox 4.1.X
- Vagrant (http://vagrantup.com/)
- chef gem install (client only)

Installation
-------------------
#### Script Install
Copy https://github.com/garrettux/knife-vagrant/blob/master/lib/chef/knife/vagrant_test.rb to your .chef/plugins/knife directory.

#### Gem Install
knife-vagrant is available on rubygems.org.

    gem install knife-vagrant

Usage
-------------------
** VAGRANT COMMANDS **
knife vagrant server [SUB-COMMAND]
knife vagrant server ssh [hostname]
knife vagrant server list
knife vagrant server create (options)
knife vagrant server delete [hostname] (args)

#### Examples

    knife vagrant server create -H vagrant01 -r role[vagrant] -m 2048 -p 22:2222,8080:8080 -U http://files.vagrantup.com/lucid64.box 

    knife vagrant server list
    testbox00
    testbox01
    testbox03

    knife vagrant server ssh testbox00
    [vagrant@testbox00 ~]$ 

Disclaimer
-------------------

This is my first stab at it, so I can't make any promises as to how well it works just yet.
