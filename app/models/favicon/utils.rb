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

    extend self
  end

end
