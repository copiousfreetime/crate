#
# The recipe for integrating amalgalite into the ruby build
#
Crate::GemIntegration.new("amalgalite", "0.2.4") do |t|
  t.upstream_source  = "http://www.copiousfreetime.org/gems/gems/amalgalite-0.2.4.gem"
  t.upstream_sha1    = "66eb4acb03092680c50d78ff2b8ef92346befba8"
end
