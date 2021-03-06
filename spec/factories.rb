FactoryGirl.define do
  factory :featured_researcher do
    name "MyString"
    title "MyString"
    bio "MyText"
    testimonial "MyText"
    binary "MyString"
  end
  factory :restoration_id_map do
    id_class "dataset"
    old_id 1
    new_id 1
    restoration_event_id 1
  end

  factory :restoration_event do
    note "bad thing happened"
  end
  
  factory :user do
    provider "identity"
    uid "mfall3@mailinator.com"
    name "Test Curator"
    email "mfall3@mailinator.com"
    role "curator"
    username "test_curator"
  end

  factory :dataset do

    title "Test Dataset"
    publisher "University of Illinois at Urbana-Champaign"
    license "CC01"
    depositor_name "Colleen Fallaw"
    depositor_email "mfall3@mailinator.com"
    corresponding_creator_name "Colleen Fallaw"
    corresponding_creator_email "mfall3@mailinator.com"
    curator_hold false
    embargo "none"
    is_test false
    is_import false
    have_permission "yes"
    removed_private "na"
    agree "yes"
    hold_state "none"
    dataset_version "1"
    suppress_changelog false

  end

  factory :creator do
    family_name "Last"
    given_name "First"
    type_of 0
    email "creator@mailinator.com"
    is_contact true
    row_position 1
    identifier_scheme "ORCID"
  end

  factory :funder do
    name "DOE"
    identifier "10.13039/100000015"
    identifier_scheme "DOI"
    grant "RFA-Unicorns"
  end

end