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

  def serve_cached_favicons?
    params[:use_cache].present?
    false
  end

  def get_favicon_snapshots
    source = if serve_cached_favicons?
               CacheLayer::RangeQueries.new
             else
               FaviconSnapshot
             end
    if params[:after_id]
      source.get_favicons_after(params[:after_id])
    elsif params[:before_id]
      source.get_favicons_before(params[:before_id])
    end
  end

end
