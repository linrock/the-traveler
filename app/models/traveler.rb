class Traveler

  # STATUSES = ["active", "inactive", "resting", "extended break"]

  def initialize
    @logger = Traveler::Logger.new
    @beanstalk = Beaneater.new(['localhost:11300'])
    @tube = @beanstalk.tubes["favicon_urls"]
  end

  def status
    Rails.cache.read("traveler:status")
  end

  def set_status(status)
    Rails.cache.write("traveler:status", status)
  end

  def is_active?
    snapshot = FaviconSnapshot.order("id DESC").first
    snapshot.created_at > 5.minutes.ago
  end

  def status
    return "active" if is_active?
    "resting"
  end

  def add_url(url, priority = 10)
    @tube.put url, :pri => priority
  end

  def run
    @logger.log "Watching for urls in Beanstalkd queue"
    set_status "active"
    begin
      while (job = @tube.reserve)
        url = job.body
        @logger.log "Checking: #{url}"
        begin
          snapshot = FaviconSnapshot.find_or_init_with_query(url)
          snapshot.init_from_fetcher_results
          snapshot.save!
        rescue => error
          @error_handler = Traveler::ErrorHandler.new(error)
          @logger.log "Failed to fetch for #{url}"
          @logger.error error, :backtrace => @error_handler.show_backtrace?
          sleep(5) if @error_handler.should_delay?
          unless @error_handler.should_ignore?
            set_status "paused"
            binding.pry
            @tube.put url, :pri => 0
          end
        ensure
          snapshot = nil
        end
        job.delete
      end
    ensure
      set_status "resting"
      @beanstalk.close
    end
  end

end
