class Traveler

  # STATUSES = ["active", "resting", "inactive"]

  attr_reader :logger, :directions

  def initialize
    @logger = Traveler::Logger.new
    @directions = nil
  end

  def status
    Rails.cache.read("traveler:status")
  end

  def set_status(status)
    Rails.cache.write("traveler:status", status)
  end

  # def is_active?
  #   snapshot = FaviconSnapshot.order("id DESC").first
  #   snapshot.created_at > 30.seconds.ago
  # end

  # def status
  #   return "active" if is_active?
  #   "resting"
  # end

  def export_state(options = {})
    state = {}
    if (fetcher = options[:fetcher]).present?
      state.merge! fetcher.get_urls
      if fetcher.has_data?
        state[:base64_favicon_data] = fetcher.data.base64_raw_data
      end
    end
    if (error = options[:error]).present?
      state.merge!({
        :error_class   => error.class,
        :error_message => error.message
      })
    end
    state
  end

  def write_state_as_fixture(state)
    host = URI(state[:query_url]).host
    file_path = Rails.root.join("test/fixtures/#{host}.json")
    open(file_path, "w+") do |f|
      f.write state.to_json
    end
  end

  def add_url(url, priority = 10)
    @tube.put url, :pri => priority
  end

  def run(source = :beanstalkd)
    if source == :beanstalkd
      @directions = Directions::Beanstalkd.new(self)
      @logger.log "Watching for urls in Beanstalkd queue"
      @directions.follow
    end
  end

end
