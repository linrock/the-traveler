# Hashed/de-duplicated favicon source data
#
class HashedFaviconSource < ActiveRecord::Base
  has_many :favicon_snapshots

  before_validation :calculate_and_set_md5_hash
  validates_format_of :md5_hash, :with => /[\da-f]{32}/
  validate :validate_source_data

  MAX_FILE_SIZE = 1024 * 1024


  def self.find_by_source_data(data)
    find_by_md5_hash Digest::MD5.hexdigest(data)
  end

  def self.find_or_create_by_source_data(data)
    hashed_favicon_source = find_by_source_data(data)
    return hashed_favicon_source if hashed_favicon_source.present?
    create!({ :source_data => data })
  end

  def size
    source_data.size
  end

  def calculate_and_set_md5_hash
    self.md5_hash = Digest::MD5.hexdigest self.source_data
  end

  def validate_source_data
    unless FaviconParty::Image.new(source_data).valid?
      errors.add :source_data, "is invalid"
    end
    unless size <= MAX_FILE_SIZE
      errors.add :source_data, "is too big"
    end
  end

end
