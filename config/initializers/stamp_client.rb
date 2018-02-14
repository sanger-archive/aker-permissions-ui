# frozen_string_literal: true

Rails.application.config.after_initialize do
  StampClient::Base.site = Rails.application.config.stamp_url

  StampClient::Base.connection do |connection|
    ENV['HTTP_PROXY'] = nil
    ENV['http_proxy'] = nil
    ENV['https_proxy'] = nil

    # Avoid checking SSL certs when going to the stamp service.
    # https://github.com/lostisland/faraday/wiki/Setting-up-SSL-certificates
    # TODO: This should be fixed in the future by adding the stamp service certificate to the stamp
    # UI app or signing the stamp certificate with from the stamp UI app
    connection.faraday.ssl.verify = false

    connection.faraday.proxy ''
    # Remove deprecation warning by sending empty hash
    # http://www.rubydoc.info/github/lostisland/faraday/Faraday/Connection
    # pj5: This does not seem to be working on staging and I'm not sure why. I'm leaving this for
    #   the time being.
    # connection.faraday.proxy {}

    connection.use JWTSerializer
    if Rails.env.production? || Rails.env.staging?
      connection.use ZipkinTracer::FaradayHandler, 'Stamp service'
    end
  end
end
