#
# The recipe for integrating amalgalite into the ruby build
#
Crate::GemIntegration.new("amalgalite", "0.5.0") do |t|
  t.upstream_source  = "http://www.copiousfreetime.org/gems/gems/amalgalite-0.5.0.gem"
  t.upstream_sha1    = "87f7d221dbcb0290c559e3823b9a6db1c8e66b94"
end
