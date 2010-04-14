#!/usr/bin/ruby

# This is a script I use to generate some tags for my photos on Flickr using the
# name of the image. When I save my film scans, I name them as follow: 
# 
#   Roll XX - DATE_SCANNED - CAMERA - FILM - UNIQUE_ID.jpg
# 
# When these files are uploaded to Flickr, their titles become:
# 
#   Roll XX - DATE_SCANNED - CAMERA - FILM - UNIQUE_ID
# 
# I take this name and turn it into the following set of tags and clear out the
# title and description.
# 
#   MACHINE_TAG:roll=XX MACHINE_TAG:date="DATE" CAMERA FILM MACHINE_TAG:id=UNIQUE_ID

require 'flickraw'
require 'flickr_auth.rb'

# Prefix for the machine tags generated. I use my username, funkaoshi
MACHINE_TAG = 'funkaoshi'

# authorize at flickr, loading auth data from yaml file.
auth = FlickrAuth.new('auth.yml', 'write')

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
    flickr.photos.setTags( :photo_id => photo.id, :tags => tags )
    flickr.photos.setMeta( :photo_id => photo.id, :title => '', :description => '' )
  end
end
puts "Updated #{count} photographs on #{Time.now.strftime('%D (%T)')}."
puts "---"
