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

    attr_accessor :final_url

    def initialize(url)
      @url = url
      @final_url = nil
      @html = nil
      @candidates = []
    end

    def fetch
      @html = `curl -sL --compressed -1 -m #{TIMEOUT} #{@url}`
      get_final_url
      get_candidate_favicon_urls
      get_favicon
    end

    def get_favicon
      @candidates.each do |url|
        d = Favicon::Data.new(get_favicon_data(url))
        return d if d.valid?
      end
      nil
    end

    # Tries to find favicon urls from the html content of given url
    #
    def get_candidate_favicon_urls
      uri = URI @final_url
      root = "#{uri.scheme}://#{uri.host}"
      doc = Nokogiri.parse @html
      @candidates = doc.css(ICON_SELECTORS.join(",")).map do |e|
        href = e.attr('href')
        href = URI.join(root, href).to_s if href !~ /^http/
        href
      end
      @candidates << URI.join(root, "favicon.ico").to_s
      @candidates << URI.join(root, "favicon.png").to_s
    end

    # Follow redirects from the given url to get to the actual url
    #
    def get_final_url
      output = `curl -sIL -1 -m #{TIMEOUT} #{@url}`
      final = output.scan(/Location: (.*)/)[-1]
      @final_url = final && final[0].strip
      return @final_url if @final_url.present?
      @final_url = if @url.starts_with?("http://")
                     @url
                   else
                     "http://#{@url}"
                   end
    end

    def get_favicon_data(url)
      return Base64.decode64(url.split(',')[1]) if url =~ /^data:/
      `curl -sL -m #{TIMEOUT} #{url}`
    end

  end

end
