#
# Muster recipe for zlib version 1.2.3
#
require 'muster/task'
Muster::Task.new( "zlib", "1.2.3") do |t|
  t.upstream_source = "http://www.zlib.net/zlib-1.2.3.tar.gz"
  t.upstream_md5    = "debc62758716a169df9f62e6ab2bc634"

  def t.build 
    system "./configure --prefix=#{File.join( '/', 'usr' )}"
  end

  def t.install
    system "make install prefix=#{File.join( install_dir, 'usr' )}"
    system "make distclean"
  end
end
