require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AkerStampsUi
  class Application < Rails::Application
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
    end
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    if Rails.env.production? || Rails.env.staging?
      config.urls = { submission: "https://dev.psd.sanger.ac.uk:9002/submission",
                      permissions: "https://dev.psd.sanger.ac.uk:9009/stamps-ui",
                      sets: "https://dev.psd.sanger.ac.uk:9001/set-shaper",
                      projects: "https://dev.psd.sanger.ac.uk:9003/study",
                      work_orders: "https://dev.psd.sanger.ac.uk:9004/work-orders" }
    elsif Rails.env.development? || Rails.env.test?
      config.urls = { submission: "",
                      permissions: "",
                      sets: "",
                      projects: "",
                      work_orders: "" }
    end


    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
