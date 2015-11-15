class Traveler

  # STATUSES = ["active", "inactive", "resting", "extended break"]

  def initialize
    set_status "initialized"
  end

  def status
    Rails.cache.read("traveler:status")
  end

  def set_status(status)
    Rails.cache.write("traveler:status", status)
  end

  def is_active?
    snapshot = FaviconSnapshot.order("id DESC").first
    snapshot.created_at > 5.minutes.ago
  end

  def status
    return "active" if is_active?
    "resting"
  end

end
