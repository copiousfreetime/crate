#
# Crate recipe for ruby version 1.8.7-p302
#
Crate::Ruby.new( "ruby", "1.8.7-p302") do |t|
  t.depends_on( "openssl" )
  t.depends_on( "zlib" )

  t.integrates( "amalgalite" )
  t.integrates( "arrayfields" )
  t.integrates( "configuration" )

  t.upstream_source  = "ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p302.tar.gz"
  t.upstream_md5     = "f446550dfde0d8162a6ed8d5a38b3ac2"

  ENV["CPPFLAGS"]= "-I#{File.join( t.install_dir, 'usr', 'include')}"
  ENV["LDFLAGS"] = "-L#{File.join( t.install_dir, 'usr', 'lib' )}"

  def t.build
    # put the .a files from the fakeroot/usr/lib directory into the package
    # directory so the compilation can use them
    %w[ libz.a libcrypto.a libssl.a ].each do |f| 
      FileUtils.cp File.join( install_dir, "usr", "lib", f ), pkg_dir
    end 
    sh "./configure --disable-shared --prefix=#{File.join( '/', 'usr' )}"
    sh "make"
  end

  t.install_commands << "make install DESTDIR=#{t.install_dir}"

end
