class TravelerController < ApplicationController

  def index
    @traveler = Traveler.new
    @favicon_snapshots = FaviconSnapshot.offset(5).get_recent_favicons
    @ids = [ @favicon_snapshots.first ? @favicon_snapshots.first.id : 0 ,
             @favicon_snapshots.last  ? @favicon_snapshots.last.id  : 0 ]
    # @favicon_snapshots = FaviconSnapshot.order("id DESC").offset(30).limit(120)
    # @favicon_snapshots = FaviconSnapshot.get_favicons_before(10000)
  end

end
