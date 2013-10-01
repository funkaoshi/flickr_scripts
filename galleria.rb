require 'flickraw'
require_relative 'flickr_auth.rb'

auth = FlickrAuth.new('auth.yml')

gallery_map = {}
contacts = flickr.contacts.getList
contacts.each do |contact|
  galleries = flickr.galleries.getList(:user_id => contact.nsid)
  gallery_map[contact.realname] = galleries.gallery if galleries.total.to_i > 0
end

gallery_map.each do |name, gallery|
  puts "#{name}"
  gallery.each do |g|
    puts "\t#{g.title} - #{g.url}"
  end
end
