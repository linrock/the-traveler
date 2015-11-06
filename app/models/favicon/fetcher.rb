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

    attr_accessor :query_url, :final_url, :favicon_url, :candidate_urls, :raw_data

    def initialize(url)
      @query_url = normalize_url(url)
      @final_url = nil
      @favicon_url = nil
      @html = nil
      @candidate_urls = []
      @raw_data = nil
    end

    def fetch
      @html = `curl -sL --compressed -1 -m #{TIMEOUT} #{@query_url}`
      get_final_url
      get_candidate_favicon_urls
      get_favicon
    end

    def get_favicon
      return @raw_data if @raw_data.present?
      @raw_data = get_favicon_data_from_candidate_urls
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
      uri = URI @final_url
      root = "#{uri.scheme}://#{uri.host}"
      doc = Nokogiri.parse @html
      @candidate_urls = doc.css(ICON_SELECTORS.join(",")).map {|e| e.attr('href') }
      @candidate_urls.sort_by! {|href|
        if href =~ /\.ico/
          0
        elsif href =~ /\.png/
          1
        else
          3
        end
      }
      @candidate_urls.map! do |href|
        if href.starts_with? "//"
          href = "#{uri.scheme}:#{href}"
        elsif href !~ /\Ahttp/
          href = URI.join(root, href).to_s
        end
        href
      end
      @candidate_urls << URI.join(root, "favicon.ico").to_s
      @candidate_urls << URI.join(root, "favicon.png").to_s
    end

    # Follow redirects from the given url to get to the actual url
    #
    def get_final_url
      output = `curl -sIL -1 -m #{TIMEOUT} #{@query_url}`
      final = output.scan(/Location: (.*)/)[-1]
      final_url = final && final[0].strip
      if final_url.present?
        if final_url.starts_with? "/"
          uri = URI @query_url
          root = "#{uri.scheme}://#{uri.host}"
          @final_url = URI.join(root, final_url)
        else
          @final_url = final_url
        end
      end
      return @final_url if @final_url.present?
      @final_url = @query_url
    end

    def get_favicon_data(url)
      return Base64.decode64(url.split(',')[1]) if url =~ /^data:/
      `curl -sL -m #{TIMEOUT} #{url}`
    end

    def get_results
      {
        :query_url    => @query_url,
        :final_url    => @final_url,
        :favicon_url  => @favicon_url,
        :raw_data     => @raw_data.data
      }
    end

    private

    def normalize_url(url)
      if url =~ /https?:\/\//
        url
      else
        "http://#{url}"
      end
    end
  end

end
