class Traveler

  STATUSES = ["active", "inactive", "resting", "extended break"]

  def initialize
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
