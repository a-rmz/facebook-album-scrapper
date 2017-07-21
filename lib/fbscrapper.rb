require "fbscrapper/version"
require "koala"
require "open-uri"
require "yaml"

module Fbscrapper
  puts "Welcome to the Facebook album scrapper!"

  config = YAML.load_file("config.yaml")
  Threshold = config["threshold"]["width"]
  Verbose = config["verbose"]

  Access_token = config["facebook"]["access_token"]
  @graph = Koala::Facebook::API.new(Access_token)

  Album_id = config["facebook"]["album_id"]
  Request_batch = config["facebook"]["request_batch"]
  @data = @graph.get_connections(Album_id, "photos", {
    limit: Request_batch,
    fields: ["images"]
  })

  @images = Hash.new

  Batch_size = config["batch_size"]
  puts Batch_size
  until @images.length >= Batch_size
    if Verbose then puts "#{@data.length} photos retreived" end
    @data.each do |photo|
      image = photo["images"][0]

      if image["width"] > Threshold and @images.length < Batch_size
        if Verbose then puts "#{image["source"]} (#{image["width"]}, #{image["height"]})" end
        @images[image["source"]] = "#{image["width"]}x#{image["height"]}"
      end
    end
    @data = @data.next_page
  end

  Save_dir = config["save_dir"]
  count = 0

  @images.each do |name, dimens|
    @capture_gps = name.match(/https:\/\/scontent.xx.fbcdn.net\/v\/t31.0-8\/([0-9]+)(_[0-9]+_[0-9]+_o.jpg)?(.+)/).captures
    @name = @capture_gps[0]

    @filename = File.join(Save_dir, "#{@name}_#{dimens}.jpg")

    if not File.file?(@filename) then
      if Verbose then puts @filename end
      File.open(@filename, "wb") do |fo|
        fo.write open(name).read
      end
      count += 1
    end
  end

  puts "#{count} photos downloaded"

end
