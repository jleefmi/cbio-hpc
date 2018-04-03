require 'chefspec'
require 'fauxhai'

ChefSpec::Coverage.start! do
  # Ignore 3rd party included cookbooks in coverage report
  add_filter File.expand_path('../../../nfs', __FILE__)
  add_filter File.expand_path('../../../samba', __FILE__)
end

RSpec.configure do |config|
  config.log_level = :error
  config.cookbook_path = ['../../cookbooks', '../../berks-cookbooks']
end

# Require all our libraries
Dir['libraries/*.rb'].each { |f| require File.expand_path(f) }
