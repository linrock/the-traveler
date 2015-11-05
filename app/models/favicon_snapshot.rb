class FaviconSnapshot < ActiveRecord::Base

  validates_format_of :query_url, :with => /\Ahttps?:\/\//
  validates_format_of :final_url, :with => /\Ahttps?:\/\//
  validates_format_of :favicon_url, :with => /\A(https?:\/\/|data:)/
  validates_presence_of :raw_data
  validates_presence_of :png_data

  def self.most_recent_for_query(query_url)
    where(:query_url => normalize_url(query_url)).order('id DESC').first
  end

  def self.init_with_query(query_url)
    FaviconSnapshot.new(:query_url => normalize_url(query_url))
  end

  def self.find_or_init_with_query(query_url)
    normalized_url = normalize_url(query_url)
    favicon_snapshot = FaviconSnapshot.most_recent_for_query(normalized_url)
    return favicon_snapshot if favicon_snapshot.present?
    FaviconSnapshot.init_with_query(normalized_url)
  end

  def self.find_or_fetch!(query_url)
    normalized_url = normalize_url(query_url)
    favicon_snapshot = FaviconSnapshot.find_or_init_with_query(normalized_url)
    return favicon_snapshot if favicon_snapshot.persisted?
    favicon_data = favicon_snapshot.fetcher.fetch
    favicon_snapshot.attributes = favicon_snapshot.fetcher.get_results
    favicon_snapshot.png_data = favicon_data.to_png
    favicon_snapshot.save!
    favicon_snapshot
  end

  def fetcher
    return @fetcher if defined?(@fetcher)
    @fetcher = Favicon::Fetcher.new(self.query_url)
  end

  def data
    Favicon::Data.new(raw_data)
  end

  private

  def self.normalize_url(url)
    if url =~ /\Ahttps?:\/\//
      url
    else
      "http://#{url}"
    end
  end

end
