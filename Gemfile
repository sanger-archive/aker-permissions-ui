# frozen_string_literal: true

source 'https://rubygems.org'

# Force git gems to use secure HTTPS
git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# All the gems not in a group will always be installed:
#   http://bundler.io/v1.6/groups.html#grouping-your-dependencies
gem 'bootstrap-sass', '~> 3.3.6'
gem 'bootstrap_form'
gem 'coffee-rails', '~> 4.2'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails'
gem 'lograge'
gem 'logstash-event'
gem 'logstash-logger'
gem 'pg', '~> 0.18' # pg version 1.0.0 is not compatible with Rails 5.1.4
gem 'pry'
gem 'puma', '~> 3.7'
gem 'rails', '~> 5.1.2'
gem 'request_store'
gem 'sass-rails', '~> 5.0'
gem 'therubyracer', platforms: :ruby
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'
gem 'zipkin-tracer'
gem 'health_check'

###
# Sanger gems
###
gem 'aker_credentials_gem', github: 'sanger/aker-credentials'
gem 'aker_shared_navbar', github: 'sanger/aker-shared-navbar'
gem 'aker_stamp_client', github: 'sanger/aker-stamp-client'
gem 'json_api_client', github: 'sanger/json_api_client'

###
# Groups
###
group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'rspec-rails'
  gem 'simplecov', require: false
  gem 'simplecov-rcov'
  gem 'timecop'
  gem 'webmock'
end

group :development, :test do
  gem 'brakeman', require: false
  gem 'byebug', platforms: :mri
  gem 'capybara', '~> 2.13'
  gem 'factory_bot_rails'
  gem 'launchy'
  gem 'poltergeist'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'
end
