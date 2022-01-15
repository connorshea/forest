require_relative 'bear'
require_relative 'forest'
require_relative 'lumberjack'
require_relative 'tree'

# TODO: Make this an argument to the script.
SIZE = 10

forest = Forest.new(size: SIZE)

month = 1

loop do
  puts forest.pretty_inspect
  puts 'Tick!'
  forest.tick!(month)
  sleep 1
  month += 1
end
