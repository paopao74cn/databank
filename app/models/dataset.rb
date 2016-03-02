require 'fileutils'

class Dataset < ActiveRecord::Base

  MIN_FILES = 1
  MAX_FILES = 10000

  validate :published_datasets_must_remain_complete

  has_many :datafiles, dependent: :destroy
  has_many :creators, dependent: :destroy
  has_many :funders, dependent: :destroy
  has_many :related_materials, dependent: :destroy
  accepts_nested_attributes_for :datafiles, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :creators, reject_if: proc { |attributes| (attributes['family_name'].blank? && attributes['institution_name'].blank?) }, allow_destroy: true
  accepts_nested_attributes_for :funders, reject_if: proc { |attributes| (attributes['name'].blank?) }, allow_destroy: true
  accepts_nested_attributes_for :related_materials, reject_if: proc { |attributes| ((attributes['link'].blank? ) && (attributes['citation'].blank? )) }, allow_destroy: true

  before_create 'set_key'
  before_save 'set_primary_contact'
  after_save 'remove_invalid_datafiles'
  after_update 'set_datacite_change'

  def to_param
    self.key
  end

  def self.search(search)
    if search

      #start with an empty relation
      search_result = Array.new

      search_terms = search.split(" ")

      search_terms.each do |term|

        #Rails.logger.warn "term class is: #{term.class}"

        clean_term = term.strip.downcase

        if !clean_term.empty?

          #TODO search creators
          term_relations = Dataset.where('lower(title) LIKE :search OR lower(keywords) LIKE :search OR lower(creator_text) LIKE :search OR lower(identifier) LIKE :search OR lower(description) LIKE :search', search: "%#{clean_term}%")

          term_relations.each do |tr|

            search_result << tr

          end # end of term_realtions each do

        end # end of if clean term is not empty
      end # end of search term each do

      Dataset.where(id: search_result.map(&:id))
    else # else of if search
      Dataset.all
    end # end if search
  end

  def to_datacite_xml

    if !self.title || self.creator_list == ""
      raise 'Dataset is not complete; a valid datacite xml document cannot be generated.'
    end

    # creatorArr = self.creator_list.split(";")

    if self.keywords
      keywordArr = self.keywords.split(";")
    end

    contact = Creator.where(dataset_id: self.id, is_contact: true).first
    raise ActiveRecord::RecordNotFound unless contact

    doc = Nokogiri::XML::Document.parse(%Q(<?xml version="1.0"?><resource xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://datacite.org/schema/kernel-3" xsi:schemaLocation="http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd"></resource>))
    resourceNode = doc.first_element_child

    identifierNode = doc.create_element('identifier')
    identifierNode['identifierType'] = "DOI"
    # for imports and post-v1 versions, use specified identifier, otherwise assert v1
    if self.identifier && self.identifier != ''
      identifierNode.content = self.identifier
    else
      identifierNode.content = "#{IDB_CONFIG[:ezid_placeholder_identifier]}#{self.key}_v1"
    end
    identifierNode.parent = resourceNode

    creatorsNode = doc.create_element('creators')
    creatorsNode.parent = resourceNode

    self.creators.each do |creator|
      creatorNode = doc.create_element('creator')
      creatorNode.parent = creatorsNode

      creatorNameNode = doc.create_element('creatorName')

      creatorNameNode.content = "#{creator.family_name.strip}, #{creator.given_name.strip}"
      creatorNameNode.parent = creatorNode

      # ORCID assumption hard-coded here, but in the model there is a field for identifier_scheme
      if creator.identifier && creator.identifier != ""
        creatorIdentifierNode = doc.create_element('nameIdentifier')
        creatorIdentifierNode['schemeURI'] = "http://orcid.org/"
        creatorIdentifierNode['nameIdentifierScheme'] = "ORCID"
        creatorIdentifierNode.content = "#{creator.identifier}"
        creatorIdentifierNode.parent = creatorNode
      end

    end

    titlesNode = doc.create_element('titles')
    titlesNode.parent = resourceNode

    titleNode = doc.create_element('title')
    titleNode.content = self.title || "Dataset Title"
    titleNode.parent = titlesNode

    contributorsNode = doc.create_element('contributors')
    contributorsNode.parent = resourceNode

    contactNode = doc.create_element('contributor')
    contactNode['contributorType'] = "ContactPerson"
    contactNode.parent = contributorsNode

    if contact.family_name && contact.given_name
      contactNameNode = doc.create_element('contributorName')
      contactNameNode.content = "#{contact.family_name}, #{contact.given_name}"
      contactNameNode.parent = contactNode

      if contact.identifier && contact.identifier != ""
        contactIdentifierNode = doc.create_element('nameIdentifier')
        contactIdentifierNode["schemeURI"] = "http://orcid.org/"
        contactIdentifierNode["nameIdentifierScheme"] = "ORCID"
        contactIdentifierNode.content = "#{contact.identifier}"
        contactIdentifierNode.parent = contactNode
      end
    end

    self.funders.each do |funder|
      if (funder.name && funder.name != '') || (funder.identifier && funder.identifer != '')

        funderNode = doc.create_element('contributor')
        funderNode['contributorType'] = "Funder"
        funderNode.parent = contributorsNode

        funderNameNode = doc.create_element('contributorName')
        funderNameNode.content = funder.name ||= '[Name not provided]'
        funderNameNode.parent = funderNode

        if funder.identifier && funder.identifier != ''
          funderIdentifierNode = doc.create_element('nameIdentifier')
          funderIdentifierNode["schemeURI"] = "http://dx.doi.org/"
          funderIdentifierNode["nameIdentifierScheme"] = "DOI"
          funderIdentifierNode.content = "#{funder.identifier}"
          funderIdentifierNode.parent = funderNode
        end
      end
    end


    publisherNode = doc.create_element('publisher')
    publisherNode.content = self.publisher || "University of Illinois at Urbana-Champaign"
    publisherNode.parent = resourceNode

    publicationYearNode = doc.create_element('publicationYear')
    publicationYearNode.content = self.publication_year || Time.now.year
    publicationYearNode.parent = resourceNode

    if self.keywords

      subjectsNode = doc.create_element('subjects')
      subjectsNode.parent = resourceNode

      keywordArr.each do |keyword|
        subjectNode = doc.create_element('subject')
        subjectNode.content = keyword.strip
        subjectNode.parent = subjectsNode
      end

    end

    datesNode = doc.create_element('dates')
    datesNode.parent = resourceNode

    releasedateNode = doc.create_element('date')
    releasedateNode["dateType"] = "Available"
    if self.tombstone_date && self.tombstone_date != ""
      releasedateNode.content =  "#{self.release_date.iso8601}/#{self.tombstone_date.iso8601} "
    else
      releasedateNode.content = self.release_date.iso8601 || Date.current().iso8601
    end
    releasedateNode.content = self.release_date.iso8601 || Date.current().iso8601
    releasedateNode.parent = datesNode

    # languageNode = doc.create_element('language')
    # languageNode.content = "en-us"
    # languageNode.parent = resourceNode

    if self.license && !self.license.blank?
      rightsListNode = doc.create_element('rightsList')
      rightsListNode.parent = resourceNode

      rightsNode = doc.create_element('rights')
      rightsNode.content = self.license
      rightsNode.parent = rightsListNode
    end

    if self.description && !self.description.blank?
      descriptionsNode = doc.create_element('descriptions')
      descriptionsNode.parent = resourceNode
      descriptionNode = doc.create_element('description')
      descriptionNode['descriptionType'] = "Abstract"
      descriptionNode.content = self.description
      descriptionNode.parent = descriptionsNode
    end

    resourceTypeNode = doc.create_element('resourceType')
    resourceTypeNode['resourceTypeGeneral'] = "Dataset"
    resourceTypeNode.content = "Dataset"
    resourceTypeNode.parent = resourceNode


    if self.related_materials.count > 0

      ready_count = 0

      relatedIdentifiersNode = doc.create_element('relatedIdentifiers')
      relatedIdentifiersNode.parent = resourceNode

      self.related_materials.each do |material|

        if material.url && material.url != ''
          ready_count = ready_count + 1
          datacite_arr = Array.new

          if material.datacite_list && material.datacite_list != ''
            datacite_arr = material.datacite_list.split(',')
          else
            datacite_arr << 'IsSupplementTo'
          end

          datacite_arr.each do |relationship|
            relatedMaterialNode = doc.create_element('relatedIdentifier')
            relatedMaterialNode['relatedIdentifierType'] = material.url_type || 'URL'
            relatedMaterialNode['relationType'] = relationship
            relatedMaterialNode.content = material.url
          end

        end
      end

      if ready_count == 0
        relatedIdentifiersNode.remove
      end

    end


    doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)


  end

  def placeholder_metadata
    doc = Nokogiri::XML::Document.parse(%Q(<?xml version="1.0"?><resource xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://datacite.org/schema/kernel-3" xsi:schemaLocation="http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd"></resource>))
    resourceNode = doc.first_element_child

    identifierNode = doc.create_element('identifier')
    identifierNode['identifierType'] = "DOI"
    # for imports and post-v1 versions, use specified identifier, otherwise assert v1
    if self.identifier && self.identifier != ''
      identifierNode.content = self.identifier
    else
      identifierNode.content = "#{IDB_CONFIG[:ezid_placeholder_identifier]}#{self.key}_v1"
    end
    identifierNode.parent = resourceNode

    creatorsNode = doc.create_element('creators')
    creatorsNode.parent = resourceNode

    creatorNode = doc.create_element('creator')
    creatorNode.parent = creatorsNode

    creatorNameNode = doc.create_element('creatorName')

    creatorNameNode.content = "University of Illinois at Urbana-Champaign"
    creatorNameNode.parent = creatorNode


    titlesNode = doc.create_element('titles')
    titlesNode.parent = resourceNode

    titleNode = doc.create_element('title')
    titleNode.content = "Removed Dataset"
    titleNode.parent = titlesNode

    publisherNode = doc.create_element('publisher')
    publisherNode.content = self.publisher || "University of Illinois at Urbana-Champaign"
    publisherNode.parent = resourceNode

    publicationYearNode = doc.create_element('publicationYear')
    publicationYearNode.content = self.publication_year || Time.now.year
    publicationYearNode.parent = resourceNode

    descriptionsNode = doc.create_element('descriptions')
    descriptionsNode.parent = resourceNode
    descriptionNode = doc.create_element('description')
    descriptionNode['descriptionType'] = "Other"
    descriptionNode.content = "Dataset has been removed. Contact the Research Data Service of the University of Illinois at Urbana-Champaign with any questions. http://researchdataservice.illinois.edu"
    descriptionNode.parent = descriptionsNode

    doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)
  end


  def set_datacite_change
    if is_datacite_changed?
      update_column("has_datacite_change", "true")
    end
  end

  def is_datacite_changed?

    self.related_materials.each do |material|
      if material.uri && material.uri != '' && material.changed?
        return true
      end
    end

    self.creators.each do |creator|
      if creator.changed?
        return true
      end
    end

    self.funders.each do |funder|
      if funder.name_changed? || funder.identifier_changed?
        return true
      end
    end

    if self.title_changed? || self.license_changed? || self.description_changed? || self.version_changed? || self.keywords_changed? || self.identifier_changed? || self.publication_year_changed? || self.release_date_changed? || self.embargo_changed?
      return true
    end

    if self.release_date_changed?
      return true
    end

    # if we get here, no DataCite-relevant changes have been detected
    return false

  end

  def visibility
    case self.publication_state
      when Databank::PublicationState::DRAFT
        return_string = "Private (Saved Draft)"
      when Databank::PublicationState::RELEASED
        return_string = "Public (Published)"
      when Databank::PublicationState::FILE_EMBARGO
        return_string = "Public description, Private files (Standard Embargo)"
      when Databank::PublicationState::METADATA_EMBARGO
        return_string = "Private (DOI Reserved Only)"
      when Databank::PublicationState::TOMBSTONE
        return_string = "Public Metadata, Private Files (Tombstoned)"
      when Databank::PublicationState::DESTROYED
        return_string = "Removed Metadata, Removed Files (Destroyed)"
      else
        #should never get here
        return_string = "Unknown, please contact the Research Data Service"
    end

    if self.new_record?
      return_string = "Private (Not Yet Saved)"
    end

    if self.curator_hold
      return_string = "Private (Curator Hold)"
    end

    return_string
  end

  def creator_list
    return_list = ""

    self.creators.each_with_index do |creator, i|

      return_list << "; " unless i == 0

      case creator.type_of
        when Creator::PERSON
          return_list << creator.family_name
          return_list << ", "
          return_list << creator.given_name
        when Creator::INSTITUTION
          return_list << creator.institution_name
      end

    end
    return_list

  end

  def plain_text_citation

    if self.creator_list == ""
      creator_list = "[Creator List]"
    else
      creator_list = self.creator_list
    end

    if title && title != ""
      citationTitle = title
    else
      citationTitle = "[Title]"

    end

    citation_id = (identifier && !identifier.empty?) ? "http://dx.doi.org/#{identifier}" : ""

    return "#{creator_list} (#{publication_year}): #{citationTitle}. #{publisher}. #{citation_id}"
  end

  def set_key
    self.key ||= generate_key
  end

  ##
  # Generates a guaranteed-unique key, of which there are
  # 36^KEY_LENGTH available.
  #
  def generate_key
    proposed_key = nil

    while true

      num_part = rand(10 ** 7).to_s.rjust(7, '0')
      proposed_key = "#{IDB_CONFIG[:key_prefix]}-#{num_part}"
      break unless self.class.find_by_key(proposed_key)
    end
    proposed_key
  end

  def set_primary_contact

    self.corresponding_creator_name = nil
    self.corresponding_creator_email = nil

    self.creators.each do |creator|
      if creator.is_contact?
        self.corresponding_creator_name = "#{creator.given_name} #{creator.family_name}"
        self.corresponding_creator_email = creator.email
      end
    end
  end

  def remove_invalid_datafiles
    self.datafiles.each do |datafile|
      if (!datafile.medusa_path || datafile.medusa_path == "") && (!datafile.binary.path || datafile.binary.path == "")
        datafile.destroy
      end
    end
  end

  def published_datasets_must_remain_complete
    if publication_state != Databank::PublicationState::DRAFT
      if !title || title == ''
        errors.add(:title, "must be present in a published dataset")
      end
      #TODO for completeness, add attributes not editable by depostors in interface
    end
  end


end
