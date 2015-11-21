class Traveler::Directions::Beanstalkd

  INPUT_TUBE = "domains_to_visit"


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
      n_skips = @n_seq_errors
      n_skips.times do
        job = @tube.reserve
        job.delete
      end
      @n_seq_errors = 0
      n_skips
    end

  end


  def initialize(traveler)
    @traveler = traveler
    @logger = traveler.logger
    @beanstalk = Beaneater.new('localhost:11300')
    @tube = @beanstalk.tubes[INPUT_TUBE]
    # @evader = ErrorEvader.new(@tube)
  end

  def add_url(url, priority = 10)
    @tube.put url, :pri => priority
  end

  def follow
    @logger.log "Following urls in Beanstalkd tube - #{@tube.name}"
    i = 0
    loop do
      job = @tube.reserve
      url = job.body
      @traveler.visit_url(url) do |error|
        add_url url, 1
      end
      job.delete
      # if (n = @evader.evade!)
      #   @logger.log "Too many sequential errors. Evading the next #{n} urls"
      # end
      i += 1
    end
  ensure
    @traveler.set_status "inactive"
    @beanstalk.close
  end

end
