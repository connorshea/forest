require_relative 'bear'
require_relative 'forest'
require_relative 'lumberjack'
require_relative 'tree'

# TODO: Make this an argument to the script.
SIZE = 10

forest = Forest.new(size: SIZE)

puts forest.pretty_inspect
