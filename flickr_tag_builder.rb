require 'flickraw'

# Prefix for the machine tags generated. I use my username, funkaoshi
MACHINE_TAG = 'funkaoshi'

AUTH_FILE = File.dirname(__FILE__) + '/auth.yml'

# Read API key from yaml file. The file auth.yml should contain
# the key and secret fields from your API key page. We will also 
# save the auth token Flickr sends us in this file once we have 
# authenticated. To start, create a file with the following:
# :key: API_KEY
# :secret: SHARED_SECRET
auth_data = YAML::load_file(AUTH_FILE)

FlickRaw.api_key = auth_data[:key]
FlickRaw.shared_secret = auth_data[:secret]

# Authenticate at Flickr, unless we have already done so and saved the 
# authentication token to the disk.
auth = nil
if auth_data.include?(:token)
  auth = flickr.auth.checkToken :auth_token => auth_data[:token]
else
  frob = flickr.auth.getFrob
  auth_url = FlickRaw.auth_url :frob => frob, :perms => 'write'

  puts "Open this url in your process to complete the authication process : #{auth_url}"
  puts "Press Enter when you are finished."
  STDIN.getc

  begin
    auth = flickr.auth.getToken :frob => frob
    puts "Authenticated as #{auth.user.username}"
  rescue FlickRaw::FailedResponse => e
    puts "Authentication failed : #{e.msg}"
  end
  auth_data[:token] = auth.token
  File.open(AUTH_FILE, 'w') { |f| YAML.dump(auth_data, f) }
end

# load the users recent photos from Flickr
photos = flickr.photos.search( :user_id => auth.user.nsid )

# For each photo named with film information, add appropriate tags and then
# clear out the title and description.
count = 0
photos.each do |photo|
  if photo.title =~ /Roll ([0-9]*) - (.*) - (.*) - (.*) - (.*)/
    count = count + 1
    puts "Updating: #{photo.title}"
    tags = "#{MACHINE_TAG}:roll=%s #{MACHINE_TAG}:date=\"%s\" %s \"%s\" #{MACHINE_TAG}:id=%s" % $~[1..5]
    flickr.photos.setTags( :photo_id => photo.id, :tags => tags)
    flickr.photos.setMeta( :photo_id => photo.id, :title => '', :description => '' )
  end
end
puts "Updated #{count} photographs on #{Time.now.strftime('%D (%T)')}."
puts "---"
