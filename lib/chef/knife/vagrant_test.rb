# knife-vagrant
# knife plugin for spinning up a vagrant instance and testing a runlist.

module KnifePlugins
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

    option :port_forward,
      :short => '-p PORTS',
      :long => '--port-forward PORTS',
      :description => "Port forwarding.  Host port, VM port separated by a colon.  E.G. to forward 80 on the host machine to 8080 on the VM, -p 80:8080.  To list multiple forwards separate with a comma, e.g. \"-p 80:8080,22:2222\"",
      :proc => lambda { |o| Hash[o.split(/,/).collect { |a| a.split(/:/) }] },
      :default => {}
 
    option :vagrant_dir,
      :short => '-D PATH',
      :long => '--vagrant-dir PATH',
      :description => "Path to vagrant project directory.  Defaults to cwd (#{Dir.pwd}) if not specified",
      :default => Dir.pwd
      
    option :vagrant_run_list,
      :short => "-r RUN_LIST",
      :long => "--vagrant-run-list RUN_LIST",
      :description => "Comma separated list of roles/recipes to apply",
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

    def build_port_forwards(ports)
      ports.collect { |k, v| "config.vm.forward_port(#{k}, #{v})" }.join("\n")
    end

    # TODO:  see if there's a way to pass this whole thing in as an object or hash or something, instead of writing a file to disk.
    def build_vagrantfile
      file = <<-EOF
        Vagrant::Config.run do |config|
          #{build_port_forwards(config[:port_forward])}
          config.vm.box = "#{config[:box]}"
          config.vm.host_name = "#{config[:hostname]}"
          config.vm.customize [ "modifyvm", :id, "--memory", #{config[:memsize]} ]
          config.vm.customize [ "modifyvm", :id, "--name", "#{config[:box]}" ]
          config.vm.box_url = "#{config[:box_url]}"
          config.vm.provision :chef_client do |chef|
            chef.chef_server_url = "#{Chef::Config[:chef_server_url]}"
            chef.validation_key_path = "#{Chef::Config[:validation_key]}"
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
      @vagrant_env = Vagrant::Environment.new(:cwd => config[:vagrant_dir], :ui_class => Vagrant::UI::Colored)
      @vagrant_env.load!
      begin
        @vagrant_env.cli("up")
      rescue
        raise # I'll put some error handling here later.
      ensure
        if config[:destroy]
          ui.confirm("Destroy vagrant box #{config[:box]} and delete chef node and client")
          args = %w[ destroy --force ]
          @vagrant_env.cli(args)
          config[:yes]
          delete_object(Chef::Node, config[:hostname])
          delete_object(Chef::ApiClient, config[:hostname])
        end
      end
    end

  end
end
