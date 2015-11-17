require 'open3'


module Favicon

  # For handling anything related to the data of the favicon itself
  #
  class Data

    # Threshold for stdev of color values under which the image data
    # is considered one color
    #
    STDEV_THRESHOLD = 0.005

    attr_accessor :data, :png_data

    def initialize(data)
      @data = data
    end

    def self.with_temp_data_file(data, &block)
      begin
        t = Tempfile.new(["favicon", ".ico"])
        t.binmode
        t.write data
        t.close
        result = block.call(t)
      ensure
        t.unlink
      end
      result
    end

    def self.get_mime_type(data)
      with_temp_data_file(data) do |t|
        `file -b --mime-type #{t.path.to_s}`.strip
      end
    end

    def imagemagick_run(cmd, binmode = false)
      stdin, stdout, stderr, t = Open3.popen3(cmd)
      stdout.binmode if binmode
      output = stdout.read.strip
      if output.empty? && (error = stderr.read.strip).present?
        raise Favicon::ImageMagickError.new(error)
      end
      output
    end

    def mime_type
      self.class.get_mime_type(@data)
    end

    def identify
      self.class.with_temp_data_file(@data) do |t|
        imagemagick_run("identify #{t.path.to_s}")
      end
    end

    # Does the data look like a valid favicon?
    # TODO return reasons why the favicon data is invalid
    # TODO ignore favicons that are close to one solid color
    def valid?
      return false if mime_type =~ /(text|html|xml|x-empty)/
      !blank? && !transparent? && !one_color?
    end

    # data size is invalid or 1x1 file sizes
    # TODO 1x1 would be caught by one_color?
    def blank?
      return false if @data.length <= 1
      files = identify.split(/\n/)
      files.length == 1 && files[0].include?(" 1x1 ")
    end

    def transparent?
      self.class.with_temp_data_file(@data) do |t|
        cmd = "convert #{t.path.to_s} -channel a -negate -format '%[mean]' info:"
        imagemagick_run(cmd).to_i == 0
      end
    end

    def one_color?
      colors_stdev < STDEV_THRESHOLD
    end

    def colors_stdev
      self.class.with_temp_data_file(to_png) do |t|
        cmd = "identify -format '%[fx:image.standard_deviation]' #{t.path.to_s}"
        imagemagick_run(cmd).to_f
      end
    end

    def n_colors
      self.class.with_temp_data_file(@data) do |t|
        cmd = "identify -format '%k' #{t.path.to_s}"
        imagemagick_run(cmd).to_i
      end
    end

    # number of bytes in the raw data
    def size
      @data.size
    end

    # Export data as a 16x16 png
    def to_png
      return @png_data if defined?(@png_data)
      self.class.with_temp_data_file(@data) do |t|
        sizes = imagemagick_run("identify #{t.path.to_s}").split(/\n/)
        files = []
        %w(16x16 32x32 64x64).each do |dims|
          %w(32-bit 24-bit 16-bit 8-bit).each do |bd|
            files += sizes.select {|x| x.include?(dims) and x.include?(bd) }.
                           map    {|x| x.split(' ')[0]}
          end
        end
        cmd = "convert -strip -resize 16x16! #{files.uniq[0] || "#{t.path.to_s}[0]"} png:fd:1"
        @png_data = imagemagick_run(cmd, true)
        raise Favicon::InvalidData.new("Empty png") if @png_data.empty?
        @png_data
      end
    end

    def base64_raw_data
      Base64.encode64(@data).split(/\s+/).join
    end

    def base64_png
      Base64.encode64(to_png).split(/\s+/).join
    end

    def inspect
      "#<Favicon::Data @data=#{@data.nil? ? nil : @data.size}>"
    end

  end

end
