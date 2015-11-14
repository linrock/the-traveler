class TravelerController < ApplicationController

  def index
    @traveler = Traveler.new
    @favicon_snapshots = FaviconSnapshot.get_recent_favicons
  end

  def favicons
    @favicon_snapshots = if params[:before_id]
                           FaviconSnapshot.get_favicons_before(params[:before_id])
                         elsif params[:after_id]
                           FaviconSnapshot.get_favicons_after(params[:after_id])
                         end
    render :json => @favicon_snapshots.map {|snapshot|
      {
        :id => snapshot.id.to_s,
        :favicon_data_uri => snapshot.favicon_data_uri,
        :query_url => snapshot.query_url
      }
    }.to_json
  end

end
