module Favicon

  # Accesses the favicon, whether through cache or fetching it
  #
  class Accessor

    attr_accessor :fetcher

    def initialize(url, options = {})
      @url = url
      if @url =~ /https?:\/\//
        @host = URI.parse(url).host
      else
        @host = url
      end
      @options = options
      @fetcher = Favicon::Fetcher.new(url)
      @cache = Favicon::Cache.new(url)
    end

    def get_favicon_image_from_cache(url)
      favicon_cache(url).get
    end

    def get_favicon_image_from_url(url)
      image = @fetcher.fetch
      return unless image

      raw_image = image.to_png
      favicon_cache(url).set raw_image
      raw_image
    end

    def favicon_cache(url)
      Favicon::Cache.new(url)
    end

    # Chooses cache or fetching favicon directly
    #
    def get_favicon_image
      unless @options[:skip_cache]
        cached_image = get_favicon_image_from_cache(@host)
        return cached_image if cached_image
      end
      return if @options[:only_cache]
      get_favicon_image_from_url(@host)
    end

  end

end
