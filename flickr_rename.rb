require 'flickraw'

# Read API key from yaml file. The file auth.yml should be:
# :key: API_KEY
# :secret: SHARED_SECRET
# :machine_tag: PREFIX_FOR_MACHINE_TAGS (I use my username, funkaoshi)
user_data = YAML::load_file(File.dirname(__FILE__) + '/auth.yml')

FlickRaw.api_key = user_data[:key]
FlickRaw.shared_secret = user_data[:secret]

# Authenticate at Flickr, unless we have already done so and saved the 
# authentication token to the disk.
auth = nil
if File.exists?("flickr_auth_token")
  auth = flickr.auth.checkToken :auth_token => File.read('flickr_auth_token')
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
  File.open('flickr_auth_token', 'w') { |f| f.write(auth.token) }
end

# load the users recent photos from Flickr
photos = flickr.photos.search( :user_id => auth.user.nsid )

# For each photo named with film information, add appropriate tags and then
# clear out the title and description.
count = 0
photos.each do |photo|
  if photo.title =~ /Roll ([0-9]*) - (.*) - (.*) - (.*) - (.*)/
    count = count + 1
    puts "Updating photograph - #{photo.title}"
    tags = "#{user_data[:machine_tag]}:roll=%s #{user_data[:machine_tag]}:date=\"%s\" %s \"%s\" #{user_data[:machine_tag]}:id=%s" % $~[1..5]
    flickr.photos.setTags( :photo_id => photo.id, :tags => tags)
    flickr.photos.setMeta( :photo_id => photo.id, :title => '', :description => '' )
  end
end
puts "Updated #{count} photographs."