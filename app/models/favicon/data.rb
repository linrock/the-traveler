require 'open3'


module Favicon

  # For handling anything related to the data of the favicon itself
  #
  class Data

    attr_accessor :data

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

    def self.run_imagemagick_cmd(cmd, binmode = false)
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
        self.class.run_imagemagick_cmd("identify #{t.path.to_s}")
      end
    end

    # Does the data look like a valid favicon?
    def valid?
      return false if blank?
      mime_type !~ /(text|html|xml|x-empty)/
    end

    # data size is invalid or 1x1 file sizes
    def blank?
      return false if @data.length <= 1
      files = identify.split(/\n/)
      files.length == 1 && files[0].include?(" 1x1 ")
    end

    # Export data as a 16x16 png
    def to_png
      self.class.with_temp_data_file(@data) do |t|
        sizes = self.class.run_imagemagick_cmd("identify #{t.path.to_s}").split(/\n/)
        files = []
        %w(16x16 32x32 64x64).each do |dims|
          %w(32-bit 24-bit 16-bit 8-bit).each do |bd|
            files += sizes.select {|x| x.include?(dims) and x.include?(bd) }.
                           map    {|x| x.split(' ')[0]}
          end
        end
        cmd = "convert -resize 16x16! #{files.uniq[0] || "#{t.path.to_s}[0]"} png:fd:1"
        data = self.class.run_imagemagick_cmd(cmd, true)
        raise Favicon::InvalidData.new("Empty png") if data.empty?
        data
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
