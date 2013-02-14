# knife-vagrant
# knife plugin for spinning up a vagrant instance and testing a runlist.

module KnifePlugins

  class VagrantServer < Chef::Knife
    banner "knife vagrant server [SUB-COMMAND]"
    
    def run
    end

    #
    class VagrantServerSsh < VagrantServer
      banner "knife vagrant server ssh [hostname]"
      deps do
        require 'vagrant'
        require 'vagrant/cli'
      end

      option :hostname,
        :short => '-H HOSTNAME',
        :long => '--hostname HOSTNAME',
        :description => 'Hostname to be set as hostname on vagrant box when provisioned'

      option :vagrant_dir,
        :short => '-D PATH',
        :long => '--vagrant-dir PATH',
        :description => "Path to vagrant project directory.  Defaults to cwd (#{Dir.pwd}) if not specified",
        :default => Dir.pwd + "/vagrant"

      def run
        unless config[:hostname] || name_args.size >= 1
          ui.fatal "Please provide a box name."
          show_usage
          exit 1
        end
        
        if name_args.size >= 1 then 
          hostname = name_args.first
        else 
          hostname = config[:hostname] 
        end
        
        
        @vagrant_env = Vagrant::Environment.new(:cwd => "#{config[:vagrant_dir]}/#{hostname}/", :ui_class => Vagrant::UI::Colored)
        @vagrant_env.cli("ssh")
      end
    end

    #
    class VagrantServerList < Chef::Knife
      banner "knife vagrant server list"

      deps do
        require 'vagrant'
        require 'vagrant/cli'
      end

      def run
        @vagrant_env = Vagrant::Environment.new(:ui_class => Vagrant::UI::Colored)
        @vagrant_env.cli("box","list")
      end
    end

    #
    class VagrantServerCreate < VagrantServer
      banner "knife vagrant server create (options)"

      deps do
        require 'vagrant'
        require 'vagrant/cli'
      end

      option :networks,
        :short => '-n NETWORKS',
        :long => '--networks ',
        :description => 'Network definitions. Comma separated network entries containing type:data Pairs. Where data is network adress or bridge info',
        :proc => lambda { |o| o.split(/,/).collect { |a| a.split(/:/) } },
        :default => []

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
        :default => Dir.pwd + "/vagrant"
        
      option :vagrant_run_list,
        :short => "-r RUN_LIST",
        :long => "--vagrant-run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => ["role[base]"]

      option :hostname,
        :short => '-H HOSTNAME',
        :long => '--hostname HOSTNAME',
        :description => 'Hostname to be set as hostname on vagrant box when provisioned'

      option :box_url,
        :short => '-U URL',
        :long => '--box-url URL',
        :description => 'URL of pre-packaged vbox template.  Can be a local path or an HTTP URL.  Defaults to ./package.box',
        :default => "#{Dir.pwd}/package.box"

      option :box,
        :short => '-b BOXNAME',
        :long => '--box BOXNAME',
        :description => 'specify a boxname to use',
        :default => ""

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

      option :json_attributes,
        :short => '-j JSON',
        :long => '--json-attributes JSON',
        :description => 'A JSON string to be added to the first run of chef-client',
        :proc => lambda { |o| JSON.parse(o) },
        :default => {} 

      option :share_folders,
        :short => '-S',
        :long => '--share-folders  SHARES',
        :description => 'Comma separated list of share folders in the form of  NAME::GUEST_PATH::HOST_PATH',
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      # TODO - hook into chef/runlist
      def build_runlist(runlist)
        runlist.collect { |i| "\"#{i}\"" }.join(",\n")
      end

      def build_port_forwards(ports)
        ports.collect { |k, v| "config.vm.forward_port(#{k}, #{v})" }.join("\n")
      end

      def parse_hostonly(network)
        addr, mask = network.split("/")
        config = "\"#{addr}\""
        if mask
          config << ", :netmask => \"#{mask}\""
        end
        config
      end

      def build_networks(networks)
        output = ""
        networks.each do |net|
          case net[0].downcase
          when "bridge"
            output << "config.vm.network :bridged, :bridge => #{net[1]}\n"
          when "hostonly"
            output << "config.vm.network :hostonly, #{parse_hostonly(net[1])}\n"
          end
        end
        output
      end

      def shares 
        shares=""
        config[:share_folders].each do |share|
          name,guest,host = share.chomp.split "::"
          shares << "config.vm.share_folder '#{name}', '#{guest}', '#{host}' "
        end 
        shares
      end

      # TODO:  see if there's a way to pass this whole thing in as an object or hash or something, instead of writing a file to disk.
      def build_vagrantfile
        # if no box is given use hostname for the box otherwise use
        # whats specified
        box = "config.vm.box = '#{config[:hostname]}'"
        unless config[:box].empty?
          box =  "config.vm.box = '#{config[:box]}'"
        end 

        file = <<-EOF
          Vagrant::Config.run do |config|
            #{build_port_forwards(config[:port_forward])}
            #{box}
            #{shares}
            config.vm.host_name = "#{config[:hostname]}"
            config.vm.customize [ "modifyvm", :id, "--memory", #{config[:memsize]} ]
            config.vm.customize [ "modifyvm", :id, "--name", "#{config[:hostname]}" ]
            config.vm.box_url = "#{config[:box_url]}"
            #{build_networks(config[:networks])}
            config.vm.provision :chef_client do |chef|
              chef.chef_server_url = "#{Chef::Config[:chef_server_url]}"
              chef.validation_key_path = "#{Chef::Config[:validation_key]}"
              chef.validation_client_name = "#{Chef::Config[:validation_client_name]}"
              chef.node_name = "#{config[:hostname]}"
              chef.log_level = :#{config[:chef_loglevel].downcase}
              chef.environment = "#{Chef::Config[:environment]}"
              chef.json = #{config[:json_attributes]}
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

      def ensure_dir(dir)
        unless File.directory? dir 
          puts  "Creating #{dir}" 
          Dir.mkdir(dir) 
        end
      end

      #
      def run
        puts "Initializing..."
        vagrantfile = "Vagrantfile"
        vagrantdir = "#{config[:vagrant_dir]}/#{config[:hostname]}/"

        # make sure parent dir is there before we try to use it
        ensure_dir(config[:vagrant_dir])
        ensure_dir(vagrantdir)

        write_vagrantfile("#{vagrantdir}/#{vagrantfile}", build_vagrantfile)
        @vagrant_env = Vagrant::Environment.new(:cwd => vagrantdir, :ui_class => Vagrant::UI::Colored)
        
        begin
          @vagrant_env.cli("up")
        rescue
          raise # I'll put some error handling here later.
        ensure
        end
      end
    end

    #
    class VagrantServerDelete < Chef::Knife
      banner "knife vagrant server delete [hostname] (args)"

      deps do
        require 'vagrant'
        require 'vagrant/cli'
        require 'chef/node'
        require 'chef/api_client'
      end

      option :hostname,
        :short => '-H HOSTNAME',
        :long => '--hostname HOSTNAME',
        :description => 'Hostname to be set as hostname on vagrant box when provisioned'
      option :vagrant_dir,
        :short => '-D PATH',
        :long => '--vagrant-dir PATH',
        :description => "Path to vagrant project directory.  Defaults to cwd (#{Dir.pwd}) if not specified",
        :default => Dir.pwd + "/vagrant"

      def run
        unless config[:hostname] || name_args.size >= 1
          ui.fatal "Please provide a hostname."
          show_usage
          exit 1
        end
        
        if name_args.size >= 1 then 
          hostname = name_args.first
        else 
          hostname = config[:hostname] 
        end

        vagrantfile = "Vagrantfile"
        vagrantdir = "#{config[:vagrant_dir]}/#{hostname}/"

        # confirm delete
        ui.confirm("Destroy vagrant box #{hostname} and delete chef node and client")
        
        #Dir.chdir("#{config[:vagrant_dir]}/#{config[:hostname]}/")
        @vagrant_env = Vagrant::Environment.new(:cwd => vagrantdir, :ui_class => Vagrant::UI::Colored)
        @vagrant_env.cli("box","remove",hostname)
        delete_object(Chef::Node, hostname)
        delete_object(Chef::ApiClient, hostname)
        Dir.delete( vagrantdir )
      end

    end

  end
end
