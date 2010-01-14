# This was a script I wrote to update the titles and
# descriptions of a flickr set that contained photos 
# from my old photoblog. To say this is probably
# useless to anyone else is an understatement. It's
# also very ugly, but it worked.

require 'flickraw'
require 'flickr_auth.rb'
require 'rdiscount'
require '../forked/ruby-mtexport/mtexport_parser.rb'

# authorize at flickr, loading auth data from yaml file.
auth = FlickrAuth.new('auth.yml', 'write')

# load all the photos from the pre-TXP flickr set. I had
# previously updated the photos so that the original titles
# for the images were saved as a machine tag. The old titles
# were originally the image filename, which was the date 
# the image was posted, in YYYYMMDD format -- i.e. 20041106.jpg.
# The images are all stored in a map indexed by the old title
# key. (When storing the old title I droped the jpg.)
photos_map = {}
page = 1
while
  photos = flickr.photosets.getPhotos( 
    :photoset_id => '797308',
    :page => page, :per_page => 500,
    :extras => 'tags, machine_tags')
  photos.photo.each do |p|
    if p.machine_tags =~ /funkaoshi:old_title=(.*)/
      photos_map[ $~[1] ] = p
    end
  end
  break if photos.page.to_i == photos.pages.to_i
  page = photos.page.to_i + 1
end
puts "Found #{photos_map.size} photos to process."

# Load up all my blog posts! The text file is a normal
# MT Export file of my photoblogs posts.
file = File.read("we_must_abuse_the_broadband.txt")
mt = MtexportParser.new(file)
mt.parse

count = 0
mt.each_blog_post do |post|
  # based on the post date we build the key used to
  # index the photos_map, and we also build the date
  # string as I like it, YYYY/MM/DD.
  m = post[:date].match(/(\d\d)\/(\d\d)\/(\d\d\d\d)/)
  date_key = "#{m[3]}#{m[1]}#{m[2]}"
  date = "#{m[3]}/#{m[1]}/#{m[2]}"
  
  flickr_info = photos_map[date_key]
  unless flickr_info.nil?
    # If there is a post body, we will convert it to HTML if its
    # in Markdown, and we will also replace relative links
    # with full links to my old site. We also add a link to the
    # original post to the bottom of the new description.
    if post[:body]      
      if post[:convert_breaks] != '0'
        body = Markdown.new(post[:body]).to_html
      end
      body.gsub!(/"\/abuse/, "\"http://funkaoshi.com/abuse")
    end
    new_body = "#{post[:excerpt]}"
    new_body += "\n\n" unless new_body.empty?
    new_body += body if body
    new_body += "\n" unless new_body.empty?
    new_body += "Originally from We Must Abuse the Broaband - <a href='http://funkaoshi.com/abuse/#{date}/'>#{post[:title]}</a>"

    puts "#{date} - #{post[:title]}"

    flickr.photos.setMeta(
      :photo_id => flickr_info["id"],
      :title => "#{date} - #{post[:title]}", 
      :description => new_body)

    count += 1
  else
    # I had actually removed a couple photos from flickr
    # after uploading the entire set of images, so the
    # export file has a couple more entries than the
    # actual set does. This should be the only reason
    # we can't find a date in the photo map
    puts "#{date_key} missing"
  end
end
puts "#{count} of #{mt.size} updated on Flickr."
