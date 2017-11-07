Rails.application.config.after_initialize do

  StampClient::Base.site = Rails.application.config.stamp_url

  StampClient::Base.connection do |connection|
    ENV['HTTP_PROXY'] = nil
    ENV['http_proxy'] = nil
    ENV['https_proxy'] = nil

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
