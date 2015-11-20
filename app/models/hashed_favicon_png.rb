# Hashed/de-duplicated 16x16 PNG versions of the source favicons
#
class HashedFaviconPng < ActiveRecord::Base
  has_many :favicon_snapshots

  before_validation :calculate_and_set_md5_hash
  validates_format_of :md5_hash, :with => /[\da-f]{32}/
  validate :validate_png_data


  def self.find_by_png_data(data)
    find_by_md5_hash Digest::MD5.hexdigest(data)
  end

  def self.find_or_create_by_png_data(data)
    hashed_favicon_png = find_by_png_data(data)
    return hashed_favicon_png if hashed_favicon_png.present?
    create!({ :png_data => data })
  end

  def size
    png_data.size
  end

  def calculate_and_set_md5_hash
    self.md5_hash = Digest::MD5.hexdigest self.png_data
  end

  def validate_png_data
    mime_type = Favicon::Utils.get_mime_type(png_data)
    if mime_type != "image/png"
      errors.add :png_data, "mime type is invalid - #{mime_type}"
    end
  end

end
