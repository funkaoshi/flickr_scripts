# # FlickrAuth

require 'flickraw'
require 'yaml'

# Encapsulates connecting to flickr, pulling auth information from a yaml file.
# A FlickrAuth object should behave the same way (more or less) as an auth object
# returned by FlickRaw.
class FlickrAuth  
  attr_reader :auth

  def initialize(file, perms='read')
    @auth = authorize(file, perms)
  end

  def token; @auth.token end
  def user; @auth.user end
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
    if auth_data.include?(:token)
      @auth = flickr.auth.checkToken :auth_token => auth_data[:token]
    else
      frob = flickr.auth.getFrob
      auth_url = FlickRaw.auth_url :frob => frob, :perms => perms

      puts "Open this url in your process to complete the authication process : #{auth_url}"
      puts "Press Enter when you are finished."
      STDIN.getc

      begin
        @auth = flickr.auth.getToken :frob => frob
        puts "Authenticated as #{auth.user.username}"
        auth_data[:token] = auth.token
        File.open(auth_file, 'w') { |f| YAML.dump(auth_data, f) }
      rescue FlickRaw::FailedResponse => e
        puts "Authentication failed : #{e.msg}"
      end
    end
    @auth
  end
end
