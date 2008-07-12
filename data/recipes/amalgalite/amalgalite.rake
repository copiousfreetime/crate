#
# The recipe for integrating amalgalite into the ruby build
#
Muster::GemIntegration.new("amalgalite", "0.2.1") do |t|
  t.upstream_source  = "http://gems.rubyforge.org/gems/amalgalite-0.2.1.gem"
  t.upstream_sha1    = "907063ddfd0822eeefcf3b6b6560ee402f13ea94"
end
