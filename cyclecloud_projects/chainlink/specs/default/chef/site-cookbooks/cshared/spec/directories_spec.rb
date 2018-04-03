require 'spec_helper'

describe 'cshared::directories' do
  context "Standard setup" do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(:platform => 'centos', :version => '6.5') do |node|
      end.converge("cshared::directories")
    end

    it 'creates base directories' do
      expect(chef_run).to create_directory("/mnt/exports").with(user: 'root', group: 'root', mode: '0755')
      expect(chef_run).to create_directory("/mnt/exports/shared").with(user: 'root', group: 'root', mode: '0755')
      expect(chef_run).to create_directory("/mnt/exports/sched").with(user: 'root', group: 'root', mode: '0755')
    end

    it 'creates shared subdirs' do
      expect(chef_run).to create_directory("/mnt/exports/shared/home").with(user: 'root', group: 'root', mode: '0755')
      expect(chef_run).to create_directory("/mnt/exports/shared/bin").with(user: 'root', group: 'root', mode: '0755')
      expect(chef_run).to create_directory("/mnt/exports/shared/man").with(user: 'root', group: 'root', mode: '0755')
      expect(chef_run).to create_directory("/mnt/exports/shared/scratch").with(user: 'root', group: 'root', mode: '0777')
    end

    it 'creates symlinks' do
      expect(chef_run).to create_link("/shared").with(to: "/mnt/exports/shared")
      expect(chef_run).to create_link("/sched").with(to: "/mnt/exports/sched")
    end
  end
end

