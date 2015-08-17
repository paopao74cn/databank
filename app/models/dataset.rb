class Dataset < ActiveRecord::Base
  has_many :creators, dependent: :destroy

  after_save 'save_to_repo'
  before_destroy 'delete_repository_entity'
  after_initialize 'set_key'

  def creator_list
    creator_list = ""

    if creator_ordered_ids && !creator_ordered_ids.empty? && creator_ordered_ids.respond_to?(:split)
      creator_array = creator_ordered_ids.split(",")
      creator_array.each_with_index do |creatorID, index|
        if index > 0
          creator_list << "; "
        end
        creator = Creator.find(creatorID)
        creator_list << creator.creator_name.strip
      end
    end

    return creator_list
  end

  def plain_text_citation

    citation_id = (identifier && !identifier.empty?) ? "http://dx.doi.org/#{identifier}" : ""

    return "#{creator_list} (#{publication_year}): #{title}. #{publisher}. #{citation_id}"
  end

  def save_to_repo
    self.key = self.key || self.id
    collection = Repository::Collection.find_by_key(self.key)
    if collection.nil?
      collection = Repository::Collection.new :parent_url => Databank::Application.databank_config[:fedora_url]
    end
    collection.key = self.key
    collection.published = true
    collection.title = self.title
    collection.creator_list = self.creator_list
    collection.description = self.description
    collection.identifier = self.identifier
    collection.license = self.license
    collection.publication_year = self.publication_year
    collection.publisher = self.publisher
    collection.save!

  end

  def delete_repository_entity
    self.key = self.key || self.id
    collection = Repository::Collection.find_by_key(self.key)
    if !collection.nil?
      collection.destroy
    end
  end

  def set_key
    unless self.key && !self.key.empty?
      self.key = self.id
      self.save!
    end
  end

end
