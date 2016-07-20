CarrierWave.configure do |config|
  # These permissions will make dir and files available only to the user running
  # the servers
  config.permissions = 0755
  config.directory_permissions = 0755
  config.storage = :file

end