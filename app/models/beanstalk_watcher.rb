class BeanstalkWatcher

  class Logger

    def initialize
      @log_file = File.open(Rails.root.join("log/beanstalk.log"), "a+")
      # @error_file = File.open(Rails.root.join("log/beanstalk.log"), "a+")
    end

    def log(message)
      formatted = "[#{Time.now}] #{message}"
      puts formatted
      @log_file.write formatted + "\n"
      @log_file.flush
    end

    def error(error, options = {})
      message = "#{error.class}: #{error.message}\n"
      message = message + error.backtrace.join("\n") if options[:backtrace]
      log message
    end

  end


  def initialize
    @logger = Logger.new
    @traveler = Traveler.new
    @beanstalk = Beaneater.new(['localhost:11300'])
    @tube = @beanstalk.tubes["favicon_urls"]
  end

  def add_url(url, priority = 10)
    @tube.put url, :pri => priority
  end

  def run
    @logger.log "Watching for urls in Beanstalkd queue"
    @traveler.set_status "active"
    begin
      while (job = @tube.reserve)
        url = job.body
        @logger.log "Checking: #{url}"
        begin
          snapshot = FaviconSnapshot.find_or_init_with_query(url)
          snapshot.init_from_fetcher_results
          snapshot.save!
        rescue => error
          @logger.log "Failed to fetch for #{url}"
          @logger.error error, :backtrace => show_backtrace?(error)
          sleep(5) if should_delay?(error)
          unless should_ignore?(error)
            @traveler.set_status "paused"
            binding.pry
            @tube.put url, :pri => 0
          end
        ensure
          snapshot = nil
        end
        job.delete
      end
    ensure
      @traveler.set_status "resting"
      @beanstalk.close
    end
  end

  def show_backtrace?(error)
    return true unless error.class.to_s == "Favicon::NotFound"
  end

  # TODO delay on DNS resolution errors to prevent huge sets of domains being
  # skipped upon laptop wakeup
  #
  def should_delay?(error)
    return false unless error.class.to_s == "Favicon::CurlError"
    return true if error.message.include? "Couldn't resolve host"
  end

  def should_ignore?(error)
    klass = error.class.to_s
    msg = error.message
    return true if klass == "Favicon::NotFound"
    if klass == "Favicon::CurlError"
      return true if msg.include? "alert handshake failure"
      return true if msg.include? "unable to get local issuer certificate"
      return false if msg.include? "SSL"
      return true
    end
    if klass == "Favicon::ImageMagickError"
      return true if msg.include? "`XWD'" # TODO ignoring XWD file formats
      return true if msg.include? "identify: improper image header" # TODO
      return true if msg.include? 'delegate failed `"dwebp"' # TODO
    end
    false
  end

end
