module Favicon
  
  module Utils

    def prefix_url(url)
      url = URI.encode url.strip.downcase
      if url =~ /https?:\/\//
        url
      else
        "http://#{url}"
      end
    end

    def encode_utf8(text)
      return text if text.valid_encoding?
      text.encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => '')
    end

    def with_temp_data_file(data, &block)
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

    extend self
  end

end
