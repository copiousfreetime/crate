#
# The recipe for integrating amalgalite into the ruby build
#
Muster::GemIntegration.new("amalgalite", "0.2.2") do |t|
  t.upstream_source  = "http://gems.rubyforge.org/gems/amalgalite-0.2.2.gem"
  t.upstream_sha1    = "19de10e35fa162199a09be82cbe2b47cf1a4da55"
end
