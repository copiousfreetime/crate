package "ruby", "1.8.6-p114"
depend  "openssl", "0.9.8h"
depend  "zlib", "1.2.3"
source  "ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.6-p114.tar.gz"
md5     "500a9f11613d6c8ab6dcf12bec1b3ed3"

# put the .a files from the fakeroot/usr/lib directory into the package
# directory so the compilation can use them
def before_build
  %w[ libz.a libcrypto.a libssl.a ].each do |f| 
    FileUtils.cp File.join( install_dir, "usr", "lib", f ), pkg_dir, :verbose => true
  end 
end

ENV["CPPFLAGS"]= "-I#{File.join( install_dir, 'usr', 'include')}"
ENV["LDFLAGS"] = "-L#{File.join( install_dir, 'usr', 'lib' )}"
build "./configure --disable-shared --prefix=#{File.join( '/', 'usr' )}"
build "make"
build "make install DESTDIR=#{install_dir}"
