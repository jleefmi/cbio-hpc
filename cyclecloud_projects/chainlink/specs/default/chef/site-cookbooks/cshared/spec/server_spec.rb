require 'spec_helper'

describe 'cshared::server' do
  context "Standard setup" do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(:platform => 'centos', :version => '6.5') do |node|
        node.default['cyclecloud']['mounts']['shared']['address'] = '127.0.0.1'
        node.default['cyclecloud']['mounts']['sched']['address'] = '127.0.0.1'

        node.default[:cyclecloud][:cluster][:user][:name] = 'root'
        node.default[:cyclecloud][:cluster][:user][:password] = 'root'
        node.default[:cyclecloud][:instance][:public_hostname] = 'my-public-hostname'
        node.default[:cyclecloud][:service_status][:routing_key] = 'my-routing-key'
      end.converge("cshared::server")
    end

    before do
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_call_original
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('nfs::server').and_return(true)
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('cshared::client').and_return(true)

      # Used in the samba section of cshared::server
      stub_command("pdbedit -L | grep root > /dev/null 2> /dev/null").and_return(false)
    end

    it "includes recipes" do
      # NOTE: For some reason this check doesn't work... asserting that we include the recipe is
      # a tad silly anyways, but woudl be good to do
      # expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('nfs::server')
      expect(chef_run).to include_recipe("cshared::directories")
      #expect(chef_run).to include_recipe("cshared::client")
      expect(chef_run).to include_recipe("samba::server")
      expect(chef_run).to include_recipe("jetpack")
    end

    %w{ shared sched }.each do |fs_name|
      export_path = "/mnt/exports/#{fs_name}"
      it 'creates mount directories' do
        expect(chef_run).to create_directory(export_path).with(user: 'root', group: 'root', mode: '0755')
        expect(chef_run).to_not create_directory('/')
      end

      it "exports #{fs_name}" do
        expect(chef_run).to create_nfs_export(export_path)  # TODO: can add with with options...
      end

      mountpoint = "/#{fs_name}"
      it 'creates symlinks to the mount directories' do
        expect(chef_run).to create_link(mountpoint).with(to: export_path)
      end
    end

    it 'configures samba for legacy shared' do
      expect(chef_run).to run_ruby_block('add cluster user to samba')
    end

    it 'creates the samba conf file' do
      expect(chef_run).to create_template('/etc/samba/smb.conf').with(
                                                                      source: "smb.conf.erb",
                                                                      owner: "root",
                                                                      group: "root",
                                                                      variables: ({:user => "root",
                                                                                   :shared_dir => "/mnt/exports/shared"})
                                                                      )
    end

    it 'creates nfs.json for service registration' do
      expect(chef_run).to render_file('/opt/cycle/jetpack/config/service.d/nfs.json')
    end

    it 'sends service registration via jetpack_send' do
      expect(chef_run).to send_jetpack_send('Registering NFS shared fs for monitoring.').with(routing_key: "my-routing-key.sharedfs", file: "/opt/cycle/jetpack/config/service.d/nfs.json")
    end

  end


  context "Extra Export" do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(:platform => 'centos', :version => '6.5') do |node|
        node.default['cyclecloud']['mounts']['shared']['address'] = '127.0.0.1'
        node.default['cyclecloud']['mounts']['sched']['address'] = '127.0.0.1'

        node.default['cyclecloud']['exports']['extra_export']['fs_type'] = 'nfs'
        node.default['cyclecloud']['exports']['extra_export']['export_path'] = '/mnt/exports/extra_export'
        node.default['cyclecloud']['exports']['extra_export']['mode'] = '0777'

        node.default['cyclecloud']['mounts']['extra_export']['fs_type'] = 'nfs'
        node.default['cyclecloud']['mounts']['extra_export']['export_path'] = '/mnt/exports/extra_export'
        node.default['cyclecloud']['mounts']['extra_export']['mountpoint'] = '/path/to/extra_export'
        node.default['cyclecloud']['mounts']['extra_export']['address'] = '127.0.0.1'

        node.default[:cyclecloud][:cluster][:user][:name] = 'root'
        node.default[:cyclecloud][:cluster][:user][:password] = 'root'

        node.default[:cyclecloud][:instance][:public_hostname] = 'my-public-hostname'
        node.default[:cyclecloud][:service_status][:routing_key] = 'my-routing-key'


      end.converge("cshared::server")
    end

    before do
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_call_original
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('nfs::server').and_return(true)
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('cshared::client').and_return(true)

      # Used in the samba section of cshared::server
      # This time pretend samba already ran
      stub_command("pdbedit -L | grep root > /dev/null 2> /dev/null").and_return(true)
    end

    %w{ shared sched extra_export }.each do |fs_name|
      export_path = "/mnt/exports/#{fs_name}"
      it 'creates mount directories' do
        if fs_name == "extra_export"
          mode = '0777'
        else
          mode = '0755'
        end
        expect(chef_run).to create_directory(export_path).with(user: 'root', group: 'root', mode: mode)
      end

      it "exports #{fs_name}" do
        expect(chef_run).to create_nfs_export(export_path)
      end
    end

    it 'configures samba for legacy shared' do
      expect(chef_run).to_not run_ruby_block('add cluster user to samba')
    end

    it 'creates the samba conf file' do
      expect(chef_run).to create_template('/etc/samba/smb.conf').with(
                                                                      source: "smb.conf.erb",
                                                                      owner: "root",
                                                                      group: "root",
                                                                      variables: ({:user => "root",
                                                                                   :shared_dir => "/mnt/exports/shared"})
                                                                      )
    end

  end

  context "Samba Disabled" do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(:platform => 'centos', :version => '6.5') do |node|
        node.default['cyclecloud']['mounts']['shared']['address'] = '127.0.0.1'
        node.default['cyclecloud']['mounts']['sched']['address'] = '127.0.0.1'
        node.default['cyclecloud']['exports']['shared']['samba']['enabled'] = false

        node.default[:cyclecloud][:cluster][:user][:name] = 'root'
        node.default[:cyclecloud][:cluster][:user][:password] = 'root'
        node.default[:cyclecloud][:instance][:public_hostname] = 'my-public-hostname'
        node.default[:cyclecloud][:service_status][:routing_key] = 'my-routing-key'
      end.converge("cshared::server")
    end

    before do
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_call_original
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('nfs::server').and_return(true)
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('cshared::client').and_return(true)

      # Used in the samba section of cshared::server
      stub_command("pdbedit -L | grep root > /dev/null 2> /dev/null").and_return(false)
    end

    it "includes recipes" do
      # NOTE: For some reason this check doesn't work... asserting that we include the recipe is
      # a tad silly anyways, but woudl be good to do
      # expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('nfs::server')
      expect(chef_run).to include_recipe("cshared::directories")
      #expect(chef_run).to include_recipe("cshared::client")
      expect(chef_run).not_to include_recipe("samba::server")
      expect(chef_run).to include_recipe("jetpack")
    end

    %w{ shared sched }.each do |fs_name|
      export_path = "/mnt/exports/#{fs_name}"
      it 'creates mount directories' do
        expect(chef_run).to create_directory(export_path).with(user: 'root', group: 'root', mode: '0755')
        expect(chef_run).to_not create_directory('/')
      end

      it "exports #{fs_name}" do
        expect(chef_run).to create_nfs_export(export_path)  # TODO: can add with with options...
      end

      mountpoint = "/#{fs_name}"
      it 'creates symlinks to the mount directories' do
        expect(chef_run).to create_link(mountpoint).with(to: export_path)
      end
    end

    it 'creates nfs.json for service registration' do
      expect(chef_run).to render_file('/opt/cycle/jetpack/config/service.d/nfs.json')
    end

    it 'sends service registration via jetpack_send' do
      expect(chef_run).to send_jetpack_send('Registering NFS shared fs for monitoring.').with(routing_key: "my-routing-key.sharedfs", file: "/opt/cycle/jetpack/config/service.d/nfs.json")
    end

  end

end
