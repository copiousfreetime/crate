#
# Crate recipe for openssl
#
Crate::Dependency.new("openssl", "0.9.8i") do |t|
  t.depends_on( "zlib" )
  t.upstream_source  = "http://www.openssl.org/source/openssl-0.9.8i.tar.gz"
  t.upstream_sha1    = "b2e029cfb68bf32eae997d60317a40945db5a65f"

  t.build_commands = [
    "./config --prefix=#{File.join( '/', 'usr' )} zlib no-threads no-shared",
    "make"
  ]

  t.install_commands = [
    "make install_sw INSTALL_PREFIX=#{t.install_dir}" ,
    "make clean"
  ]

end

