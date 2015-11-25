class Traveler::ErrorHandler

  IGNORED_ERRORS = [
    Favicon::NotFound,
    Favicon::CurlError,
    Favicon::Curl::DNSError
  ]

  IGNORED_ERROR_STRINGS = {

    Favicon::Curl::SSLError   => [
      "alert handshake failure",
      "unable to get local issuer certificate",
      "SSL read: error:00000000"
    ],

    Favicon::ImageMagickError => [
      "`XWD'",                           # TODO ignoring XWD file formats
      "identify: improper image header", # TODO
      'delegate failed `"dwebp"',        # TODO
      "insufficient image data",         # query_url: advantage.asus.com
      "unexpected end-of-file",
      "Expected 8 bytes; found 0 bytes", # query_url: www.mytreesunshinecoast.com
      "convert: corrupt image",          # query_url: www.tinyvital.com
      "Premature end of JPEG",           # query_url: www.ciw.com.cn
    ]

  }

  IGNORED_BACKTRACES = [
    Favicon::NotFound,
    Favicon::CurlError,
    Favicon::Curl::DNSError
  ]

  def initialize(error)
    @error = error
    @class = error.class
    @message = error.message
  end

  def show_backtrace?
    return true unless IGNORED_BACKTRACES.include? @class
  end

  # ie. delays on DNS resolution errors to prevent huge sets of domains being
  # skipped upon laptop wakeup
  #
  def should_delay?
    @class == Favicon::Curl::DNSError
  end

  def should_ignore?
    return true if IGNORED_ERRORS.include? @class
    ignored_strs = IGNORED_ERROR_STRINGS[@class]
    return false unless ignored_strs.present?
    ignored_strs.any? {|str| @message.include? str }
  end

  def export_as_fixture!
    return unless @error.meta.present?
    host = URI(@error.meta[:query_url]).host
    file_path = Rails.root.join("test/fixtures/#{host}.json")
    open(file_path, "w+") do |f|
      f.write @error.to_h.to_json
    end
  end

end
