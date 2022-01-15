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

  # @attr [Integer] The current month of the simulation.
  attr_accessor :month

  # @param size [Integer] The width and height of the grid.
  def initialize(size:)
    @size = size
    @total_grid_size = size * size
    @grid = Array.new(size) { Array.new(size) }
    @month = 1

    populate_grid!
  end

  # Handle tree sapling planting on each tick. We can't do this from the Tree class because it doesn't have information about the grid, unfortunately.
  # @return [Boolean] Whether to continue to the next tick.
  def tick!
    new_saplings_spawned = 0
    new_elder_trees_spawned = 0

    @grid.each_with_index do |row, y|
      row.each_with_index do |slot, x|
        if slot.is_a?(Tree)
          spawn_sapling = slot&.tick!
          # When the tree becomes 120 months old, it becomes an elder tree.
          # So we want to track that to output later.
          new_elder_trees_spawned += 1 if slot.age == 120
          if spawn_sapling
            adjacent_spaces = get_adjacent_spaces(x, y)
            empty_adjacent_space = adjacent_spaces.filter { |space| space[:content].nil? }.sample

            unless empty_adjacent_space.nil?
              new_saplings_spawned += 1
              populate(empty_adjacent_space[:coords][0], empty_adjacent_space[:coords][1], Tree.new(type: :sapling, age: 0))
            end
          end
        else
          slot&.tick!
        end
      end
    end

    # Monthly outputs.
    puts "Month [#{@month.to_s.rjust(4, '0')}]: [#{new_saplings_spawned}] new saplings created." unless new_saplings_spawned.zero?
    puts "Month [#{@month.to_s.rjust(4, '0')}]: [#{new_elder_trees_spawned}] trees became elder trees." unless new_elder_trees_spawned.zero?

    if @month % 12 == 0
      flat_grid = @grid.flatten

      trees = flat_grid.filter { |slot| slot.is_a?(Tree) && slot.type == :tree }.size
      saplings = flat_grid.filter { |slot| slot.is_a?(Tree) && slot.type == :sapling }.size
      elder_trees = flat_grid.filter { |slot| slot.is_a?(Tree) && slot.type == :elder_tree }.size
      lumberjacks = flat_grid.filter { |slot| slot.is_a?(Lumberjack) }.size
      bears = flat_grid.filter { |slot| slot.is_a?(Bear) }.size

      puts "Year [#{(@month / 12).to_s.rjust(3, '0')}]: has #{trees} Trees, #{saplings} Saplings, #{elder_trees} Elder Trees, #{lumberjacks} Lumberjacks, and #{bears} Bears."
      # TODO: The logic for spawning bears if there are too few.
      # puts "Year [#{(@month / 12).to_s.rjust(3, '0')}]: #{num_bears_added} Bears added."
    end
    @month += 1

    # If there are no trees left, end the simulation.
    return false unless @grid.flatten.map(&:class).uniq.include?(Tree)
    # End the simulation after 400 years.
    return false if @month > 4800

    true
  end

  # Populates the grid with bears and trees and lumberjacks.
  # @return [void]
  def populate_grid!
    bears_to_spawn = (Bear::SPAWN_RATE * total_grid_size).round
    puts "Spawning #{bears_to_spawn} Bears..." if ENV['DEBUG']
    bears_to_spawn.times do
      populate_an_empty_grid_space(Bear.new)
    end

    trees_to_spawn = (Tree::SPAWN_RATE * total_grid_size).round
    puts "Spawning #{trees_to_spawn} Trees..." if ENV['DEBUG']
    trees_to_spawn.times do
      populate_an_empty_grid_space(Tree.new(type: :tree, age: 12))
    end

    lumberjacks_to_spawn = (Lumberjack::SPAWN_RATE * total_grid_size).round
    puts "Spawning #{lumberjacks_to_spawn} Lumberjacks..." if ENV['DEBUG']
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
