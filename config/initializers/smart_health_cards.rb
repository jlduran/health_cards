# frozen_string_literal: true

require 'health_cards'

Rails.application.configure do
  config.smart = config_for('well-known')
  config.metadata = config_for('metadata')
  config.operation = config_for('operation')

  config.hc_key_path = ENV.fetch('KEY_PATH', nil)
  FileUtils.mkdir_p(File.dirname(ENV.fetch('KEY_PATH', nil)))
  kp = HealthCards::PrivateKey.load_from_or_create_from_file(config.hc_key_path)

  config.hc_key = kp
  config.issuer = HealthCards::Issuer.new(url: ENV.fetch('HOST', nil), key: config.hc_key)

  config.auth_code = ENV.fetch('AUTH_CODE', nil)
  config.client_id = ENV.fetch('CLIENT_ID', nil)
end
