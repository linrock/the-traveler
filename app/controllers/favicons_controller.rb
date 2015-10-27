class FaviconsController < ApplicationController

  # Homepage - shows a list of recent favicons
  #
  def index
    @use_spritesheet = true
    if @use_spritesheet
      @spritesheet = Spritesheet.new
      @spritesheet.generate
    else
      set_favicon_urls
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

  def set_favicon_urls
    favicon_urls = Favicon::Cache.get_cached_favicon_urls
    hostnames = open(Rails.root.join("hostnames")).read.strip.split(/\n/)
    unless favicon_urls.present?
      favicon_urls = %w( yahoo.com quora.com google.com )
    end
    favicon_urls = (favicon_urls + hostnames).uniq
    @favicon_urls = favicon_urls.map {|url|
      "/favicons?q=#{url}"
    }
  end

end
