require_relative 'bear'
require_relative 'forest'
require_relative 'lumberjack'
require_relative 'tree'

# TODO: Make this an argument to the script.
SIZE = 10

forest = Forest.new(size: SIZE)

loop do
  puts forest.pretty_inspect if ENV['DEBUG']
  puts 'Tick!' if ENV['DEBUG']
  continue = forest.tick!
  unless continue
    puts 'Ending simulation.'
    break
  end
  sleep 1
end
