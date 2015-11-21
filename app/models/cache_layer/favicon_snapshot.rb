class CacheLayer::FaviconSnapshot

  class << self

    def get(favicon_id)
      serialized_favicon = Rails.cache.read(cache_key(favicon_id))
      return unless serialized_favicon
      Marshal.load serialized_favicon
    end

    def get_or_set(favicon_id)
      favicon_snapshot = get favicon_id
      return favicon_snapshot if favicon_snapshot
      favicon_snapshot = ::FaviconSnapshot.find(favicon_id)
      return unless favicon_snapshot
      set favicon_snapshot
    end

    def set(favicon_snapshot)
      id = favicon_snapshot.id
      Rails.cache.write(cache_key(id), Marshal.dump(favicon_snapshot))
      favicon_snapshot
    end

    def cache_key(favicon_id)
      "favicon_snapshot:#{favicon_id}"
    end

  end

end
