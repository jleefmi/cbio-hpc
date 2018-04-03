require 'spec_helper'

describe 'cshared::client' do
  context "Standard setup" do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(:platform => 'centos', :version => '6.5') do |node|
        node.default['cyclecloud']['mounts']['shared']['address'] = 'localhost'
        node.default['cyclecloud']['mounts']['sched']['address'] = 'localhost'

      end.converge("cshared::client")
    end

    %w{ shared sched }.each do |fs_name|
      mountpoint = "/#{fs_name}"
      it 'creates mount directories' do
        expect(chef_run).to create_directory(mountpoint).with(user: 'root', group: 'root', mode: '0755')
      end

      it 'mounts and enables the filesystems' do
        expect(chef_run).to mount_mount(mountpoint).with(fstype: 'nfs', device: "localhost:/mnt/exports/#{fs_name}")
        expect(chef_run).to enable_mount(mountpoint)
      end

      it 'creates a link from the legacy location' do
        expect(chef_run).to create_directory("/mnt/exports")
      end      

      it 'creates a link from the legacy location' do
        expect(chef_run).to create_link("/mnt/exports/#{fs_name}").with(to: "/#{fs_name}")
      end      
    end
  end
end
