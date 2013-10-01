require 'net/http'
require 'fileutils'
require 'flickraw'
require_relative 'flickr_auth.rb'

# quit unless our script gets two command line arguments
unless ARGV.length == 2
  puts "Usage: ruby download_set.rb set_id directory"
  exit
end

set_id = ARGV[0]
directory = ARGV[1]

FileUtils.mkdir_p(directory)

auth = FlickrAuth.new('auth.yml')

photos = flickr.photosets.getPhotos(:photoset_id => set_id, :extras => 'url_o').photo
puts "Downloading..."
photos.each_with_index do |photo, i|
  puts "  ... #{photo.title}"
  resp = Net::HTTP.get URI.parse(photo.url_o)
  File.open("#{directory}/#{i+1} #{photo.title}.jpg", "w") do |f|
    f.puts resp
  end
end