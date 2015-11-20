class PollingController < ActionController::Metal
  include AbstractController::Rendering
  include ActionController::Renderers::All

  def updates
    @traveler = Traveler.new
    @favicon_snapshots = if params[:after_id]
                           FaviconSnapshot.get_favicons_before(params[:after_id])
                         elsif params[:before_id]
                           FaviconSnapshot.get_favicons_after(params[:before_id])
                         end
    render :json => {
      :favicons => @favicon_snapshots,
      :traveler => {
        :status => @traveler.status
      }
    }
  end

end
