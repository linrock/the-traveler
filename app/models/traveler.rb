# The Traveler visits domains and attempts to save their favicons
#
class Traveler

  STATUSES = ["active", "resting", "inactive"]

  attr_accessor :directions
  attr_reader :logger

  def initialize
    @directions = nil
    @logger = ColorizedLogger.new("log/traveler.log")
  end

  def status
    Rails.cache.read("traveler:status")
  end

  def set_status(status)
    return unless STATUSES.include? status
    Rails.cache.write("traveler:status", status)
  end

  def visit_url(url, debug = Rails.env.development?)
    @logger.log "Visiting - #{url}"
    set_status "active"
    begin
      snapshot = FaviconSnapshot.find_or_init_with_query(url)
      snapshot.init_from_fetcher_results
      if snapshot.save!
        success_str = "Found #{snapshot.favicon_url} (#{snapshot.data.info_str})"
        @logger.log success_str, :color => :cyan
      end
      true
    rescue => error
      error_handler = Traveler::ErrorHandler.new(error)
      @logger.error error, :log_backtrace => error_handler.show_backtrace?
      # @evader.track_index i
      sleep(5) if error_handler.should_delay?
      return if error_handler.should_ignore?
      error_handler.export_as_fixture!
      if debug
        set_status "resting"
        binding.pry
        yield error if block_given?
      end
      false
    end
  end

  def run
    @directions ||= BeanstalkFollower.new(self)
    @directions.follow
  end

end
