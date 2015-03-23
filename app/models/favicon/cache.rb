module Favicon

  # For handling the getting/setting of favicon data
  # in the cache (memcached)
  #
  class Cache

    def initialize(url)
      @store = Rails.cache
      @key = url
    end

    # Get the cached favicon image data
    #
    def get
      Rails.cache.read @key
    end

    def set(image_data, options = {})
      opts = { :expires_in => 1.day }.merge(options)
      Rails.cache.write @key, image_data, **opts
      mru_set
      image_data
    end

    # When fetching a new favicon, add it to the list
    #
    def mru_set
      favicons = Rails.cache.read("favicon_cache:mru")
      favicons ||= []
      favicons.push @key
      Rails.cache.write("favicon_cache:mru", favicons)
      favicons
    end

    def self.get_cached_favicon_urls
      Rails.cache.read("favicon_cache:mru") || []
    end

  end

end
