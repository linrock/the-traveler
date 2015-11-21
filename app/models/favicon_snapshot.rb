class FaviconSnapshot < ActiveRecord::Base
  extend Favicon::Utils

  validates_format_of :query_url, :with => /\Ahttps?:\/\//
  validates_format_of :final_url, :with => /\Ahttps?:\/\//
  validates_format_of :favicon_url, :with => /\A(https?:\/\/|data:)/
  validates_presence_of :hashed_favicon_source
  validates_presence_of :hashed_favicon_png

  belongs_to :hashed_favicon_source
  belongs_to :hashed_favicon_png

  # after_save :write_to_cache

  N_PER_PAGE = 100

  class << self

    def most_recent_for_query(query_url)
      where(:query_url => prefix_url(query_url)).order('id DESC').first
    end

    def init_with_query(query_url)
      FaviconSnapshot.new(:query_url => prefix_url(query_url))
    end

    def find_or_init_with_query(query_url)
      prefixed_url = prefix_url(query_url)
      favicon_snapshot = FaviconSnapshot.most_recent_for_query(prefixed_url)
      return favicon_snapshot if favicon_snapshot.present?
      FaviconSnapshot.init_with_query(prefixed_url)
    end

    def find_or_fetch!(query_url)
      prefixed_url = prefix_url(query_url)
      favicon_snapshot = FaviconSnapshot.find_or_init_with_query(prefixed_url)
      return favicon_snapshot if favicon_snapshot.persisted?
      favicon_snapshot.init_from_fetcher_results
      favicon_snapshot.save!
      favicon_snapshot
    end
    alias_method :lookup!, :find_or_fetch!

    def most_recent
      order("id DESC").first
    end

    def get_recent_favicons
      includes(:hashed_favicon_png).order("id DESC").limit(N_PER_PAGE)
    end

    def get_favicons_before(id)
      includes(:hashed_favicon_png).where("id < ?", id).order("id DESC").limit(N_PER_PAGE)
    end

    def get_favicons_after(id)
      includes(:hashed_favicon_png).where("id > ?", id).order("id ASC").limit(N_PER_PAGE)
    end

  end

  def init_from_fetcher_results
    data = fetcher.fetch
    self.attributes = fetcher.get_urls
    self.hashed_favicon_source = HashedFaviconSource.find_or_create_by_source_data(data.source_data)
    self.hashed_favicon_png = HashedFaviconPng.find_or_create_by_png_data(data.png_data)
    self
  end

  def fetcher
    return @fetcher if defined?(@fetcher)
    @fetcher = Favicon::Fetcher.new(self.query_url)
  end

  def fetch
    fetcher.fetch
  end

  def data
    Favicon::Data.new(source_data)
  end

  def source_data
    self.hashed_favicon_source.source_data
  end

  def png_data
    self.hashed_favicon_png.png_data
  end

  def tmp_file_with_source_data
    t = Tempfile.new ["favicon", ".ico"]
    t.binmode
    t.write source_data
    t.flush
    t
  end

  def tmp_file_with_png_data
    t = Tempfile.new ["favicon", ".ico"]
    t.binmode
    t.write png_data
    t.flush
    t
  end

  def favicon_data_uri
    "data:image/png;base64,#{Base64.encode64(png_data).split(/\s+/).join}"
  end

  def as_json(options = {})
    super(:only    => [ :id, :query_url,  ],
          :methods => [ :favicon_data_uri ])
  end

  def write_to_cache
    CacheLayer::FaviconSnapshot.new.set(self.id)
  end

end
