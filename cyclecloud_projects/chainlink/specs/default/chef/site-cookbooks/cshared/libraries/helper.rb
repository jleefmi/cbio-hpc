module CycleCloud
  module Mounts
    module Helpers

      # Is the hash passed in a nfs mount?
      # TODO: We could treat all mounts as a class (Class::Mount) for example:
      # class Mount
      #
      #   TODO: apply default values here too!
      #   def initialize(mount)
      #     @type = mount['type'] || mount['fs_type'] || ''
      #     @other_variables_here = true
      #   end
      #
      #   def nfs?
      #     return @type == "nfs"
      #   end
      #
      #   def disabled?
      #      return false
      #   end
      # end
      # Note: If we did this probably dont' need it in 'CycleCloud::Mounts' just
      # 'CycleCloud::Helpers'

      # If mount address not set, search for filer in cluster: cluster_name or local cluster if no cluster_name set
      def search_for_filer(node, name, recipe="cshared::server")

        server_ip = nil
        if node['cyclecloud']['mounts'][name][:address].nil?
          cluster_UID = node['cyclecloud']['mounts'][name][:cluster_name]
          if cluster_UID.nil?
            # Default to local cluster filer
            cluster_UID = node[:cyclecloud][:cluster][:id]
          end

          if cluster_UID == "all"
            Chef::Log.info "Searching for the #{name} filer in all clusters."
            cluster_UID = cluster_UID.intern
          elsif cluster_UID == node[:cyclecloud][:cluster][:id]
            Chef::Log.info "Searching for the cluster-local filer as #{name} filer in cluster: #{cluster_UID}"
          else
            Chef::Log.info "Searching for the #{name} filer in cluster: #{cluster_UID}"
          end

          filer = cluster.search(:clusterUID => cluster_UID, :recipe => recipe, :singular => "Filer #{name} not found")
          server_ip = filer[:cyclecloud][:instance][:ipv4]

          # Store the filer IP
          node.default['cyclecloud']['mounts'][name]['address'] = server_ip
          if name == 'shared'
            # Backwards compat.:  Also set legacy attribute for the basic "/shared" filer
            node.default['cshared']['client']['filer_ip'] = server_ip
          end

        else
          server_ip = node['cyclecloud']['mounts'][name]['address']
        end

        return server_ip
      end

      # Is the hash/mash we passed in representing an nfs mount?
      def nfs_mount?(mount)
        # Convert the mount to a mash so we can support both :type and 'fs_type'
        # accessors
        mount = Mash.new(mount)
        type = ''

        # Prefer "type" over "fs_type"
        if not mount['type'].nil? and not mount['type'].empty?
          type = mount['type']
        elsif not mount['fs_type'].nil? and not mount['fs_type'].empty?
          type = mount['fs_type']
        end

        if type != "nfs"
          return false
        else
          return true
        end
      end

      def disabled?(mount)
        mount = Mash.new(mount)
        return (not mount['disabled'].nil? and mount['disabled'] == true)
      end

      def apply_defaults(name, mount, defaults)

        # Apply current defaults to unset attributes (ensure mount overrides default)
        merged = defaults.merge(mount)

        # "type" and "fs_type" are synonyms (but if both set, prefer "type")
        if merged['type'].nil? and merged.key?('fs_type')
          merged['type'] = merged['fs_type']
        end

        # If mountpoint isn't specified, use /mnt/<name>
        if merged['mountpoint'].nil?
          merged['mountpoint'] = "/mnt/#{name}"
        end

        return merged
      end

    end
  end

end
