require_relative 'bear'
require_relative 'forest'
require_relative 'lumberjack'
require_relative 'tree'

# TODO: Make this an argument to the script.
SIZE = 10

forest = Forest.new(size: SIZE)

loop do
  puts forest.pretty_inspect if ENV['DEBUG'] || ENV['DISPLAY_FOREST']
  puts 'Tick!' if ENV['DEBUG']
  continue = forest.tick!
  unless continue
    if forest.month >= 4800
      puts 'COMPLETE: We have simulated 400 years.'
    else
      puts 'COMPLETE: There are no trees left.'
    end
    break
  end
  # Commented out since we want to see the full script run and there's no
  # reason to limit the speed anymore.
  # sleep 0.1
end
