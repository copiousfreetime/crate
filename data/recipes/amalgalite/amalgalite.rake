#
# The recipe for integrating amalgalite into the ruby build
#
Crate::GemIntegration.new("amalgalite", "0.4.3") do |t|
  t.upstream_source  = "http://www.copiousfreetime.org/gems/gems/amalgalite-0.4.3.gem"
  t.upstream_sha1    = "569c497f56bfe95d6a7abe4834f5372394857b5a"
end
