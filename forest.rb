require_relative 'bear'
require_relative 'lumberjack'
require_relative 'tree'
require_relative 'slottable'
require 'debug'

# It's the forest. Simple.
class Forest
  # @attr [Integer] The width/height of the grid.
  attr_reader :size

  # @attr [Integer]
  attr_reader :total_grid_size

  # @attr [Array<Array<Slottable, nil>] The grid of items, will be all nils by default.
  attr_accessor :grid

  # @attr [Integer] The current month of the simulation.
  attr_accessor :month

  # @attr [Integer] The current amount of total Lumber.
  attr_accessor :lumber

  # @param size [Integer] The width and height of the grid.
  def initialize(size:)
    @size = size
    @total_grid_size = size * size
    @grid = Array.new(size) { Array.new(size) }
    @month = 1
    @lumber = 0

    populate_grid!
  end

  # Handle tree sapling planting on each tick. We can't do this from the Tree class because it doesn't have information about the grid, unfortunately.
  # @return [Boolean] Whether to continue to the next tick.
  def tick!
    new_saplings_spawned = 0
    new_elder_trees_spawned = 0
    newly_harvested_lumber = 0

    @grid.each_with_index do |row, y|
      row.each_with_index do |slottable, x|
        next if slottable.nil?

        if slottable.any_tree?
          spawn_sapling = slottable.tick!
          # When the tree becomes 120 months old, it becomes an elder tree.
          # So we want to track that to output later.
          new_elder_trees_spawned += 1 if slottable.age == 120
          if spawn_sapling
            adjacent_spaces = get_adjacent_spaces(x, y)
            empty_adjacent_space = adjacent_spaces.filter { |space| space[:content].nil? }.sample

            unless empty_adjacent_space.nil?
              new_saplings_spawned += 1
              populate(empty_adjacent_space[:coords][0], empty_adjacent_space[:coords][1], Tree.new(type: :sapling, age: 0))
            end
          end
        elsif slottable.lumberjack?
          # Lumberjacks each month will wander. They will move up to 3 times
          # to a randomly picked spot that is adjacent in any direction. So
          # for example a Lumberjack in the middle of your grid has 8 spots
          # to move to. He will wander to a random spot. Then again. And
          # finally for a third time.
          #
          # When the lumberjack moves if he encounters a Tree (not a sapling)
          # he will stop and his wandering for that month comes to an end.
          # He will then harvest the Tree for lumber. Remove the tree. Gain
          # 1 piece of lumber. Lumberjacks will not harvest "Sapling". They
          # will harvest an Elder Tree. Elder Trees are worth 2 pieces of
          # lumber.
          #
          # Every 12 months the amount of lumber harvested is compared to the
          # number of lumberjacks in the forest. A math formula
          # is used to determine if we hire 1 or many lumberjacks. We hire a
          # number of new lumberjacks based on lumber gathered. Let us say you
          # have 10 lumberjacks. If you harvest 10-19 pieces of lumber you would
          # hire 1 lumberjack. But if you harvest 20-29 pieces of lumber you
          # would hire 2 lumberjacks. If you harvest 30-39 you would gain 3
          # lumberjacks. And so forth.
          #
          # However if after a 12 month span the amount of lumber collected
          # is below the number of lumberjacks then a lumberjack is let go
          # to save money and 1 random lumberjack is removed from the forest.
          # However you will never reduce your Lumberjack labor force below 0.

          # Track movements, Lumberjack can only have 3 at most.
          movements = 0
          # Copy the current x and y so we can update it to match the 
          curr_x = x
          curr_y = y

          until movements >= 3
            movements += 1
            stop_wandering = false

            # Get spaces which are adjacent to this lumberjack.
            # Then filter out saplings (since he can't cut those down)
            # and other lumberjacks (since there's no interaction between
            # lumberjacks, so we don't want them to move onto the same tile).
            adjacent_spaces = get_adjacent_spaces(curr_x, curr_y)
            new_space_to_move_to = adjacent_spaces.reject do |space|
              space[:content]&.sapling? || space[:content]&.lumberjack?
            end.sample

            # Just stop wandering if there's nothing to move to, since there
            # aren't any valid spaces for the lumberjack to move to.
            break if new_space_to_move_to.nil?

            # If the new slot is nil, populate the new slot, empty the old
            # slot, and update the current x and y coords.
            if new_space_to_move_to[:content]&.nil?
              populate(*new_space_to_move_to[:coords], slottable)
              puts 'foo'
              empty_slot!(curr_x, curr_y)
              curr_x, curr_y = *new_space_to_move_to[:coords]
            end

            # Just use `any_tree?` since we've already established that it
            # can't be a sapling.
            if new_space_to_move_to[:content]&.any_tree?
              # Harvest some lumber depending on the type of tree in the slot.
              newly_harvested_lumber += 1 if new_space_to_move_to[:content]&.tree?
              newly_harvested_lumber += 2 if new_space_to_move_to[:content]&.elder_tree?

              puts "Lumberjack is at #{[curr_x, curr_y]}."
              puts self.pretty_inspect
              # Empty the slot since we harvested the tree, then populate it
              # with the lumberjack.
              puts 'bar'
              puts "Emptying slot #{new_space_to_move_to[:coords]}"
              empty_slot!(*new_space_to_move_to[:coords])
              puts "Populating slot #{new_space_to_move_to[:coords]} with lumberjack"
              populate(*new_space_to_move_to[:coords], slottable)

              puts self.pretty_inspect
              # Empty the original slot since we don't want the lumberjack to be
              # in that old slot anymore.
              puts 'baz'
              puts "Emptying slot #{[curr_x, curr_y]}"
              empty_slot!(curr_x, curr_y)

              # Update the current x and current y to the new coordinates.
              curr_x, curr_y = *new_space_to_move_to[:coords]

              # Stop wandering after this.
              stop_wandering = true
            end

            if new_space_to_move_to[:content]&.bear?
              # TODO: handle what happens if the contents of the slot is a bear.
              stop_wandering = true
            end

            # If we want to stop wandering because we've hit a tree or bear,
            # break the loop and stop wandering.
            break if stop_wandering
          end

          slottable.tick!
        elsif slottable.bear?
          slottable.tick!
        end
      end
    end

    # Monthly outputs.
    puts "Month [#{@month.to_s.rjust(4, '0')}]: [#{new_saplings_spawned}] new saplings created." unless new_saplings_spawned.zero?
    puts "Month [#{@month.to_s.rjust(4, '0')}]: [#{new_elder_trees_spawned}] trees became elder trees." unless new_elder_trees_spawned.zero?

    if @month % 12 == 0
      puts "Year [#{(@month / 12).to_s.rjust(3, '0')}]: has #{count_trees} Trees, #{count_saplings} Saplings, #{count_elder_trees} Elder Trees, #{count_lumberjacks} Lumberjacks, and #{count_bears} Bears."
      # TODO: The logic for spawning bears if there are too few.
      # puts "Year [#{(@month / 12).to_s.rjust(3, '0')}]: #{num_bears_added} Bears added."
    end
    @month += 1

    # If there are no trees left, end the simulation.
    return false if count_any_tree.zero?
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

  # Recurses until it finds an empty grid space to place the slottable.
  # @param slottable [Slottable]
  # @return [void]
  def populate_an_empty_grid_space(slottable)
    loop do
      rand_num = rand(total_grid_size)
      if @grid[rand_num / size][rand_num % size].nil?
        populate(rand_num / size, rand_num % size, slottable)
        break
      end
    end
  end

  # Empty a slot on the grid.
  # @param x [Integer]
  # @param y [Integer]
  # @param [void]
  def empty_slot!(x, y)
    raise StandardError, "This space (#{[x, y]}) is already empty!" if @grid[x][y].nil?

    @grid[x][y] = nil
  end

  # @param x [Integer]
  # @param y [Integer]
  # @param slottable [Slottable, nil] 
  # @param [void]
  def populate(x, y, slottable)
    raise StandardError, "This space (#{[x, y]}) is already populated!" unless @grid[x][y].nil?

    @grid[x][y] = slottable
  end

  # Count the number of any tree type.
  # @return [Integer]
  def count_any_tree
    @grid.flatten.compact.filter(&:any_tree?).size
  end

  # Count the number of saplings.
  # @return [Integer]
  def count_saplings
    @grid.flatten.compact.filter(&:sapling?).size
  end

  # Count the number of trees.
  # @return [Integer]
  def count_trees
    @grid.flatten.compact.filter(&:tree?).size
  end

  # Count the number of elder trees.
  # @return [Integer]
  def count_elder_trees
    @grid.flatten.compact.filter(&:elder_tree?).size
  end

  # Count the number of lumberjacks.
  # @return [Integer]
  def count_lumberjacks
    @grid.flatten.compact.filter(&:lumberjack?).size
  end

  # Count the number of bears.
  # @return [Integer]
  def count_bears
    @grid.flatten.compact.filter(&:bear?).size
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
  #
  # @param x [Integer] The x coordinate.
  # @param y [Integer] The y coordinate.
  # @return [Array<Hash>] Array of hashes with coordinates and contents.
  def get_adjacent_spaces(x, y)
    adjacent_spaces = [
      [x - 1, y - 1],
      [x - 1, y],
      [x - 1, y + 1],
      [x, y - 1],
      [x, y + 1],
      [x + 1, y - 1],
      [x + 1, y],
      [x + 1, y + 1]
    ]

    adjacent_spaces.reject! do |space|
      space[0] > size - 1 || space[0] < 0 || space[1] > size - 1 || space[1] < 0
    end

    adjacent_spaces.map do |x, y|
      {
        coords: [x, y],
        content: @grid[x][y].dup
      }
    end
  end
end
