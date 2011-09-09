require File.dirname(__FILE__) + '/../test_helper'

class SoundcloudClientTest < ActiveSupport::TestCase
  CREDITS_FILE = File.dirname(__FILE__) + '/soundcloud_credits.yml'

  #
  # we need to persist the credits to use the refresh tokens
  #
  def setup
    @config = load_config
  end

  def teardown
    save_config(@config)
  end

  def test_connecting
    client = SoundcloudClient.new
    client.remote(@config['soundcloud'])
    assert client.connected?
  ensure
    save_config(@config)
  end

  protected

  def load_config
    YAML::load File.open(CREDITS_FILE)
  end

  def save_config(config)
    return unless config['soundcloud'].try[:refresh_token]
    File.open CREDITS_FILE, 'w' do |f|
      f.write config.to_yaml
    end
  end

end
