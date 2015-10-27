class Spritesheet

  attr_accessor :css, :image, :urls, :rows, :updated_at

  def initialize
  end

  def generate
    dir = "/tmp/ffetcher/favicons"
    `mkdir -p #{dir}`
    css_rules = [".favicon { width: 16px; height: 16px; }"]
    image_filenames = []
    @urls = []
    @rows = []
    Favicon::Cache.get_cached_favicon_urls.each_with_index do |url, i|
      favicon_data = Favicon::Cache.new(url).get 
      png_filename = "#{dir}/#{subbed_url(url)}.png"
      css_rule = ".favicon-#{subbed_url(url)} { background-position: -#{16 * i}px 0; }"
      css_rules << css_rule
      image_filenames << png_filename
      @urls << url
      row = {
        :url        => url,
        :css_class  => "favicon-#{subbed_url(url)}",
        :css_rule   => "background-position: -#{16 * i}px 0;"
      }
      @rows << row
      open(png_filename, "wb") {|f| f.write favicon_data }
    end
    merged_image = "#{dir}/favicons.png"
    `convert #{image_filenames.join " "} -colorspace RGB +append png:#{merged_image}`
    @image = open(merged_image).read
    @css   = css_rules.join("\n")
    @updated_at = Time.now.to_i
    `cp #{merged_image} #{Rails.root.join("app/assets/images/favicons.png")}`
  end

  private

  def subbed_url(url)
    url.gsub(/\./, '_')
  end

end
