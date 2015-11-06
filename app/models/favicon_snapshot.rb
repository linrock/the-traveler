class FaviconSnapshot < ActiveRecord::Base

  validates_format_of :query_url, :with => /\Ahttps?:\/\//
  validates_format_of :final_url, :with => /\Ahttps?:\/\//
  validates_format_of :favicon_url, :with => /\A(https?:\/\/|data:)/
  validates_presence_of :raw_data
  validates_presence_of :png_data

  class << self

    def most_recent_for_query(query_url)
      where(:query_url => normalize_url(query_url)).order('id DESC').first
    end

    def init_with_query(query_url)
      FaviconSnapshot.new(:query_url => normalize_url(query_url))
    end

    def find_or_init_with_query(query_url)
      normalized_url = normalize_url(query_url)
      favicon_snapshot = FaviconSnapshot.most_recent_for_query(normalized_url)
      return favicon_snapshot if favicon_snapshot.present?
      FaviconSnapshot.init_with_query(normalized_url)
    end

    def find_or_fetch!(query_url)
      normalized_url = normalize_url(query_url)
      favicon_snapshot = FaviconSnapshot.find_or_init_with_query(normalized_url)
      return favicon_snapshot if favicon_snapshot.persisted?
      favicon_snapshot.init_from_fetcher_results
      favicon_snapshot.save!
      favicon_snapshot
    end
    alias_method :lookup!, :find_or_fetch!

  end

  def init_from_fetcher_results
    data = fetcher.fetch
    self.attributes = fetcher.get_urls
    self.raw_data = data.data
    self.png_data = data.to_png
  end

  def fetcher
    return @fetcher if defined?(@fetcher)
    @fetcher = Favicon::Fetcher.new(self.query_url)
  end

  def data
    Favicon::Data.new(raw_data)
  end

  def favicon_data_uri
    "data:image/png;base64,#{Base64.encode64(png_data).split(/\s+/).join}"
  end

  private

  def self.normalize_url(url)
    url = url.strip.downcase
    if url =~ /\Ahttps?:\/\//
      url
    else
      "http://#{url}"
    end
  end

end
