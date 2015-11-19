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
      html_response = Favicon::HTTPClient.get(self.url)
    rescue Favicon::CurlError => error
      self.error_message = error.message
    end
    self.visited = true
    self.successful = !self.error_message.present?
    self.last_visit_at = Time.now
    self.save!
    html_response
  end

  def normalize_url
    if self.url !~ /\Ahttps?:\/\//
      self.url = "http://#{self.url}"
    end
    self.url = URI.encode(URI.parse(url).hostname.downcase)
  end

end
