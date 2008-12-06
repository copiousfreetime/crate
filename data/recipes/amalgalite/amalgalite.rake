#
# The recipe for integrating amalgalite into the ruby build
#
Crate::GemIntegration.new("amalgalite", "0.5.1") do |t|
  t.upstream_source  = "http://rubyforge.org/frs/download.php/47660/amalgalite-0.5.1.gem"
  t.upstream_sha1    = "db2e7f8a766cf6a83ec5715caf02067047c74f65"
end
