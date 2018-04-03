require 'spec_helper'

describe CycleCloud::Mounts::Helpers do

  # Include our helpers module in a class that we can test with!
  class HelperClass
    include CycleCloud::Mounts::Helpers
  end
  before(:all) do
    @helper = HelperClass.new
  end

  describe '#nfs_mount?' do
    it "has 'fs_type=nfs'" do
      expect(@helper.nfs_mount?({:fs_type => "nfs"})).to be(true)
    end
    it "has 'type=nfs'" do
      expect(@helper.nfs_mount?({:type => "nfs"})).to be(true)
    end
    it "has 'type=other'" do
      expect(@helper.nfs_mount?({:fs_type => "other"})).to be(false)
    end
    it "has no type" do
      expect(@helper.nfs_mount?({})).to be(false)
    end
  end

  describe '#disabled?' do
    it 'is not disabled' do
      expect(@helper.disabled?({})).to be(false)
      expect(@helper.disabled?({:disabled => false})).to be(false)
    end

    it 'is disabled' do
      expect(@helper.disabled?({:disabled => true})).to be(true)
    end
  end

end
