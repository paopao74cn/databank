module Effective
  module Datatables
    class DepositorDatasets < Effective::Datatable

      datatable do
        default_order :updated_at, :desc
        current_email = attributes[:current_email]
        current_name = attributes[:current_name]
        array_column 'Depositors', sortable: false, visible: false, filter: {type: :select, values: ['me', 'other']} do |dataset|
          if dataset.depositor_email == current_email
            render text: 'me'
          else
            render text: 'other'
          end
        end

        array_column :citation, label: 'Indexable', sortable: false, filter: {fuzzy: true} do |dataset|
          table_description = nil
          if dataset.description && !dataset.description.empty?
            table_description = dataset.description.first(230)
            if dataset.description.length > 230
              table_description = table_description + "[...]"
            end
          end

          table_keywords = nil
          if dataset.keywords && dataset.keywords != ""
            table_keywords = dataset.keywords
          end

          if table_description && table_keywords
            render inline: %Q[<%= link_to(%Q[#{dataset.plain_text_citation}], "#{request.base_url}#{dataset_path(dataset.key)}") %><br/>#{h(table_description)}<br/>Keywords: #{table_keywords} ]
          elsif table_description
            render inline: %Q[<%= link_to(%Q[#{dataset.plain_text_citation}], "#{request.base_url}#{dataset_path(dataset.key)}") %><br/>#{h(table_description)}]
          elsif table_keywords
            render inline: %Q[<%= link_to(%Q[#{dataset.plain_text_citation}], "#{request.base_url}#{dataset_path(dataset.key)}") %><br/>Keywords: #{table_keywords} ]
          else
            render inline: %Q[<%= link_to(%Q[#{dataset.plain_text_citation}], "#{request.base_url}#{dataset_path(dataset.key)}") %>]
          end
        end
        array_column 'Status', visible: false, filter: {type: :select, values: ['Draft', 'Metadata and Files Publication Delayed (Embargoed)', 'Metadata Published, Files Publication Delayed (Embargoed)', 'Metadata and Files Published', 'Metadata Published, Files Temporarily Suppressed', 'Metadata and Files Temporarily Suppressed', 'Metadata Published, Files Withdrawn']} do |dataset|

          render text: "#{dataset.visibility}"
        end
        table_column :depositor_email, visible: false
        table_column :updated_at, visible: false
        table_column :created_at, visible: false
      end

      def collection
        current_email = attributes[:current_email]
        Dataset.where(is_test: false).where.not(publication_state: Databank::PublicationState::PermSuppress::METADATA).where("publication_state = ? OR publication_state = ? OR publication_state = ? OR publication_state = ? OR depositor_email = ?", Databank::PublicationState::RELEASED, Databank::PublicationState::TempSuppress::FILE, Databank::PublicationState::Embargo::FILE, Databank::PublicationState::PermSuppress::FILE, current_email)
      end

    end
  end
end
