#
# The recipe for integrating amalgalite into the ruby build
#
Crate::GemIntegration.new("amalgalite", "0.7.1") do |t|
  t.upstream_source = "http://rubyforge.org/frs/download.php/50375/amalgalite-0.7.1.gem"
  t.upstream_sha1   = "712200229c5d151e8a7cb9407466e879adb79147"
end
