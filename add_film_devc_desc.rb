# This is a script that will append a link to the filmdev.org recipe that
# describes how a black and white roll I shot was developed. This currently
# examines more photos than it really should. Should probably tag what i've
# processed, or store the last update date locally.

require 'flickraw'
require_relative 'flickr_auth.rb'

# authorize with Flickr
auth = FlickrAuth.new('auth.yml', 'write')

# load the users recent photos from Flickr
photos = flickr.photos.search(:user_id => auth.user.nsid, 
                              :machine_tags => 'filmdev:recipe=',
                              :extras => 'machine_tags, description' )

# For each photo named with film information, append link to the 
# filmdev site's recipe page.
count = 0
photos.each do |photo|
  unless photo.description =~ /filmdev.org/
    if photo.machine_tags =~ /filmdev:recipe=(\d+)/
      count += 1
      puts "Updating: #{photo.title}"
      description = "#{photo.description}"
      description += "\n\n" unless description.empty?
      description += "<a href='http://filmdev.org/recipe/show/#{$~[1]}'>Development details on FilmDev</a>"
      flickr.photos.setMeta( :photo_id => photo.id, :title => photo.title, :description => description )
    end
  end
end
puts "Updated #{count} photographs on #{Time.now.strftime('%D (%T)')}."
