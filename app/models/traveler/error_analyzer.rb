# For looking at unexpected error traces from fixtures
#
class ErrorAnalyzer

  def self.each_json_fixture(&block)
    Dir.glob(Rails.root.join("test/fixtures/*.json")).each do |fixture|
      block.call new(open(fixture).read)
    end
  end


  attr_accessor :error, :data

  def initialize(error_json)
    @error = JSON.parse(error_json, :symbolize_names => true)
  end

  def base64_data
    @error[:base64_favicon_data]
  end

  def source_data
    Base64.decode64(@error[:base64_favicon_data]) rescue nil
  end

  def data
    FaviconParty::Image.new(source_data)
  end

  def mime_type
    data.mime_type
  end

  def identify
    data.identify
  end

end
