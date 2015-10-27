class Spritesheet

  attr_accessor :urls, :sprites, :updated_at

  def initialize
    @sprites = []
  end

  def generate
    dir = "/tmp/ffetcher/favicons"
    `mkdir -p #{dir}`
    image_filenames = []
    Favicon::Cache.get_cached_favicon_urls.each_with_index do |url, i|
      favicon_data = Favicon::Cache.new(url).get 
      png_filename = "#{dir}/#{subbed_url(url)}.png"
      image_filenames << png_filename
      sprite = {
        :url        => url,
        :css_class  => "favicon-#{subbed_url(url)}",
        :css_rule   => "background-position: -#{16 * i}px 0;"
      }
      @sprites << sprite
      open(png_filename, "wb") {|f| f.write favicon_data }
    end
    merged_image = "#{dir}/favicons.png"
    `convert #{image_filenames.join " "} -colorspace RGB +append png:#{merged_image}`
    @updated_at = Time.now.to_i
    `cp #{merged_image} #{Rails.root.join("app/assets/images/favicons.png")}`
  end

  private

  def subbed_url(url)
    url.gsub(/\./, '_')
  end

end
