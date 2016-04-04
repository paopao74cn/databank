require 'rake'
require 'bunny'
require 'json'

namespace :test do

  desc 'send a RabbitMQ message'
  task :send_msg => :environment do
    puts "sending message"

    idbconfig = YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]

    config = (idbconfig['amqp'] || {}).symbolize_keys

    config.merge!(recover_from_connection_close: true)

    conn = Bunny.new(config)
    conn.start

    ch = conn.create_channel
    q  = ch.queue("idb_to_medusa", :durable => true)
    x  = ch.default_exchange

    # q.subscribe do |delivery_info, metadata, payload|
    #   puts "Received #{payload}"
    # end

    x.publish("This might be a message.", :routing_key => q.name)

    conn.close

  end

  desc 'get a RabbitMQ message'
  task :get_msg => :environment do
    puts "getting message"

    idbconfig = YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]

    config = (idbconfig['amqp'] || {}).symbolize_keys

    config.merge!(recover_from_connection_close: true)

    conn = Bunny.new(config)
    conn.start

    ch = conn.create_channel
    q  = ch.queue("medusa_to_idb", :durable => true)
    x  = ch.default_exchange

    delivery_info, properties, payload = q.pop
    if payload.nil?
      puts "No message found."
    else
      puts "This is the message: " + payload + "\n\n"
    end

    conn.close

  end

  desc 'simulate RabbitMQ ok response from Medusa'
  task :send_ok => :environment do
    puts "sending message"

    idbconfig = YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]

    config = (idbconfig['amqp'] || {}).symbolize_keys

    config.merge!(recover_from_connection_close: true)

    conn = Bunny.new(config)
    conn.start

    ch = conn.create_channel
    q  = ch.queue("medusa_to_idb", :durable => true)
    x  = ch.default_exchange

    # q.subscribe do |delivery_info, metadata, payload|
    #   puts "Received #{payload}"
    # end

    msg_hash = {status: 'ok',
                operation: 'ingest',
                staging_path: 'uploads/5g06s/test.txt',
                medusa_path: '5g06s_test.txt',
                medusa_uuid: '149603bb-0cad-468b-9ef0-e91023a5d455',
                error: ''}

    x.publish("#{msg_hash.to_json}", :routing_key => q.name)

    conn.close

  end

  desc 'simulate RabbitMQ error response from Medusa'
  task :send_error => :environment do
    puts "sending message"

    idbconfig = YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]

    config = (idbconfig['amqp'] || {}).symbolize_keys

    config.merge!(recover_from_connection_close: true)

    conn = Bunny.new(config)
    conn.start

    ch = conn.create_channel
    q  = ch.queue("medusa_to_idb", :durable => true)
    x  = ch.default_exchange

    # q.subscribe do |delivery_info, metadata, payload|
    #   puts "Received #{payload}"
    # end

    msg_hash = {status: 'error',
                operation: 'ingest',
                staging_path: 'uploads/tbzaq/test.txt',
                medusa_path: '',
                medusa_uuid: '',
                error: 'malformed thingy'}

    x.publish("#{msg_hash.to_json}", :routing_key => q.name)

    conn.close

  end

  desc 'send duplicate file messages'
  task :send_medusa_dup => :environment do

    File.open("#{IDB_CONFIG[:datafile_store_dir]}/test/test.txt", "w") do |test_file|
      test_file.write("Initial placeholder content for test file.")
    end
    puts "creating ingest message"
    medusa_ingest = MedusaIngest.new
    staging_path = "uploads/test/test.txt"
    medusa_ingest.staging_path = staging_path
    medusa_ingest.idb_class = 'test'
    medusa_ingest.idb_identifier = "test_1"
    medusa_ingest.send_medusa_ingest_message(staging_path)
    medusa_ingest.save

    File.open("#{IDB_CONFIG[:datafile_store_dir]}/test/test.txt", "w") do |test_file|
      test_file.write("Changed content for test file. If this gets into Medusa, something has gone wrong.")
    end
    puts "creating ingest message"
    medusa_ingest = MedusaIngest.new
    staging_path = "uploads/test/test.txt"
    medusa_ingest.staging_path = staging_path
    medusa_ingest.idb_class = 'test'
    medusa_ingest.idb_identifier = "test_2"
    medusa_ingest.send_medusa_ingest_message(staging_path)
    medusa_ingest.save


  end
  
end