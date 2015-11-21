# rails runner

most_recent_id = FaviconSnapshot.most_recent.id

# Sanity check
#
cached_favicons = FaviconSnapshot::Cache.new.get_favicons_before(most_recent_id)
favicons = FaviconSnapshot.get_favicons_before(most_recent_id)

if cached_favicons.to_json != favicons.to_json
  raise "cached_favicons != favicons (#{most_recent_id})"
end

# Time it takes to run the same query in memcached vs postgres
#
t0 = Time.now
1.times { FaviconSnapshot.get_favicons_before(most_recent_id).to_json }
puts "#{Time.now - t0}s - db query for get_favicons_before"

t0 = Time.now
1.times { FaviconSnapshot::Cache.new.get_favicons_before(most_recent_id).to_json }
puts "#{Time.now - t0}s - cache query for get_favicons_before"

t0 = Time.now
100.times { FaviconSnapshot.get_favicons_before(most_recent_id).to_json }
puts "#{Time.now - t0}s - db query for get_favicons_before"

t0 = Time.now
100.times { FaviconSnapshot::Cache.new.get_favicons_before(most_recent_id).to_json }
puts "#{Time.now - t0}s - cache query for get_favicons_before"
