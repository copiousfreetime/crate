#
# The recipe for integrating amalgalite into the ruby build
#
Crate::GemIntegration.new("amalgalite", "0.5.0") do |t|
  t.upstream_source  = "http://www.copiousfreetime.org/gems/gems/amalgalite-0.5.0.gem"
  t.upstream_sha1    = "df862827bbcd5b49a3249b67478ea9b2d601ac8c"
end
