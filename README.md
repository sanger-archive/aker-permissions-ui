# Aker - Material Permissions Manager

[![Build Status](https://travis-ci.org/sanger/aker-permissions-ui.svg?branch=devel)](https://travis-ci.org/sanger/aker-permissions-ui)
[![Maintainability](https://api.codeclimate.com/v1/badges/7e068987370a63dddd10/maintainability)](https://codeclimate.com/github/sanger/aker-permissions-ui/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/7e068987370a63dddd10/test_coverage)](https://codeclimate.com/github/sanger/aker-permissions-ui/test_coverage)

An application to manage the permissions or "stamps" applied to materials as well as deputies assigned to users.

# Installation
## Dev environment
1. Configure or update the ports to services in `development.rb`.
2. Setup the database using `rake db:setup`. Alternatively, use:
  * `rake db:drop db:create db:migrate`
  * Seed the database with `rade db:seed` (first verify that your username has been added to the seed)

# Testing
## Running tests
To execute the tests, run: `bundle exec rspec` or simply `rspec`
