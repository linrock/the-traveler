class Domain < ActiveRecord::Base
  validates_format_of :url, :with => /\A[\w\-]+(\.[\w\-]+)*(\.[a-z]{2,})\z/

  after_initialize :normalize_url

  def self.uncharted(n = nil)
    domains = where(:visited => false).order('id ASC')
    return domains if n.nil?
    domains.limit(n)
  end

  def visit!
    html_response = nil
    begin
      html_response = FaviconParty::HTTPClient.get(url)
      self.error_message = nil
    rescue FaviconParty::CurlError => error
      self.error_message = error.message
    end
    self.visited = true
    self.accessed = !self.error_message.present?
    self.last_visit_at = Time.now
    self.save!
    html_response
  end

  def dns_error?
    return unless error_message.present?
    ["Couldn't resolve host", "name lookup timed out"].any? do |msg|
      error_message.include? msg
    end
  end

  def normalize_url
    if self.url !~ /\Ahttps?:\/\//
      self.url = "http://#{self.url}"
    end
    self.url = URI.encode(URI.parse(url).hostname.downcase.strip) rescue nil
  end

end
