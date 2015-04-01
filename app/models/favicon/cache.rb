module Favicon

  # For handling the getting/setting of favicon data
  # in the cache (memcached)
  #
  class Cache

    def initialize(url)
      @store = Rails.cache
      @key = "favicon:#{url}"
    end

    # Get the cached favicon image data
    #
    def get
      @store.read @key
    end

    def set(image_data, options = {})
      opts = { :expires_in => 1.month }.merge(options)
      @store.write @key, image_data, **opts
      mru_set
      image_data
    end

    # When fetching a new favicon, add it to the list
    #
    def mru_set
      favicons = @store.read("favicon_cache:mru")
      favicons ||= []
      favicons.push @key.split("favicon:").last
      @store.write("favicon_cache:mru", favicons)
      favicons
    end

    def self.get_cached_favicon_urls
      Rails.cache.read("favicon_cache:mru") || []
    end

  end

end
