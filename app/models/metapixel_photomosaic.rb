class MetapixelPhotomosaic

  FAVICONS_DIR = "/tmp/favicons"

  def initialize
    raise "Metapixel not detected" unless `which metapixel`.present?
    `mkdir -p #{FAVICONS_DIR}`
  end

  def export_all_favicons
    HashedFaviconPng.find_each do |png|
      open("#{FAVICONS_DIR}/#{png.id}.png") do |f|
        f.binmode
        f.write png.png_data
      end
    end
  end

  def preprocess_all_pngs
    Dir.glob("#{FAVICONS_DIR}/*.png").each do |image|
      `convert -define png:color-type=2 -depth 16 #{image} #{image}`
    end
  end

  def prepare_favicons
    prepared_dir = "#{FAVICONS_DIR}-prepared"
    `metapixel-prepare --width=16 --height=16 #{FAVICONS_DIR} #{prepared_dir}`
  end

  def create(input_image_file, output_image_file)
    `metapixel -l #{prepared_dir} -c --width=16 --height=16 --metapixel #{input_image_file} #{output_image_file}`
  end

  private

  def prepared_dir
    "#{FAVICONS_DIR}-prepared"
  end

end
