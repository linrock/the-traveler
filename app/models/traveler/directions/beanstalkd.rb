class Traveler::Directions::Beanstalkd

  def initialize(traveler)
    @traveler = traveler
    @logger = traveler.logger
    @beanstalk = Beaneater.new('localhost:11300')
    @tube = @beanstalk.tubes["favicon_urls"]
  end

  def add_url(url, priority = 10)
    @tube.put url, :pri => priority
  end

  def follow
    @logger.log "Following urls in Beanstalkd tube - #{@tube.name}"
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
          @error_handler = Traveler::ErrorHandler.new(error)
          @logger.log "Failed to fetch for #{url}"
          @logger.error error, :log_backtrace => @error_handler.show_backtrace?
          sleep(5) if @error_handler.should_delay?
          unless @error_handler.should_ignore?
            @traveler.set_status "resting"
            state = @traveler.export_state({
              :fetcher => snapshot.fetcher,
              :error   => error
            })
            @traveler.write_state_as_fixture(state)
            binding.pry
            add_url url, 1
          end
        ensure
          snapshot = nil
        end
        job.delete
      end
    ensure
      @traveler.set_status "inactive"
      @beanstalk.close
    end
  end

end
