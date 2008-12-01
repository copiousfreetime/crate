#
# The recipe for integrating amalgalite into the ruby build
#
Crate::GemIntegration.new("amalgalite", "0.5.1") do |t|
  t.upstream_source  = "http://rubyforge.org/frs/download.php/47660/amalgalite-0.5.1.gem"
  t.upstream_sha1    = "fca93f2ab3abf46c86e78202d46489f25b7acb33"
end
