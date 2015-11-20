module Favicon

  class CurlError < StandardError; end

  module Curl
    class DNSError < CurlError; end
    class SSLError < CurlError; end
  end

  class NotFound < StandardError; end
  class ImageMagickError < StandardError; end
  class InvalidData < StandardError; end

end
