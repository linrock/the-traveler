# The scout explores unvisited domains and finds prospective
# domains to visit in the future
#
class Scout

  LOG_FILE        = "log/scout.log"
  BEANSTALK_HOST  = "localhost:11300"
  MAX_QUEUE_SIZE  = 20000
  OUTPUT_TUBE     = "domains_to_visit"

  def initialize
    @logger = ColorizedLogger.new(LOG_FILE)
    @beanstalk = Beaneater.new(BEANSTALK_HOST)
    @tube = @beanstalk.tubes[OUTPUT_TUBE]
  end

  def process_domain(domain)
    @logger.log "Visiting - #{domain.url}"
    html = domain.visit!
    if domain.error_message
      @logger.log "Failed: #{domain.error_message}", :color => :yellow
      return
    end
    enqueue_url domain.url
    urls = find_unique_domains_in_html(html)
    save_uncharted_domains urls
  end

  def save_uncharted_domains(urls)
    i = 0
    ActiveRecord::Base.transaction do
      urls.each do |url|
        domain = Domain.find_by(:url => url)
        next if domain.present?
        Domain.create!(:url => url)
        i += 1
      end
    end
    @logger.log "Found #{i} new domains out of #{urls.length}"
  end

  def visit_uncharted_domains(n = 50)
    Domain.uncharted(n).each { |domain| process_domain(domain) }
  end

  def find_unique_domains_from_url(url)
    process_domain Domain.find_or_create_by(:url => url)
  end

  def find_unique_domains_in_html(html)
    doc = Nokogiri::HTML.parse html
    links = doc.css("a").map {|a| a.attr("href") }.
                select {|href| (href =~ /\Ahttps?:\/\//) rescue nil }.
                map    {|href| URI.parse(href).hostname.downcase.strip rescue nil }.
                compact.uniq
  end

  def status_update
    stats = "#uncharted: #{Domain.uncharted.count}, #enqueued: #{queue_size}"
    @logger.log "Status update - #{stats}", :color => :cyan
  end

  def enqueue_url(url, priority = 10)
    @tube.put url, :pri => priority
  end

  def queue_size
    @tube.stats[:current_jobs_ready]
  end

  def queue_is_fat?
    queue_size > MAX_QUEUE_SIZE
  end

  def explore!
    if Domain.uncharted.count == 0
      @logger.log "No more domains to visit. Exiting"
      exit 1
    end
    loop do
      if queue_is_fat?
        @logger.log "Taking a break - queue is pretty full (#{queue_size})"
        sleep(60)
        next
      end
      visit_uncharted_domains
      status_update
      sleep 2
    end
  ensure
    @beanstalk.close
  end

end
