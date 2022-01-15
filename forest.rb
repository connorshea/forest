require 'bear'
require 'lumberjack'
require 'tree'

# It's the forest. Simple.
class Forest
  # @attr [Integer] The width/height of the grid.
  attr_reader :size
  # @attr [Array<Array<Bear, Tree, Lumberjack, nil>] The grid of items, will be all nils by default.
  attr_accessor :grid
  # @attr [Integer]
  attr_reader :total_grid_size

  def initialize(size:)
    @size = size
    @total_grid_size = size * size
    @grid = Array.new(size, Array.new(size))
  end

  # Populates the grid with stuff.
  def populate_grid
    bears_to_spawn = (Bear.SPAWN_RATE * total_grid_size).round
    bears_to_spawn.times do
      populate_an_empty_grid_space(Bear.new)
    end

    trees_to_spawn = (Tree.SPAWN_RATE * total_grid_size).round
    trees_to_spawn.times do
      populate_an_empty_grid_space(Tree.new(type: :tree))
    end

    lumberjack_to_spawn = (Lumberjack.SPAWN_RATE * total_grid_size).round
    lumberjack_to_spawn.times do
      populate_an_empty_grid_space(Lumberjack.new)
    end
  end

  # Recurses until it finds an empty grid space.
  def populate_an_empty_grid_space(populator)
    rand_num = rand(total_grid_size)

    # TODO: does rand_num % size get the correct value here?
    if grid[rand_num / size][rand_num % size].nil?
      grid[rand_num / size][rand_num % size] = populator
    else
      populate_grid_space(populator)
    end
  end
end
