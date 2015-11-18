class Traveler::Directions::Beanstalkd

  # Tracks # sequential errors to determine how many
  # urls to be skipped
  #
  class ErrorEvader

    THRESHOLD = 10

    attr_accessor :n_seq_errors

    def initialize(tube)
      @tube = tube
      @n_seq_errors = 0
      @i = -99
    end

    def track_index(i)
      @n_seq_errors = 0 if i - @i > 1
      @n_seq_errors += 1
      @i = i
    end

    def should_evade?
      @n_seq_errors >= THRESHOLD
    end

    def evade!
      return unless should_evade?
      @n_seq_errors.times do |i|
        job = @tube.reserve
        job.delete
      end
      THRESHOLD
    end

  end


  def initialize(traveler)
    @traveler = traveler
    @logger = traveler.logger
    @beanstalk = Beaneater.new('localhost:11300')
    @tube = @beanstalk.tubes["favicon_urls"]
    @evader = ErrorEvader.new(@tube)
  end

  def add_url(url, priority = 10)
    @tube.put url, :pri => priority
  end

  def follow
    @logger.log "Following urls in Beanstalkd tube - #{@tube.name}"
    @traveler.set_status "active"
    i = 0
    loop do
      job = @tube.reserve
      url = job.body
      @logger.log "Checking: #{url}"
      begin
        snapshot = FaviconSnapshot.find_or_init_with_query(url)
        snapshot.init_from_fetcher_results
        snapshot.save!
      rescue => error
        error_handler = Traveler::ErrorHandler.new(error)
        @logger.log "Failed to fetch for #{url}"
        @logger.error error, :log_backtrace => error_handler.show_backtrace?
        @evader.track_index i
        sleep(5) if error_handler.should_delay?
        unless error_handler.should_ignore?
          @traveler.set_status "resting"
          state = @traveler.export_state({
            :fetcher => snapshot.fetcher,
            :error   => error
          })
          @traveler.write_state_as_fixture(state)
          binding.pry
          add_url url, 1
        end
        @traveler.set_status "active"
      ensure
        snapshot = nil
      end
      job.delete
      if (n = @evader.evade!)
        @logger.log "Too many sequential errors. Evading the next #{n} urls"
      end
      i += 1
    end
  ensure
    @traveler.set_status "inactive"
    @beanstalk.close
  end

end
