#
# The recipe for integrating amalgalite into the ruby build
#
Crate::GemIntegration.new("amalgalite", "0.5.0") do |t|
  t.upstream_source  = "http://www.copiousfreetime.org/gems/gems/amalgalite-0.5.0.gem"
  t.upstream_sha1    = "116f4c5c18576fb1df57f1f9faaec4f0015400a9"
end
