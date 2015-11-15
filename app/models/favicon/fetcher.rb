require 'open3'


module Favicon

  # Actually go and grab the favicon from the given url
  #
  class Fetcher

    # Given a url, grab the favicon
    #
    TIMEOUT = 5
    ICON_SELECTORS = [ 'link[rel="shortcut icon"]',
                       'link[rel="icon"]',
                       'link[type="image/x-icon"]',
                       'link[rel="fluid-icon"]',
                       'link[rel="apple-touch-icon"]'
                     ]

    attr_accessor :query_url, :final_url, :favicon_url, :candidate_urls, :html, :raw_data

    def initialize(url)
      @query_url = normalize_url(url)
      @final_url = nil
      @favicon_url = nil
      @html = nil
      @candidate_urls = []
      @raw_data = nil
    end

    def curl_cmd(url)
      "curl -sL -k --compressed -m #{TIMEOUT} --ciphers 'RC4,3DES,ALL' --fail --show-error #{url}"
    end

    def http_get(url)
      stdin, stdout, stderr, t = Open3.popen3(curl_cmd(url))
      @html = encode_utf8(stdout.read).strip
      if (err = stderr.read.strip).present?
        raise Favicon::CurlError.new(err)
      end
    end

    def fetch
      http_get @query_url
      get_final_url
      get_candidate_favicon_urls
      get_favicon
    end

    def get_favicon
      return @raw_data if @raw_data.present?
      @raw_data = get_favicon_data_from_candidate_urls
      raise Favicon::NotFound.new(@query_url) unless @raw_data
      @raw_data
    end

    def get_favicon_data_from_candidate_urls
      @candidate_urls.each do |url|
        d = Favicon::Data.new(get_favicon_data(url))
        if d.valid?
          @favicon_url = url
          return d
        end
      end
      nil
    end

    # Tries to find favicon urls from the html content of given url
    #
    def get_candidate_favicon_urls
      doc = Nokogiri.parse @html
      @candidate_urls = doc.css(ICON_SELECTORS.join(",")).map {|e| e.attr('href') }.compact
      @candidate_urls.sort_by! {|href|
        if href =~ /\.ico/
          0
        elsif href =~ /\.png/
          1
        else
          3
        end
      }
      uri = URI @final_url
      root = "#{uri.scheme}://#{uri.host}"
      @candidate_urls.map! do |href|
        href = URI.encode(href.strip)
        if href.starts_with? "//"
          href = "#{uri.scheme}:#{href}"
        elsif href !~ /\Ahttp/
          # TODO handle invalid URLS
          # ex. {http://i50.tinypic.com/wbuzcn.png}
          href = URI.join(root, href).to_s rescue nil
        end
        href
      end.compact
      @candidate_urls << URI.join(root, "favicon.ico").to_s
      @candidate_urls << URI.join(root, "favicon.png").to_s
    end

    # Follow redirects from the query url to get to the last url
    #
    def get_final_url
      output = `curl -sIL -1 -m #{TIMEOUT} "#{@query_url}"`
      final = output.scan(/\ALocation: (.*)/)[-1]
      final_url = final && final[0].strip
      if final_url.present?
        if final_url.starts_with? "http"
          @final_url = URI.encode final_url
        else
          uri = URI @query_url
          root = "#{uri.scheme}://#{uri.host}"
          @final_url = URI.encode URI.join(root, final_url).to_s
        end
      end
      return @final_url if @final_url.present?
      @final_url = @query_url
    end

    def get_favicon_data(url)
      return Base64.decode64(url.split(',')[1]) if url =~ /^data:/
      `#{curl_cmd(url)}`
    end

    def get_urls
      {
        :query_url    => @query_url,
        :final_url    => @final_url,
        :favicon_url  => @favicon_url
      }
    end

    private

    def normalize_url(url)
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

  end

end
