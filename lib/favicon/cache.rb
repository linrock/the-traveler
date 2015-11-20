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
      return unless Favicon::Data.new(image_data).valid?
      @store.write @key, image_data, **opts
      mru_set
      image_data
    end

    # When fetching a new favicon, add its url to the list
    #
    def mru_set
      favicon_urls = @store.read("favicon_cache:mru")
      favicon_urls ||= []
      url = @key.split("favicon:").last
      return favicon_urls if Set.new(favicon_urls).include? url
      favicon_urls.unshift url
      @store.write("favicon_cache:mru", favicon_urls)
      favicon_urls
    end

    def self.get_cached_favicon_urls
      Rails.cache.read("favicon_cache:mru") || []
    end

  end

end
