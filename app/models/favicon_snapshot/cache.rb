# Cache layer for FaviconSnapshot
#
class FaviconSnapshot::Cache

  # For handling the getting/setting of favicon data
  # in the cache (memcached)
  #
  def initialize
    @cache = Rails.cache
  end

  # Get the cached favicon image data
  #
  def get(favicon_id)
    @store.read cache_key(favicon_id)
  end

  def get_or_set(favicon_id)
    favicon = @store.read cache_key(favicon_id)
    return favicon if favicon.present?
    set favicon_id
  end

  def set(favicon_id)
    favicon_snapshot = FaviconSnapshot.find favicon_id
    @store.write cache_key(favicon_id), favicon_snapshot.to_json
  end

  def get_multi(favicon_ids)
    @cache.read_multi favicon_ids.map {|id| favicon_cache_key(id) }
  end

  def get_recent_favicons
    get_favcions_before FaviconSnapshot.most_recent.id
  end

  def get_favicons_before(favicon_id)
    id_range = (favicon_id - FaviconSnapshot::N_PER_PAGE .. favicon_id)
    favicons = get_multi id_range.reverse.to_a
  end

  def get_favicons_after(favicon_id)
    
  end

  def favicon_cache_key(favicon_id)
    "favicon_snapshot:#{favicon_id}"
  end

end
