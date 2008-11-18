#
# The recipe for integrating amalgalite into the ruby build
#
Crate::GemIntegration.new("amalgalite", "0.5.0") do |t|
  t.upstream_source  = "http://rubyforge.org/frs/download.php/46874/amalgalite-0.5.0.gem"
  t.upstream_sha1    = "3dbbc86b490cfb9c8da98378e4751f3c177794be"
end
