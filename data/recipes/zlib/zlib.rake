#
# Crate recipe for zlib version 1.2.5
#
Crate::Dependency.new( "zlib", "1.2.5") do |t|
  t.upstream_source = "http://www.zlib.net/zlib-1.2.5.tar.gz"
  t.upstream_md5    = "c735eab2d659a96e5a594c9e8541ad63"

  t.build_commands << "./configure --prefix=#{File.join( '/', 'usr' )}"

  t.install_commands = [
    "make install prefix=#{File.join( t.install_dir, 'usr' )}",
    "make distclean"
  ]

end

