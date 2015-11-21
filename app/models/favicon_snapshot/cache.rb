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
    @cache.read cache_key(favicon_id)
  end

  def get_or_set(favicon_id)
    favicon = @cache.read cache_key(favicon_id)
    return favicon if favicon.present?
    set favicon_id
  end

  def set(favicon_id)
    favicon_snapshot = FaviconSnapshot.find favicon_id
    @cache.write cache_key(favicon_id), favicon_snapshot.as_json
  end

  def get_multi(favicon_ids)
    results = @cache.read_multi *favicon_ids.map {|id| cache_key(id) }
    results.map {|result| JSON.load(result[1]) }
  end

  def get_recent_favicons
    get_favicons_before(FaviconSnapshot.most_recent.id + 1)
  end

  def get_favicons_before(favicon_id)
    id_range = (favicon_id - FaviconSnapshot::N_PER_PAGE .. favicon_id - 1)
    favicons = get_multi id_range.to_a.reverse
  end

  def get_favicons_after(favicon_id)
    id_range = (favicon_id + 1 .. favicon_id + FaviconSnapshot::N_PER_PAGE)
    favicons = get_multi id_range.to_a
  end

  def cache_key(favicon_id)
    "favicon_snapshot:#{favicon_id}"
  end

end
