class FaviconsController < ApplicationController

  def index
    favicon_urls = Favicon::Cache.get_cached_favicon_urls
    unless favicon_urls.present?
      favicon_urls = %w( yahoo.com quora.com google.com )
    end
    @favicon_urls = favicon_urls.map {|url|
      "http://localhost:3000/favicons?q=#{url}"
    }
  end

  # http://localhost:3000/favicons?q=yahoo.com
  #
  def show
    url = params[:q]
    raw_image = Favicon::Accessor.new(url).get_favicon

    if !raw_image.nil? && raw_image.length > 0
      render :text => raw_image, :content_type => Mime::PNG
      return
    end
  end

end
