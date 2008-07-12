#
# Muster recipe for openssl
#
Muster::Task.new("openssl", "0.9.8h") do |t|
  t.depends_on( "zlib" )
  t.upstream_source  = "http://www.openssl.org/source/openssl-0.9.8h.tar.gz"
  t.upstream_sha1    = "ced4f2da24a202e01ea22bef30ebc8aee274de86"

  def t.build
    system "./config --prefix=#{File.join( '/', 'usr' )} zlib no-threads no-shared no-kb5"
    system "make depend"
    system "make"

  end

  def t.install
    system "make install_sw INSTALL_PREFIX=#{install_dir}"
    system "make clean"
  end

end

