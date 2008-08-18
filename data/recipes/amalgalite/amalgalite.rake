#
# The recipe for integrating amalgalite into the ruby build
#
Crate::GemIntegration.new("amalgalite", "0.4.0") do |t|
  t.upstream_source  = "http://www.copiousfreetime.org/gems/gems/amalgalite-0.4.0.gem"
  t.upstream_sha1    = "410ddb2e96c74ff12d8542079fcb5d7951b267e4"
end
