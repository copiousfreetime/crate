#
# The recipe for integrating amalgalite into the ruby build
#
Crate::GemIntegration.new("amalgalite", "0.8.0") do |t|
  t.upstream_source = "http://rubyforge.org/frs/download.php/53787/amalgalite-0.8.0.gem"
  #t.upstream_sha1   = "84a84fd1192cef2d77701ec74afc8325a2a99ca7"
end
