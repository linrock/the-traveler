class BeanstalkWatcher

  def initialize
    @beanstalk = Beaneater.new(['localhost:11300'])
    @tube = @beanstalk.tubes["favicon_urls"]
  end

  def add_url(url)
    @tube.put url
  end

  def run
    puts "Watching for urls in Beanstalkd queue"
    begin
      while (job = @tube.reserve)
        url = job.body
        puts "Checking url: #{url}"
        begin
          snapshot = FaviconSnapshot.find_or_init_with_query(url)
          snapshot.init_from_fetcher_results
          snapshot.save!
        rescue => e
          puts "Failed to fetch for #{url}"
          puts "#{e.class}: #{e.message}"
          unless ["Favicon::NotFound", "Favicon::CurlError"].include? e.class.to_s
            binding.pry
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

end
