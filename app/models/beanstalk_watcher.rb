class BeanstalkWatcher

  class Logger

    def initialize
      @logfile = File.open(Rails.root.join("log/beanstalk.log"), "a+")
    end

    def log(message)
      formatted = "[#{Time.now}] #{message}"
      puts formatted
      @logfile.write formatted + "\n"
      @logfile.flush
    end

    def error(error, options = {})
      message = "#{error.class}: #{error.message}\n"
      message = message + error.backtrace.join("\n") if options[:backtrace]
      log message
    end

  end


  def initialize
    @logger = Logger.new
    @beanstalk = Beaneater.new(['localhost:11300'])
    @tube = @beanstalk.tubes["favicon_urls"]
  end

  def add_url(url, priority = 10)
    @tube.put url, :pri => priority
  end

  def run
    @logger.log "Watching for urls in Beanstalkd queue"
    begin
      while (job = @tube.reserve)
        url = job.body
        @logger.log "Checking url: #{url}"
        begin
          snapshot = FaviconSnapshot.find_or_init_with_query(url)
          snapshot.init_from_fetcher_results
          snapshot.save!
        rescue => error
          @logger.log "Failed to fetch for #{url}"
          @logger.error error, :backtrace => should_show_backtrace?(error)
          unless should_ignore?(error)
            binding.pry
            @tube.put url, :pri => 0
          end
        ensure
          snapshot = nil
        end
        job.delete
      end
    ensure
      @beanstalk.close
    end
  end

  def should_show_backtrace?(error)
    return true unless error.class.to_s == "Favicon::NotFound"
  end

  def should_ignore?(error)
    klass = error.class.to_s
    msg = error.message
    return true if klass == "Favicon::NotFound"
    if klass == "Favicon::CurlError"
      return false if msg.include? "SSL"
      return true
    end
    return true if msg.include? "`XWD'" # TODO ignoring XWD file formats
    return true if msg.include? "identify: improper image header" # TODO
    false
  end

end
