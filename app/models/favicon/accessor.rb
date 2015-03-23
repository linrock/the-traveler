module Favicon

  # Accesses the favicon, whether through cache or fetching it
  #
  class Accessor

    def initialize(url, options = {})
      @url = url
      @options = options
    end

    # Chooses cache or fetching favicon directly
    #
    def get_favicon
      cache = Favicon::Cache.new(@url)

      unless @options[:skip_cache]
        cached_image = cache.get
        return cached_image if cached_image
      end

      fetcher = Favicon::Fetcher.new(@url)
      image = fetcher.fetch
      return unless image

      raw_image = image.to_png
      cache.set raw_image
      raw_image
    end

  end

end
