# # FlickrAuth

require 'flickraw'
require 'yaml'

# Encapsulates connecting to flickr, pulling auth information from a yaml file.
# A FlickrAuth object should behave the same way (more or less) as an auth
# object returned by FlickRaw.
class FlickrAuth
  attr_reader :auth

  def initialize(file, perms='read')
    @auth = authorize(file, perms)
  end

  def user; @auth.user end
  def token; @auth.token end
  def perms; @auth.perms end

  # Read API key from a yaml file. The file (parameter) should contain
  # the key and secret fields from your API key page. We will also
  # save the auth token Flickr sends us in this file once we have
  # authenticated. To start, create a file with the following:
  #
  #     :key: API_KEY
  #     :secret: SHARED_SECRET
  #
  # @auth will be nill if authentication fails.
  def authorize(file, perms)
    auth_file = File.dirname(__FILE__) + '/' + file
    auth_data = YAML::load_file(auth_file)

    FlickRaw.api_key = auth_data[:key]
    FlickRaw.shared_secret = auth_data[:secret]

    # Authenticate at Flickr, unless we have already done so and saved the
    # authentication token to the disk.
    if auth_data.include?(:auth_token) and auth_data.include?(:auth_secret)
      flickr.access_token = auth_data[:auth_token]
      flickr.access_secret = auth_data[:auth_secret]
      begin
        @auth = flickr.auth.oauth.checkToken
      rescue FlickRaw::OAuthClient::FailedResponse => e
        puts "Encountered error #{e} while checking security token."
      end
    else
      token = flickr.get_request_token
      auth_url = flickr.get_authorize_url token['oauth_token'], :perms => perms

      puts "Open this url in your process to complete the authentication process : #{auth_url}"
      puts "Press Enter when you are finished."
      verify = STDIN.gets.strip

      begin
        flickr.get_access_token token['oauth_token'], token['oauth_token_secret'], verify
        @auth = flickr.auth.oauth.checkToken

        puts "Authenticated as #{@auth.user}"

        auth_data[:auth_token] = token['oauth_token']
        auth_data[:auth_secret] = token['oauth_token_secret']
        File.open(auth_file, 'w') { |f| YAML.dump(auth_data, f) }
      rescue FlickRaw::OAuthClient::FailedResponse => e
        puts "Authentication failed : #{e.msg}"
      end
    end
    @auth
  end
end
