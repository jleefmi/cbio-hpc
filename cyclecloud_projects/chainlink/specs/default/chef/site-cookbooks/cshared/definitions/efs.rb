::Chef::Recipe.send(:include, CycleCloud::Mounts::Helpers)


define :efs_mount, :data => "" do

  name = params[:name]
  data = params[:data].to_hash

  data['type'] = 'nfs4'
  if data['options'].nil?
    data['options'] = "nfsvers=4.1"
  end
  data['export_path'] = '/'
  if not data['filesystem_id'].nil? and data['address'].nil?
    zone = node['cyclecloud']['instance']['zone']
    region = node['cyclecloud']['instance']['region']
    filesystem_id = data['filesystem_id']
    data['address'] = "#{zone}.#{filesystem_id}.efs.#{region}.amazonaws.com"
  elsif not data['filesystem_id'].nil? and not data['address'].nil?
    Chef::Log.warn("Both 'address' and 'filesystem_id' specified for EFS mount '#{name}' - using 'address'")
  end

  if data['filesystem_id'].nil? and data['address'].nil?
    raise("Neither 'address' nor 'filesystem_id' specified for EFS mount '#{name}'!") 
  end
  nfs_mount name do
    data data
  end
end