#
# The recipe for integrating amalgalite into the ruby build
#
Mustard::GemIntegration.new("amalgalite", "0.2.2") do |t|
  t.upstream_source  = "http://www.copiousfreetime.org/gems/gems/amalgalite-0.2.2.gem"
  t.upstream_sha1    = "9885b1a44f83e88da038d454e1048559ff57975c"
end
