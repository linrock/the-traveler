class Traveler::ErrorHandler

  def initialize(error)
    @error = error
    @class = error.class.to_s
    @message = error.message
  end

  def show_backtrace?
    return true unless @class == "Favicon::NotFound"
  end

  # ie. delays on DNS resolution errors to prevent huge sets of domains being
  # skipped upon laptop wakeup
  #
  def should_delay?
    return false unless @class == "Favicon::CurlError"
    return true if @message.include? "Couldn't resolve host"
  end

  def should_ignore?
    return true if @class == "Favicon::NotFound"
    if @class == "Favicon::CurlError"
      return true if @message.include? "alert handshake failure"
      return true if @message.include? "unable to get local issuer certificate"
      return false if @message.include? "SSL"
      return true
    end
    if @class == "Favicon::ImageMagickError"
      return true if @message.include? "`XWD'" # TODO ignoring XWD file formats
      return true if @message.include? "identify: improper image header" # TODO
      return true if @message.include? 'delegate failed `"dwebp"' # TODO
    end
    false
  end

end
