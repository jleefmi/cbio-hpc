require 'spec_helper'

# Missing things to test:
#  -> NFS - Server is the client, creates links
#  -> Search vs passed in address
#  -> skips disabled mounts?

describe 'cshared::default' do
  context "Mounts a NFS filesystem on LINUX" do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(step_into: ['cshared::nfs'], :platform => 'centos', :version => '6.5') do |node|
        node.default['cyclecloud']['mounts']['nfs'] = {
          'type' => 'nfs',
          'export_path' => '/exports/data',
          'address' => '1.2.3.4',
          'mountpoint' => '/data',
          'options' => 'option1,option2'
        }
      end.converge("cshared::default")
    end

    before do
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_call_original
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('nfs')
    end

    it 'includes the nfs::default recipe' do
      expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('nfs')
      chef_run
    end

    it 'creates the nfs directory' do
      expect(chef_run).to create_directory('/data')
    end

    it 'mounts and enables the filesystem' do
      expect(chef_run).to mount_mount('/data').with({
        :device => "1.2.3.4:/exports/data",
        :fstype => "nfs",
        :pass => 0,
        :options => ["option1", "option2"],
        :retries => 5,
        :retry_delay => 30
      })

      expect(chef_run).to enable_mount('/data')
    end
  end

  context "Mounts a NFS filesystem on WINDOWS" do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(:platform => 'windows', :version => '2012R2') do |node|
        node.default['cyclecloud']['mounts']['nfs'] = {
          'type' => 'nfs',
          'export_path' => '/exports/data',
          'address' => '1.2.3.4',
          'mountpoint' => '/data',
          'options' => 'option1,option2',
          'windevice' => 'Z'
        }
      end.converge("cshared::default")
    end

    it 'mounts and enables the filesystem' do
      expect(chef_run).to mount_mount('Z:').with({
        :device => '\\\\1.2.3.4\\nfs',
        :retries => 5,
        :retry_delay => 30
      })
    end
  end

  context "Mounts a Lustre filesystem on LINUX" do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(:platform => 'centos', :version => "6.5") do |node|

        # Set up a lustre filer mountpoint
        node.default['cyclecloud']['mounts']['lustre'] = {
          'type' => 'lustre',
          'address' => '1.2.3.4'        }
      end.converge("cshared::default")
    end

    before do
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_call_original
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('lustre::client')
      stub_command("cat /etc/fstab | grep \"/mnt/lustre\"").and_return false
    end

    it 'includes the lustre::client recipe' do
      # We check for include_recipe calls this way to prevent the include_recipe specs from being
      # tested, those are tested in the lustre cookbook itself. See the chefspec homepage for more details.
      expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('lustre::client')
      chef_run
    end

    it 'creates the lustre mountpoint dir' do
      expect(chef_run).to create_directory('/mnt/lustre')
    end

    it 'mounts and enables the filesystem' do
      expect(chef_run).to mount_mount('/mnt/lustre').with({
        :device => "1.2.3.4:/lustre",
        :fstype => "lustre",
        :pass => 0,
        :options => [],
        :retries => 5,
        :retry_delay => 30
      })

      expect(chef_run).to enable_mount('/mnt/lustre')
    end

  end
end
