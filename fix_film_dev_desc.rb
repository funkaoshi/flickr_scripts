# This is a script that will append a link to the filmdev.org recipe that
# describes how a black and white roll I shot was developed.

require 'flickraw'
require 'flickr_auth.rb'

# authorize with Flickr
auth = FlickrAuth.new('auth.yml')

# load the users recent photos from Flickr
photos = flickr.photos.search(:user_id => auth.user.nsid, 
                              :machine_tags => 'filmdev:recipe=',
                              :extras => 'machine_tags' )

# For each photo named with film information, append link to the 
# filmdev site's recipe page.
count = 0
photos.each do |photo|
  info = flickr.photos.getInfo( :photo_id => photo.id )
  if  info.description =~ /\\n\\n/
    puts "Updating: #{photo.title}"
    description = info.description.gsub(/\\n\\n/, ' ')
    flickr.photos.setMeta( :photo_id => photo.id, :title => info.title, :description => description )
  end
end
puts "Updated #{count} photographs on #{Time.now.strftime('%D (%T)')}."
