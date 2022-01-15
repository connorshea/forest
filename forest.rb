require_relative 'bear'
require_relative 'lumberjack'
require_relative 'tree'
require 'debug'

# It's the forest. Simple.
class Forest
  # @attr [Integer] The width/height of the grid.
  attr_reader :size

  # @attr [Integer]
  attr_reader :total_grid_size

  # @attr [Array<Array<Bear, Tree, Lumberjack, nil>] The grid of items, will be all nils by default.
  attr_accessor :grid

  def initialize(size:)
    @size = size
    @total_grid_size = size * size
    @grid = Array.new(size) { Array.new(size) }

    populate_grid
  end

  # Populates the grid with stuff.
  def populate_grid
    bears_to_spawn = (Bear::SPAWN_RATE * total_grid_size).round
    puts "Spawning #{bears_to_spawn} Bears..."
    bears_to_spawn.times do
      populate_an_empty_grid_space(Bear.new)
    end

    trees_to_spawn = (Tree::SPAWN_RATE * total_grid_size).round
    puts "Spawning #{trees_to_spawn} Trees..."
    trees_to_spawn.times do
      populate_an_empty_grid_space(Tree.new(type: :tree))
    end

    lumberjack_to_spawn = (Lumberjack::SPAWN_RATE * total_grid_size).round
    puts "Spawning #{lumberjack_to_spawn} Lumberjacks..."
    lumberjack_to_spawn.times do
      populate_an_empty_grid_space(Lumberjack.new)
    end
  end

  # Recurses until it finds an empty grid space to place the populator.
  # @param populator [Bear, Tree, Lumberjack]
  # @return [void]
  def populate_an_empty_grid_space(populator)
    loop do
      rand_num = rand(total_grid_size)
      # puts populator.class
      # puts "random num: #{rand_num}"
      # puts "size: #{size}"
      # puts "grid[#{rand_num / size}][#{rand_num % size}]"
      if grid[rand_num / size][rand_num % size].nil?
        # puts 'nil on the grid!'
        grid[rand_num / size][rand_num % size] = populator
        break
      end
    end
  end

  def inspect
    grid.map do |row|
      row.map do |slot|
        slot.nil? ? ' ' : slot.representation
      end
    end.each do |row|
      row.inspect
    end
  end

  def pretty_inspect
    grid.map do |row|
      row.map do |slot|
        slot.nil? ? ' ' : slot.representation
      end.join('')
    end.join("\n")
  end
end
