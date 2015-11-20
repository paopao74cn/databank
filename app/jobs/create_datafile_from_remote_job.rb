require 'tempfile'
require 'open-uri'
require 'fileutils'
require 'net/http'

class CreateDatafileFromRemoteJob < ProgressJob::Base
  # queue_as :default

  def initialize(dataset_id, datafile, remote_url, filename, filesize)
    @remote_url = remote_url
    @dataset_id = dataset_id
    @datafile = datafile
    @filename = filename

    if filesize.to_f < 10000
      progress_max = 2
    else
      progress_max = (filesize.to_f/10000).to_i + 1
    end

    super progress_max: progress_max
  end

  def perform

    dir_name = "#{Rails.root}/public/uploads/#{@dataset_id}"

    FileUtils.mkdir_p(dir_name) unless File.directory?(dir_name)

    filepath = "#{dir_name}/#{@filename}"

    File.open(filepath, 'wb+') do |outfile|
      uri = URI.parse(@remote_url)
      Net::HTTP.start(uri.host,uri.port, :use_ssl => (uri.scheme == 'https')  ){ |http|
        http.request_get(uri.path){ |res|

          # # Works with the response object as well:
          # res.each_header do |header_name, header_value|
          #   Rails.logger.warn "#{header_name} : #{header_value}"
          # end

          # seg_count = 1

          res.read_body{ |seg|
            #Rails.logger.warn "seg_count: #{seg_count}"
            outfile << seg
            #seg_count = seg_count + 1
            update_progress()
          }
        }
      }


    end


    if File.file?(filepath)
      @datafile.binary = Rails.root.join("public/uploads/#{@dataset_id}/#{@filename}").open
      @datafile.save!
    end



    # uri = URI.parse(@remote_url)
    # Net::HTTP.start(uri.host,uri.port){ |http|
    #   http.request_get(uri.path){ |res|
    #     res.read_body{ |seg|
    #       outfile << seg
    #       #hack -- adjust to suit:
    #       #sleep 0.005
    #     }
    #   }
    # }


    # f = open("/public/uploads/test.txt", "wb+")
    #
    # begin
    #   http.request_get(@remote_url) do |resp|
    #     resp.read_body do |segment|
    #       f.write(segment)
    #     end
    #   end
    # ensure
    #   f.close()
    # end

    # @progress_max.times do |count|W
    #   update_progress
    # end



  end

end



# class CreateDatafileFromRemoteJob < ProgressJob::Base
#   # queue_as :default
#
#   def initialize(dataset_id, remote_url, progress_max)
#     @remote_url = remote_url
#     @dataset_id = dataset_id
#     super progress_max: Integer(progress_max)
#   end
#
#   def perform
#
#    100.times do |count|
#
#       update_progress
#     end
#
#    Datafile.create(:remote_binary_url => @remote_url, :dataset_id => @dataset_id)
#
#   end
#
# end
