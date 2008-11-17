class App
  def initialize
    puts "App Initialization"
  end

  def run( argv, env )
    puts "Loaded Features : "
    $LOADED_FEATURES.each do |lf|
      puts "  #{lf}"
    end

    puts
    puts "Load path : "
    $:.each do |lp|
      puts "  #{lp}"
    end

    version_dump
    show_news
    show_md5
  end

  def version_dump
    puts "OpenSSL Version : #{OpenSSL::OPENSSL_VERSION}"
    puts "zlib Version    : #{Zlib::zlib_version}"
    puts "SQLite Version  : #{Amalgalite::SQLite3::Version}"
  end

  def show_news
    require 'net/http'
    require 'rexml/document'
    puts
    puts "Ruby Lang News Feed"
    response = Net::HTTP.get_response( URI.parse( "http://www.ruby-lang.org/en/feeds/news.rss" ) )
    doc = REXML::Document.new( response.body )
    doc.root.each_element( "//rss/channel/item/title" ) do |element|
      puts " . #{element.text.to_s}"
    end
  end

  def show_md5
    require 'digest/md5'
    str = "I love ruby"
    puts "MD5 checksum of '#{str}' is : #{Digest::MD5.hexdigest( str ) }"
  end

end
