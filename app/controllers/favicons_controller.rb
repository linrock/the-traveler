class FaviconsController < ApplicationController

  # Homepage - shows a list of recent favicons
  #
  def index
    @use_spritesheet = false
    if @use_spritesheet
      @spritesheet = Spritesheet.new
      @spritesheet.generate
    else
      # set_favicon_urls_from_cache
      # set_favicon_urls_from_unique_favicon_snapshots
      @favicon_snapshots = FaviconSnapshot.get_recent(params[:last_id])
      if request.xhr?
        render :json => @favicon_snapshots.map {|snapshot|
          {
            :id => snapshot.id.to_s,
            :favicon_data_uri => snapshot.favicon_data_uri,
            :query_url => snapshot.query_url
          }
        }.to_json
      end
    end
  end

  # http://localhost:3000/favicons?q=yahoo.com
  #
  def show
    url = params[:q]
    raw_image = Favicon::Accessor.new(url).get_favicon_image
    if !raw_image.nil? && raw_image.length > 0
      render :text => raw_image, :content_type => Mime::PNG
      return
    else
      render :nothing => true, :status => 404
    end
  end

  private

  def set_favicon_urls_from_cache
    favicon_urls = Favicon::Cache.get_cached_favicon_urls
    hostnames = open(Rails.root.join("hostnames")).read.strip.split(/\n/)
    unless favicon_urls.present?
      favicon_urls = %w( yahoo.com quora.com google.com )
    end
    favicon_urls = (favicon_urls + hostnames).uniq
    @favicon_urls = favicon_urls.map {|url|
      "http://localhost:8000/favicons?q=#{url}"
    }.take(160)
  end

  def set_favicon_urls_from_unique_favicon_snapshots
    s = Set.new
    @favicon_snapshots = FaviconSnapshot.order("id DESC").limit(800)
    @favicon_snapshots.to_a.delete_if do |snapshot|
      data_uri = snapshot.favicon_data_uri
      return true if s.include? data_uri
      s.add data_uri
    end
  end

end
