require 'flickraw'
require_relative 'flickr_auth.rb'

# todo: read these from command line or something
DESCRIPTION = 'DESCRIPTION'
SET_ID = 'SET'

# authorize at flickr, loading auth data from yaml file.
auth = FlickrAuth.new('auth.yml', 'write')

# get photos in set 
photos = flickr.photosets.getPhotos(:photoset_id => SET_ID, :extras => 'description')

photos.photo.each do |photo|
  description = photo.description
  description += "\n\n" unless description.empty?
  description += DESCRIPTION
  puts "Update: #{photo.title} - #{photo.id}"
  
  flickr.photos.setMeta(
      :photo_id => photo.id,
      :title => photo.title,
      :description => description)
end

