class TravelerController < ApplicationController

  def index
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
