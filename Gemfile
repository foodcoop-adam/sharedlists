source "http://rubygems.org"

gem 'rails', '~> 3.2.13'
gem "haml"
gem "mysql2", '~> 0.3.1' # compatible with rails 3
gem "bcrypt-ruby", :require => "bcrypt"
gem 'will_paginate', '~> 3.0'
gem 'whenever', :require => false
gem 'jquery-rails'
gem 'nokogiri'
gem 'simple_form'

gem 'countries', require: 'countries/global'
gem 'geocoder'
gem 'gmaps4rails'
gem 'underscore-rails'          # for gmaps4rails
gem 'markerclustererplus-rails' # for gmaps4rails

gem 'daemons', require: false
gem 'mailman', require: false
gem 'uchardet'

# Needed for the new asset pipeline
group :assets do
  gem 'sass-rails',   "~> 3.2.3"
  gem 'coffee-rails', "~> 3.2.1"
  gem 'uglifier',     ">= 1.0.3"
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', platforms: :ruby
end

group :development do
  # Deploy with Capistrano
  gem 'capistrano', '~> 3.4.0', require: false
  gem 'capistrano-rvm', require: false
  gem 'capistrano-bundler', '>= 1.1.0', require: false
  gem 'capistrano-rails', require: false
end
