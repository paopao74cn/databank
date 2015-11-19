Rails.application.routes.draw do

  resources :licenses
  resources :datafiles
  resources :users
  resources :identities
  resources :datasets

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'welcome#index'

  get '/faqs', to: 'welcome#faqs', :as => :faq
  get '/policies', to: 'welcome#policies', :as => :policies
  get '/help', to: 'welcome#help', :as => :help
  get '/welcome/deposit_login_modal', to: 'welcome#deposit_login_modal'
  get '/contact', to: 'welcome#contact', :as => :contact
  get '/datasets/:id/download_endNote_XML', to: 'datasets#download_endNote_XML'
  get '/datasets/:id/download_BibTeX', to: 'datasets#download_BibTeX'
  get '/datasets/:id/download_RIS', to: 'datasets#download_RIS'
  get '/datasets/:id/download_plaintext_citation', to: 'datasets#download_plaintext_citation'

  get '/datasets/:id/destroy_file/:web_id', to: 'datasets#destroy_file'

  get '/datasets/:id/download_box_file/:box_file_id', to: 'datasets#download_box_file'

  # datafiles
  # get '/datafiles', to: 'datafiles#index'
  # get '/datasets/:dataset_key/datafiles', to: 'datafiles#index'
  #
  # get '/datasets/:dataset_key/datafiles/new', to: 'datafiles#new'
  # post '/datasets/:dataset_key/datafiles/new', to: 'datafiles#create'
  #
  # post '/datasets/:dataset_key/datafiles', to: 'datafiles#create'
  #
  # get '/datafiles/:web_id', to: 'datafiles#show'
  #
  # patch '/datafiles/:web_id', to: 'datafiles#update'
  # put '/datafiles/:web_id', to: 'datafiles#update'
  #
  # get '/datafiles/:web_id/edit', to: 'datafiles#edit'
  # get '/datafiles/:web_id/edit', to: 'datafiles#edit'
  #
  # delete '/datafiles/:web_id', to: 'datafiles#destroy'

  # deposit
  get '/datasets/:id/deposit', to: 'datasets#deposit'

  # review agreement
  get '/review_deposit_agreement', to: 'datasets#review_deposit_agreement'
  get '/datasets/:id/review_deposit_agreement', to: 'datasets#review_deposit_agreement'


  # authentication routes
  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  match '/login', to: 'sessions#new', as: :login, via: [:get, :post]
  match '/logout', to: 'sessions#destroy', as: :logout, via: [:get, :post]

  match '/auth/failure', to: 'sessions#unauthorized', as: :unauthorized, via: [:get, :post]

  # route binary downloads
  get "/datafiles/:id/download", :controller => "datafiles", :action => "download"

  # create from box file select widget
  post "/datafiles/create_from_box", to: 'datafiles#create_from_box'


end