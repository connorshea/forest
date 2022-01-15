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

  # @param size [Integer] The width and height of the grid.
  def initialize(size:)
    @size = size
    @total_grid_size = size * size
    @grid = Array.new(size) { Array.new(size) }

    populate_grid!
  end

  # Handle tree sapling planting on each tick. We can't do this from the Tree class because it doesn't have information about the grid, unfortunately.
  def tick!
    @grid.each_with_index do |row, y|
      row.each_with_index do |slot, x|
        if slot.is_a?(Tree)
          spawn_sapling = slot&.tick!
          if spawn_sapling
            adjacent_spaces = get_adjacent_spaces(x, y)
            empty_adjacent_space = adjacent_spaces.filter { |space| space[:content].nil? }.sample

            unless empty_adjacent_space.nil?
              populate(empty_adjacent_space[:coords][0], empty_adjacent_space[:coords][1], Tree.new(type: :sapling, age: 0))
            end
          end
        else
          slot&.tick!
        end
      end
    end
  end

  # Populates the grid with bears and trees and lumberjacks.
  # @return [void]
  def populate_grid!
    bears_to_spawn = (Bear::SPAWN_RATE * total_grid_size).round
    puts "Spawning #{bears_to_spawn} Bears..."
    bears_to_spawn.times do
      populate_an_empty_grid_space(Bear.new)
    end

    trees_to_spawn = (Tree::SPAWN_RATE * total_grid_size).round
    puts "Spawning #{trees_to_spawn} Trees..."
    trees_to_spawn.times do
      populate_an_empty_grid_space(Tree.new(type: :tree, age: 12))
    end

    lumberjacks_to_spawn = (Lumberjack::SPAWN_RATE * total_grid_size).round
    puts "Spawning #{lumberjacks_to_spawn} Lumberjacks..."
    lumberjacks_to_spawn.times do
      populate_an_empty_grid_space(Lumberjack.new)
    end
  end

  # Recurses until it finds an empty grid space to place the populator.
  # @param populator [Bear, Tree, Lumberjack]
  # @return [void]
  def populate_an_empty_grid_space(populator)
    loop do
      rand_num = rand(total_grid_size)
      if @grid[rand_num / size][rand_num % size].nil?
        populate(rand_num / size, rand_num % size, populator)
        break
      end
    end
  end

  # @param x [Integer]
  # @param y [Integer]
  # @param populator [Bear, Tree, Lumberjack, nil] 
  # @param [void]
  def populate(x, y, populator)
    raise StandardError, "This space is already populated!" unless @grid[x][y].nil?

    @grid[x][y] = populator
  end

  # @return [String]
  def inspect
    @grid.map do |row|
      row.map do |slot|
        slot.nil? ? ' ' : slot.representation
      end
    end.each do |row|
      row.inspect
    end
  end

  # @return [String]
  def pretty_inspect
    @grid.map do |row|
      row.map do |slot|
        slot.nil? ? ' ' : slot.representation
      end.join('')
    end.join("\n")
  end

  # Given an x and y coordinate, get the contents of the adjacent spaces.
  # TODO: There's definitely a better way to do this.
  #
  # @param x [Integer] The x coordinate.
  # @param y [Integer] The y coordinate.
  # @return [Array<Hash>] Array of hashes with coordinates and contents.
  def get_adjacent_spaces(x, y)
    adjacent_spaces = []

    if x < size - 1 && y < size - 1
      adjacent_spaces << {
        coords: [x + 1, y + 1],
        content: @grid[x + 1][y + 1]
      }
    end
    if x < size - 1 && !y.zero?
      adjacent_spaces << {
        coords: [x + 1, y - 1],
        content: @grid[x + 1][y - 1]
      }
    end
    if !x.zero? && y < size - 1
      adjacent_spaces << {
        coords: [x - 1, y + 1],
        content: @grid[x - 1][y + 1]
      }
    end
    if !x.zero? && !y.zero?
      adjacent_spaces << {
        coords: [x - 1, y - 1],
        content: @grid[x - 1][y - 1]
      }
    end

    adjacent_spaces
  end
end
