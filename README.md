knife-vagrant
========
First pass at knife-vagrant, a knife plugin that will create a Vagrant box, then run a set of Chef recipes in it.  Eventually will also run cucumber tests and report the results.

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
Not ready yet, will be available on rubygems.org later.

Usage
-------------------
knife vagrant test (options)

    -b, --box BOX                    Name of vagrant box to be provisioned

    -U, --box-url URL                URL of pre-packaged vbox template.  Can be a local path or an HTTP URL.  Defaults to ./package.box

    -l, --chef-loglevel LEVEL        Logging level for the chef-client process that runs inside the provisioned VM.  Default is INFO

    -s, --server-url URL             Chef Server URL

    -k, --key KEY                    API Client Key

        --color                      Use colored output

    -c, --config CONFIG              The configuration file to use

        --defaults                   Accept default values for all questions

    -x, --destroy                    Destroy vagrant box and delete chef node/client when finished

    -e, --editor EDITOR              Set the editor to use for interactive commands

    -E, --environment ENVIRONMENT    Set the Chef environment

    -F, --format FORMAT              Which format to use for output

    -H, --hostname HOSTNAME          Hostname to be set as hostname on vagrant box when provisioned

    -m, --memsize MEMORY             Amount of RAM to allocate to provisioned VM, in MB.  Defaults to 1024

        --no-color                   Don't use colors in the output

    -n, --no-editor                  Do not open EDITOR, just accept the data as is

    -u, --user USER                  API Client Username

        --print-after                Show the data after a destructive operation

    -D, --vagrant-dir PATH           Path to vagrant project directory.  Defaults to cwd (/home/mgarrett/knife-vagrant) if not specified

    -r, --vagrant-run-list RUN_LIST  Comma separated list of roles/recipes to apply before applying RECIPE

    -V, --verbose                    More verbose output. Use twice for max verbosity

    -v, --version                    Show chef version

    -y, --yes                        Say yes to all prompts for confirmation

    -h, --help                       Show this message


Disclaimer
-------------------

This is my first stab at it, so I can't make any promises as to how well it works just yet.
