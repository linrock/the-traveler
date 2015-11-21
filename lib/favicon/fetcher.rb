require 'open3'


module Favicon

  # Actually go and grab the favicon from the given url
  #
  class Fetcher
    include Favicon::Utils

    ICON_SELECTORS = [ 'link[rel="shortcut icon"]',
                       'link[rel="icon"]',
                       'link[type="image/x-icon"]',
                       'link[rel="fluid-icon"]',
                       'link[rel="apple-touch-icon"]'
                     ]

    attr_accessor :query_url, :final_url, :favicon_url, :candidate_urls, :html, :data

    def initialize(url)
      @query_url       = prefix_url(url)
      @final_url       = nil
      @favicon_url     = nil
      @html            = nil
      @data            = nil
      @candidate_urls  = []
    end

    # Encodes output as utf8 - Not for binary http responses
    #
    def http_get(url)
      Favicon::HTTPClient.get(url)
    end

    def fetch
      set_final_url
      @html = http_get @final_url
      set_candidate_favicon_urls
      get_favicon_data
    end

    def get_favicon_data
      return @data if @data.present?
      @data = get_favicon_data_from_candidate_urls
      raise Favicon::NotFound.new(@query_url) unless @data
      @data
    end

    def get_favicon_data_from_candidate_urls
      @candidate_urls.each do |url|
        data = Favicon::Data.new(get_favicon_data_from_url(url))
        begin
          if data.valid?
            @favicon_url = url
            return data
          end
        rescue ImageMagickError => error
          error.meta = get_urls
          error.meta[:favicon_url] ||= url
          error.meta[:base64_favicon_data] = data.base64_source_data
          raise error
        end
      end
      nil
    end

    # Tries to find favicon urls from the html content of given url
    #
    def set_candidate_favicon_urls
      doc = Nokogiri.parse @html
      @candidate_urls = doc.css(ICON_SELECTORS.join(",")).map {|e| e.attr('href') }.compact
      @candidate_urls.sort_by! {|href|
        if href =~ /\.ico/
          0
        elsif href =~ /\.png/
          1
        else
          2
        end
      }
      uri = URI @final_url
      url_root = "#{uri.scheme}://#{uri.host}"
      @candidate_urls.map! do |href|
        href = URI.encode(href.strip)
        if href.starts_with? "//"
          href = "#{uri.scheme}:#{href}"
        elsif href !~ /\Ahttp/
          # Ignore invalid URLS - ex. {http://i50.tinypic.com/wbuzcn.png}
          href = URI.join(url_root, href).to_s rescue nil
        end
        href
      end.compact
      @candidate_urls << URI.join(url_root, "favicon.ico").to_s
      @candidate_urls << URI.join(url_root, "favicon.png").to_s
    end

    # Follow redirects from the query url to get to the last url
    #
    def set_final_url
      output = Favicon::HTTPClient.head(@query_url)
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
      if @final_url.present?
        if %w( 127.0.0.1 localhost ).any? {|host| @final_url.include? host }
          # TODO Exception for invalid final urls
          @final_url = @query_url
        end
        return @final_url
      end
      @final_url = @query_url
    end

    def get_favicon_data_from_url(url)
      if url =~ /^data:/
        data = url.split(',')[1]
        return data && Base64.decode64(data)
      end
      Favicon::HTTPClient.bin_get url
    end

    def get_urls
      {
        :query_url    => @query_url,
        :final_url    => @final_url,
        :favicon_url  => @favicon_url
      }
    end

    def has_data?
      @data.present? && !@data.blank?
    end

  end

end
