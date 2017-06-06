require 'zip'

class Datafile < ActiveRecord::Base
  include ActiveModel::Serialization
  mount_uploader :binary, BinaryUploader
  belongs_to :dataset
  audited associated_with: :dataset

  WEB_ID_LENGTH = 5

  before_create { self.web_id ||= generate_web_id }

  before_destroy 'destroy_job'
  before_destroy 'remove_directory'

  # after_save 'chmod_binary_for_medusa'

  def to_param
    self.web_id
  end

  def as_json(options={})
    super(:only => [:web_id, :binary_name, :binary_size, :medusa_id, :created_at, :updated_at])
  end

  def file_download_tallies
    FileDownloadTally.where(file_web_id: self.web_id)
  end

  def total_downloads
    FileDownloadTally.where(file_web_id: self.web_id).sum :tally
  end

  def bytestream_name
    return_name = ""
    if self.binary_name && self.binary_name != ""
      return_name = self.binary_name
    elsif self.binary && self.binary.file
      return_name = self.binary.file.filename

    else
      return "error: filename not found"
    end
    return_name
  end

  def bytestream_size

    if self.binary_size
      self.binary_size
    elsif self.binary
      self.binary.size
    else
      0
    end

  end

  def file_extension
    filename_split = self.bytestream_name.split(".")

    if filename_split.count > 1 # otherwise cannot determine extension

      return filename_split.last

    else
      return ""

    end

  end

  def bytestream_path
    if self.medusa_path.nil? || self.medusa_path.empty?
      self.binary.path
    else
      "#{IDB_CONFIG['medusa']['medusa_path_root']}/#{self.medusa_path}"
    end
  end

  def preview
    if self.bytestream_name != ""
      filename_split = self.bytestream_name.split(".")

      if filename_split.count > 1 # otherwise cannot determine extension

        case filename_split.last # extension

          when 'txt', 'csv', 'tsv', 'rb', 'xml', 'json'
            return File.read(self.bytestream_path)

          when 'zip'
            entry_list_text = `unzip -l "#{self.bytestream_path}"`

            entry_list_array = entry_list_text.split("\n")

            return_string = '<span class="glyphicon glyphicon-folder-open"></span> '

            return_string << self.bytestream_name

            entry_list_array.each_with_index do |raw_entry, index|


              if index > 2  && index < (entry_list_array.length - 1) # first three lines are headers, last line is summary

                entry_array = raw_entry.strip.split " "

                filepath = entry_array[-1]
                entry_length = entry_array[0].to_i

                if filepath && entry_length > 0

                  if filepath.exclude?('__MACOSX/')
                    name_arr = filepath.split("/")

                    Rails.logger.warn name_arr.last

                    name_arr.length.times do
                      return_string << "<div class='indent'>"
                    end

                    if filepath[-1] == "/" # means directory
                      return_string << '<span class="glyphicon glyphicon-folder-open"></span> '

                    else
                      return_string << '<span class="glyphicon glyphicon-file"></span> '
                    end

                    return_string << name_arr.last
                    name_arr.length.times do
                      return_string << "</div>"
                    end
                  end

                end


              end


            end

            return return_string

          when '7z'

            entry_list_text = `7za l "#{self.bytestream_path}"`

            Rails.logger.warn entry_list_text

            entry_list_array = entry_list_text.split("\n")

            return_string = '<span class="glyphicon glyphicon-folder-open"></span> '

            return_string << self.bytestream_name

            entry_list_array.each_with_index do |raw_entry, index|


              if index > 19  && index < (entry_list_array.length - 2) # first three lines are headers, last two lines are summary

                entry_array = raw_entry.strip.split " "

                filepath = entry_array[-1]

                if filepath

                  name_arr = filepath.split("/")

                  Rails.logger.warn name_arr.last

                  name_arr.length.times do
                    return_string << "<div class='indent'>"
                  end

                  if filepath[-1] == "/" # means directory
                    return_string << '<span class="glyphicon glyphicon-folder-open"></span> '

                  else
                    return_string << '<span class="glyphicon glyphicon-file"></span> '
                  end

                  return_string << name_arr.last
                  name_arr.length.times do
                    return_string << "</div>"
                  end


                end


              end


            end

            return return_string

          else
            return "no preview available"

        end

      else
        return "no preview available"
      end

    else
      return "no preview available"
    end
  end


  def has_preview?
    if self.bytestream_name == ""
      return false
    else
      filename_split = self.bytestream_name.split(".")
      extension = filename_split.last
      if ['txt', 'csv', 'tsv', 'rb', 'xml', 'json', 'zip', '7z'].include?(extension)
        return true
      else
        return false
      end
    end

  end

  def is_image?
    if self.bytestream_name == ""
      return false
    else
      filename_split = self.bytestream_name.split(".")
      extension = filename_split.last
      if ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'jpg2', 'tif', 'tiff'].include?(extension)
        return true
      else
        return false
      end
    end
  end

  def is_microsoft?
    if self.bytestream_name == ""
      return false
    else
      filename_split = self.bytestream_name.split(".")
      extension = filename_split.last
      return ['doc', 'docx', 'xls', 'xslx', '.ppt', 'pptx' ].include?(extension)
    end
  end

  def microsoft_preview_url
    if self.is_microsoft?

      dataset = Dataset.find(self.dataset_id)

      return "https://view.officeapps.live.com/op/view.aspx?src=https%3A%2F%2Fdatabank.illinois.edu%2Fdatasets%2FIDB-0341890%2F#{dataset.key}%2Fdatafiles%2#{self.web_id}%2Fdisplay"

    else
      raise "Microsoft preview url requested for non-Microsoft file."

    end
  end

  def mime_type
    if self.bytestream_name == ""
      return nil
    else
      filename_split = self.bytestream_name.split(".")
      extension = filename_split.last
      case extension
        when 'png'
          return 'image/png'
        when 'jpg', 'jpeg', 'jpg2'
          return 'image/jpeg'
        when 'bmp'
          return 'image/bmp'
        when 'gif'
          return 'image/gif'
        when 'pdf'
          return 'application/pdf'
        else
          return 'application/octet-stream'
      end
    end
  end

  def ip_downloaded_file_today(request_ip)
    DayFileDownload.where(["ip_address = ? and file_web_id = ? and download_date = ?", request_ip, self.web_id, Date.current]).count > 0
  end

  def record_download(request_ip)

    if Robot.exists?(address: request_ip)
      return nil
    end

    dataset = Dataset.find(self.dataset_id)

    if dataset && dataset.identifier && dataset.identifier != "" # ignore draft datasets

      unless dataset.ip_downloaded_dataset_today(request_ip)

        today_dataset_download_relation = DatasetDownloadTally.where(["dataset_key= ? and download_date = ?", dataset.key, Date.current])

        if today_dataset_download_relation.count == 1

          today_dataset_download = today_dataset_download_relation.first
          today_dataset_download.tally = today_dataset_download.tally + 1
          today_dataset_download.save
        elsif today_dataset_download_relation.count == 0
          DatasetDownloadTally.create(tally: 1, download_date: Date.current, dataset_key: dataset.key, doi: dataset.identifier)
        else
          Rails.logger.warn "unexpected number of dataset tally records for download of #{self.web_id} on #{Date.current} from #{request_ip}"
        end

      end

      unless ip_downloaded_file_today(request_ip)


          DayFileDownload.create(ip_address: request_ip,
                                 download_date: Date.current,
                                 file_web_id: self.web_id,
                                 filename: self.bytestream_name,
                                 dataset_key: dataset.key,
                                 doi: dataset.identifier)

          today_datatafile_download_relation = FileDownloadTally.where(["file_web_id = ? and download_date = ?", self.web_id, Date.current])

          if today_datatafile_download_relation.count == 1
            today_file_download = today_datatafile_download_relation.first
            today_file_download.tally = today_file_download.tally + 1
            today_file_download.save
          elsif today_datatafile_download_relation.count == 0
            FileDownloadTally.create(tally: 1, download_date: Date.current, dataset_key: dataset.key, doi: dataset.identifier, file_web_id: self.web_id, filename: self.bytestream_name)
          else
            Rails.logger.warn "unexpected number of file tally records for download of #{self.web_id} on #{Date.current} from #{request_ip}"
          end

      end

    end

  end

  def remove_directory
    dir = "#{IDB_CONFIG[:datafile_store_dir]}/#{self.web_id}"
    if Dir.exists? dir
      FileUtils.rm_rf(dir)
    end
  end

  def job
    if self.job_id
      Delayed::Job.where(id: self.job_id).first
    end
  end

  def job_status
    if self.job
      if job.locked_by
        return :processing
      else
        return :pending
      end
    else
      return :complete
    end
  end

  def destroy_job
    if self.job
      self.job.destroy
    end
  end

  ##
  # Generates a guaranteed-unique web ID, of which there are
  # 36^WEB_ID_LENGTH available.
  #
  def generate_web_id
    proposed_id = nil
    while true
      proposed_id = (36 ** (WEB_ID_LENGTH - 1) +
          rand(36 ** WEB_ID_LENGTH - 36 ** (WEB_ID_LENGTH - 1))).to_s(36)
      break unless Datafile.find_by_web_id(proposed_id) || Recordfile.find_by_web_id(proposed_id)
    end
    proposed_id
  end

  # def chmod_binary_for_medusa
  #   if self.binary && self.binary.file
  #     FileUtils.chmod "u=wrx,go=rx", File.dirname(self.binary.path)
  #     FileUtils.chmod "u=wrx,go=rx", self.binary.path
  #
  #   end
  # end

end
