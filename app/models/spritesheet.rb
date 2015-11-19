class Spritesheet

  attr_accessor :urls, :sprites, :updated_at

  def initialize(favicon_snapshots)
    @favicon_snapshots = favicon_snapshots
    @sprites = []
  end

  def regenerate
    tmp_dir = "/tmp/ffetcher/favicons"
    `mkdir -p #{tmp_dir}`
    image_filenames = []
    @favicon_snapshots.each_with_index do |favicon, i|
      png_data = favicon.png_data
      png_filename = "#{tmp_dir}/#{subbed_url(url)}.png"
      image_filenames << png_filename
      sprite = {
        :url        => url,
        :css_class  => "favicon-#{subbed_url(url)}",
        :css_rule   => "background-position: -#{16 * i}px 0;"
      }
      @sprites << sprite
      open(png_filename, "wb") {|f| f.write png_data }
    end
    merged_png_filename = "#{tmp_dir}/favicons.png"
    `convert #{image_filenames.join " "} -colorspace RGB +append png:#{merged_png_filename}`
    @updated_at = Time.now.to_i
    `cp #{merged_png_filename} #{Rails.root.join("app/assets/images/favicons.png")}`
  end

  def regenerate_forever
    loop do
      puts "[#{Time.now}] Regenerating spritesheet..."
      regenerate
      sleep 3600
    end
  end

  private

  def subbed_url(url)
    url.gsub(/\./, '_')
  end

end
