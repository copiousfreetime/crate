#
# The recipe for integrating amalgalite into the ruby build
#
Crate::GemIntegration.new("amalgalite", "0.4.3") do |t|
  t.upstream_source  = "http://www.copiousfreetime.org/gems/gems/amalgalite-0.4.3.gem"
  t.upstream_sha1    = "4eb6c4ac172f874f11fe359ebe493762effbc01d"
end
