knife-vagrant
========
First pass at knife-vagrant, a knife plugin that will create a Vagrant box, then run a set of Chef recipes in it.

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
knife vagrant test (options)

    -b, --box BOX                    Name of vagrant box to be provisioned
    -U, --box-url URL                URL of pre-packaged vbox template.  Can be a local path or an HTTP URL.  Defaults to ./package.box
    -l, --chef-loglevel LEVEL        Logging level for the chef-client process that runs inside the provisioned VM.  Default is INFO
    -s, --server-url URL             Chef Server URL
    -k, --key KEY                    API Client Key
        --[no-]color                 Use colored output, defaults to enabled
    -c, --config CONFIG              The configuration file to use
        --defaults                   Accept default values for all questions
    -x, --destroy                    Destroy vagrant box and delete chef node/client when finished
    -d, --disable-editing            Do not open EDITOR, just accept the data as is
    -e, --editor EDITOR              Set the editor to use for interactive commands
    -E, --environment ENVIRONMENT    Set the Chef environment
    -F, --format FORMAT              Which format to use for output
    -H, --hostname HOSTNAME          Hostname to be set as hostname on vagrant box when provisioned
    -m, --memsize MEMORY             Amount of RAM to allocate to provisioned VM, in MB.  Defaults to 1024
    -u, --user USER                  API Client Username
    -p, --port-forward PORTS         Port forwarding.  Host port, VM port separated by a colon.  E.G. to forward 80 on the 
                                     host machine to 8080 on the VM, -p 80:8080.  
                                     To list multiple forwards separate with a comma, e.g. "-p 80:8080,22:2222"
        --print-after                Show the data after a destructive operation
    -D, --vagrant-dir PATH           Path to vagrant project directory.  Defaults to cwd (/Users/mgarrett/vagrant) if not specified
    -r, --vagrant-run-list RUN_LIST  Comma separated list of roles/recipes to apply
    -V, --verbose                    More verbose output. Use twice for max verbosity
    -v, --version                    Show chef version
    -y, --yes                        Say yes to all prompts for confirmation
    -h, --help                       Show this message

#### Example

    knife vagrant test -b base -H vagrant-mgarrett01 -r role[vagrant] -m 2048 -p 22:2222,8080:8080 -b box64 -U http://files.vagrantup.com/lucid64.box -xy

Disclaimer
-------------------

This is my first stab at it, so I can't make any promises as to how well it works just yet.
