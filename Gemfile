source "http://rubygems.org"

gem 'rails', '~> 3.2.13'
gem "haml"
gem "mysql2"
gem "bcrypt-ruby", :require => "bcrypt"
gem 'will_paginate', '~> 3.0'
gem 'whenever', :require => false
gem 'jquery-rails'
gem 'nokogiri'
gem 'simple_form'

gem 'geocoder'
gem 'gmaps4rails'
gem 'underscore-rails'          # for gmaps4rails
gem 'markerclustererplus-rails' # for gmaps4rails

gem 'mailman'

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
  gem 'capistrano', '~> 3.0', require: false
  # https://github.com/capistrano/rails/issues/48#issuecomment-31443739
  gem 'capistrano-rvm', github: 'capistrano/rvm', require: false
  gem 'capistrano-bundler', '>= 1.1.0', require: false
  gem 'capistrano-rails', require: false
end
