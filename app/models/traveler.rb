class Traveler

  # STATUSES = ["active", "resting", "inactive"]

  attr_reader :logger, :directions

  def initialize
    @logger = ColorizedLogger.new("log/traveler.log")
    @directions = nil
  end

  def status
    Rails.cache.read("traveler:status")
  end

  def set_status(status)
    Rails.cache.write("traveler:status", status)
  end

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

  def run(source = :beanstalkd)
    if source == :beanstalkd
      @directions = Directions::Beanstalkd.new(self)
      @directions.follow
    end
  end

end
