class Traveler::ErrorHandler

  IGNORED_ERRORS = {

    Favicon::NotFound         => [""],
    Favicon::CurlError        => [""],
    Favicon::Curl::DNSError   => [""],

    Favicon::Curl::SSLError   =>
      [
        "alert handshake failure",
        "unable to get local issuer certificate",
        "SSL read: error:00000000"
      ],

    Favicon::ImageMagickError =>
      [
        "`XWD'",                           # TODO ignoring XWD file formats
        "identify: improper image header", # TODO
        'delegate failed `"dwebp"'         # TODO
      ]

  }

  def initialize(error)
    @error = error
    @class = error.class
    @message = error.message
  end

  def show_backtrace?
    return true unless @class == Favicon::NotFound
  end

  # ie. delays on DNS resolution errors to prevent huge sets of domains being
  # skipped upon laptop wakeup
  #
  def should_delay?
    @class == Favicon::Curl::DNSError
  end

  def should_ignore?
    ignored = IGNORED_ERRORS[@class]
    return false unless ignored.present?
    ignored.any? {|text| @message.include? text }
  end

end
