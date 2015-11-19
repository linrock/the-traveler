class FaviconSnapshot < ActiveRecord::Base
  extend Favicon::Utils

  validates_format_of :query_url, :with => /\Ahttps?:\/\//
  validates_format_of :final_url, :with => /\Ahttps?:\/\//
  validates_format_of :favicon_url, :with => /\A(https?:\/\/|data:)/
  validates_presence_of :hashed_favicon_png
  validate :validate_raw_data

  belongs_to :hashed_favicon_png

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

    def get_recent_favicons
      includes(:hashed_favicon_png).order("id DESC").limit(120)
    end

    def get_favicons_before(id)
      includes(:hashed_favicon_png).where("id < ?", id).order("id DESC").limit(120)
    end

    def get_favicons_after(id)
      includes(:hashed_favicon_png).where("id > ?", id).order("id DESC").limit(120)
    end

  end

  def init_from_fetcher_results
    data = fetcher.fetch
    self.attributes = fetcher.get_urls
    self.raw_data = data.raw_data
    self.hashed_favicon_png = HashedFaviconPng.find_or_create_by_png_data(data.png_data)
    self
  end

  def fetcher
    return @fetcher if defined?(@fetcher)
    @fetcher = Favicon::Fetcher.new(self.query_url)
  end

  def data
    Favicon::Data.new(raw_data)
  end

  def png_data
    self.hashed_favicon_png.png_data
  end

  def favicon_data_uri
    "data:image/png;base64,#{Base64.encode64(png_data).split(/\s+/).join}"
  end

  def tmp_file_with_raw_data
    t = Tempfile.new ["favicon", ".ico"]
    t.binmode
    t.write raw_data
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

  def validate_raw_data
    unless Favicon::Data.new(raw_data).valid?
      errors.add :raw_data, "is invalid"
    end
  end

end
