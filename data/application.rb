class App
  def initialize
	puts "initialized #{self.class}"
  end

  def run( argv, env )
	puts "Executing : #{$0}"
	puts "ARGV      : #{argv.join(' ')}"
	puts "ENV       :"
	env.keys.sort.each do |k|
	  puts "    #{k}  => #{env[k]}"
	end
	exit 42
  end
end

class App2 < App
  def initialize
	super
  end

  def run_me( argv, env )
	run( argv, env )
  end
end

class App3 < App
  def initialize
    super
  end
  def b
    raise NotImplementedError, "run has not been implemented"
  end

  def a
    b
  end


  def run( argv, env )
    a
  end
end

if $0 == __FILE__ then
  App3.new.run( nil, nil )
end
