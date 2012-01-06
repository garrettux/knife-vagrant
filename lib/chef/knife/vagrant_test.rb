# knife-vagrant
# knife plugin for spinning up a vagrant instance and testing a runlist.

module KnifeVagrant
  class VagrantTest < Chef::Knife

    banner "knife vagrant test (options)"

    deps do
      require 'rubygems'
      require 'pp'
      require 'vagrant'
      require 'vagrant/cli'
      require 'chef/node'
      require 'chef/api_client'
    end
 
    # Default is nil here because if :cwd passed to the Vagrant::Environment object is nil,
    # it defaults to Dir.pwd, which is the cwd of the running process.
    option :vagrant_dir,
      :short => '-D PATH',
      :long => '--vagrant-dir PATH',
      :description => "Path to vagrant project directory.  Defaults to cwd (#{Dir.pwd}) if not specified",
      :default => nil
      
    option :vagrant_run_list,
      :short => "-r RUN_LIST",
      :long => "--vagrant-run-list RUN_LIST",
      :description => "Comma separated list of roles/recipes to apply before applying RECIPE",
      :proc => lambda { |o| o.split(/[\s,]+/) },
      :default => []
 
    option :box,
      :short => '-b BOX',
      :long => '--box BOX',
      :description => 'Name of vagrant box to be provisioned',
      :default => false

    option :hostname,
      :short => '-H HOSTNAME',
      :long => '--hostname HOSTNAME',
      :description => 'Hostname to be set as hostname on vagrant box when provisioned',
      :default => 'vagrant_test'

    option :box_url,
      :short => '-U URL',
      :long => '--box-url URL',
      :description => 'URL of pre-packaged vbox template.  Can be a local path or an HTTP URL.  Defaults to ./package.box',
      :default => "#{Dir.pwd}/package.box"

    option :memsize,
      :short => '-m MEMORY',
      :long => '--memsize MEMORY',
      :description => 'Amount of RAM to allocate to provisioned VM, in MB.  Defaults to 1024',
      :default => 1024
  
    option :chef_loglevel,
      :short => '-l LEVEL',
      :long => '--chef-loglevel LEVEL',
      :description => 'Logging level for the chef-client process that runs inside the provisioned VM.  Default is INFO',
      :default => 'INFO'

    option :destroy,
      :short => '-x',
      :long => '--destroy',
      :description => 'Destroy vagrant box and delete chef node/client when finished',
      :default => false

    # TODO - hook into chef/runlist
    def build_runlist(runlist)
      runlist.collect { |i| "\"#{i}\"" }.join(",\n")
    end

    # got almost finished with this and remembered I could have used ERB... I'll switch it over to ERB template when i start packaging it as a gem
    def build_vagrantfile
      file = <<-EOF
        Vagrant::Config.run do |config|
          config.ssh.forwarded_port_key = "ssh"
          config.vm.forward_port("ssh", 22, 2222)
          config.vm.box = "#{config[:box]}"
          config.vm.host_name = "#{config[:hostname]}"
          config.vm.customize do |vm|
            vm.memory_size = #{config[:memsize]}
            vm.name = "#{config[:box]}"
          end
          config.vm.box_url = "#{config[:box_url]}"
          config.vm.provision :chef_client do |chef|
            chef.chef_server_url = "#{Chef::Config[:chef_server_url]}"
            chef.validation_key_path = "#{Chef::Config[:validation_key_path]}"
            chef.validation_client_name = "#{Chef::Config[:validation_client_name]}"
            chef.node_name = "#{config[:hostname]}"
            chef.provisioning_path = "#{Chef::Config[:provisioning_path]}"
            chef.log_level = :#{config[:chef_loglevel].downcase}
            chef.environment = "#{Chef::Config[:environment]}"
            chef.run_list = [
              #{build_runlist(config[:vagrant_run_list])}
            ]
          end
        end
      EOF
      file
    end
      
    def write_vagrantfile(path, content)
      File.open(path, 'w') { |f| f.write(content) }
    end
  
    def cleanup(path)
      File.delete(path)
    end
    
    def run
      ui.msg('Loading vagrant environment..')
      Dir.chdir(config[:vagrant_dir])
      vagrantfile = "#{config[:vagrant_dir]}/Vagrantfile"
      write_vagrantfile(vagrantfile, build_vagrantfile)
      @vagrant_env = Vagrant::Environment.new(:cwd => config[:vagrant_dir])
      @vagrant_env.ui = Vagrant::UI::Shell.new(@vagrant_env, Thor::Base.shell.new) 
      @vagrant_env.load!
      begin
        @vagrant_env.cli("up")
      rescue
        raise # I'll put some error handling here later.
      ensure
        if config[:destroy]
          ui.confirm("Destroy vagrant box #{config[:box]} and delete chef node and client")
          config[:yes] = true unless config[:yes]
          @vagrant_env.cli("destroy")
          delete_object(Chef::Node, config[:hostname])
          delete_object(Chef::ApiClient, config[:hostname])
        end
      end
    end

  end
end
