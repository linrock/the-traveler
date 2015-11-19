class TravelerController < ApplicationController

  def index
    @traveler = Traveler.new
    @favicon_snapshots = FaviconSnapshot.get_recent_favicons
    # @favicon_snapshots = FaviconSnapshot.order("id DESC").offset(30).limit(120)
    # @favicon_snapshots = FaviconSnapshot.get_favicons_before(10000)
  end

  def favicons
    @traveler = Traveler.new
    @favicon_snapshots = if params[:before_id]
                           FaviconSnapshot.get_favicons_before(params[:before_id])
                         elsif params[:after_id]
                           FaviconSnapshot.get_favicons_after(params[:after_id])
                         end
    render :json => {
      :favicons => @favicon_snapshots.map {|snapshot|
        {
          :id => snapshot.id.to_s,
          :favicon_data_uri => snapshot.favicon_data_uri,
          :query_url => snapshot.query_url
        }
      },
      :traveler => {
        :status => @traveler.status
      }
    }.to_json
  end

end
