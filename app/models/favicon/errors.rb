module Favicon

  module Curl; end
  class CurlError < StandardError; end
  class Curl::DNSError < CurlError; end
  class Curl::SSLError < CurlError; end

  class NotFound < StandardError; end
  class ImageMagickError < StandardError; end
  class InvalidData < StandardError; end

end
