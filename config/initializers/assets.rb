# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.1'

# Add additional assets to the asset load path
Rails.application.config.assets.paths << Rails.root.join("vendor", "assets", "stylesheet")

# Precompile additional assets.
# application.js, application.scss, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
#Rails.application.config.assets.precompile +=  ['datasets.js', 'creators.js' 'jansy-bootstrap.js', 'datasets.scss', 'scaffolds.scss', 'jansy-bootstrap.css', 'bootstrap-glyphicons.css']