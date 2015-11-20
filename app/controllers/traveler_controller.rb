class TravelerController < ApplicationController

  def index
    @traveler = Traveler.new
    @favicon_snapshots = FaviconSnapshot.get_recent_favicons
    # @favicon_snapshots = FaviconSnapshot.order("id DESC").offset(30).limit(120)
    # @favicon_snapshots = FaviconSnapshot.get_favicons_before(10000)
  end

  def favicons
  end

end
