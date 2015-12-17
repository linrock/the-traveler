class PollingController < ActionController::Metal
  include AbstractController::Rendering
  include ActionController::Renderers::All

  def updates
    @traveler = Traveler.new
    render :json => {
      :favicons => get_favicon_snapshots,
      :traveler => {
        :status => @traveler.status
      }
    }
  end

  private

  def get_favicon_snapshots
    if params[:after_id]
      FaviconSnapshot.get_favicons_after(params[:after_id])
    elsif params[:before_id]
      FaviconSnapshot.get_favicons_before(params[:before_id])
    end
  end

end
