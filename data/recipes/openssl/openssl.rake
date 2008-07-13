#
# Mustard recipe for openssl
#
Mustard::Dependency.new("openssl", "0.9.8h") do |t|
  t.depends_on( "zlib" )
  t.upstream_source  = "http://www.openssl.org/source/openssl-0.9.8h.tar.gz"
  t.upstream_sha1    = "ced4f2da24a202e01ea22bef30ebc8aee274de86"

  t.build_commands = [
    "./config --prefix=#{File.join( '/', 'usr' )} zlib no-threads no-shared",
    "make"
  ]

  t.install_commands = [
    "make install_sw INSTALL_PREFIX=#{t.install_dir}" ,
    "make clean"
  ]

end

