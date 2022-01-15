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

  # @attr [Integer] The current amount of total Lumber harvested this year.
  attr_accessor :lumber

  # @attr [Integer] The current amount of total Mawings for the year.
  attr_accessor :mawings

  # @attr [Hash] A hash for tracking per-tick statistics, will be reset to the
  #              default after every tick.
  attr_accessor :tick_stats

  # @param size [Integer] The width and height of the grid.
  def initialize(size:)
    @size = size
    @total_grid_size = size * size
    @grid = Array.new(size) { Array.new(size) }
    @month = 1
    @lumber = 0
    @mawings = 0
    @tick_stats = {
      new_saplings_spawned: 0,
      new_elder_trees_spawned: 0,
      newly_mawed_lumberjacks: 0,
      newly_harvested_lumber: 0
    }

    populate_grid_initially!
  end

  # Handle actions for the Slottables on each tick. We can't do this from the
  # individual classes because they don't have information about the grid.
  #
  # @return [Boolean] Whether to continue to the next tick.
  def tick!
    # Reset tick stats on every tick.
    @tick_stats = {
      new_saplings_spawned: 0,
      new_elder_trees_spawned: 0,
      newly_mawed_lumberjacks: 0,
      newly_harvested_lumber: 0
    }

    @grid.each_with_index do |row, y|
      row.each_with_index do |slottable, x|
        next if slottable.nil?

        if slottable.any_tree?
          tree_think(slottable, x, y)
        elsif slottable.lumberjack?
          lumberjack_think(slottable, x, y)
        elsif slottable.bear?
          bear_think(slottable, x, y)
        end
      end
    end

    perform_monthly_actions

    # If there are no trees left, end the simulation.
    return false if count_any_tree.zero?
    # End the simulation after 400 years.
    return false if @month > 4800

    true
  end

  # Populates the grid with bears and trees and lumberjacks.
  #
  # @return [void]
  def populate_grid_initially!
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

  # Randomly select an empty grid space to place the slottable.
  #
  # @param slottable [Slottable]
  # @return [void]
  def populate_an_empty_grid_space(slottable)
    nil_coords = []

    @grid.each_with_index do |row, y|
      row.each_with_index do |slottable, x|
        nil_coords << [x, y] if slottable.nil?
      end
    end

    if nil_coords.empty?
      puts 'ERROR: No empty grid slots.'
      return
    end

    populate(*nil_coords.sample, slottable)
  end

  # Perform a tick for a tree.
  #
  # @param tree [Tree]
  # @param x [Integer]
  # @param y [Integer]
  # @return [void]
  def tree_think(tree, x, y)
    spawn_sapling = tree.tick!

    # When the tree becomes 120 months old, it becomes an elder tree.
    # So we want to track that to output later.
    @tick_stats[:new_elder_trees_spawned] += 1 if tree.age == 120
    if spawn_sapling
      adjacent_spaces = get_adjacent_spaces(x, y)
      empty_adjacent_space = adjacent_spaces.filter { |space| space[:content].nil? }.sample

      unless empty_adjacent_space.nil?
        @tick_stats[:new_saplings_spawned] += 1
        populate(empty_adjacent_space[:coords][0], empty_adjacent_space[:coords][1], Tree.new(type: :sapling, age: 0))
      end
    end
  end

  # Perform a tick for a lumberjack.
  #
  # @param lumberjack [Lumberjack]
  # @param x [Integer]
  # @param y [Integer]
  # @return [void]
  def lumberjack_think(lumberjack, x, y)
    # Skip this Lumberjack if it's already acted on this tick.
    return if lumberjack.acted_on_current_tick?

    # Track movements so we don't go above the max movements for the lumberjack.
    movements = 0
    # Copy the current x and y so we can update it to match the location
    # of the lumberjack after each movement.
    curr_x = x
    curr_y = y

    until movements >= Lumberjack::MAX_MOVEMENT
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
      if new_space_to_move_to[:content].nil?
        populate(*new_space_to_move_to[:coords], lumberjack)
        empty_slot!(curr_x, curr_y)
        curr_x, curr_y = *new_space_to_move_to[:coords]
      end

      # Just use `any_tree?` since we've already established that it
      # can't be a sapling.
      if new_space_to_move_to[:content]&.any_tree?
        # Harvest some lumber depending on the type of tree in the slot.
        @tick_stats[:newly_harvested_lumber] += 1 if new_space_to_move_to[:content]&.tree?
        @tick_stats[:newly_harvested_lumber] += 2 if new_space_to_move_to[:content]&.elder_tree?

        # Empty the slot since we harvested the tree, then populate it
        # with the lumberjack.
        empty_slot!(*new_space_to_move_to[:coords])
        populate(*new_space_to_move_to[:coords], lumberjack)

        # Empty the original slot since we don't want the lumberjack to
        # be in that old slot anymore.
        empty_slot!(curr_x, curr_y)

        # Update the current x and current y to the new coordinates.
        curr_x, curr_y = *new_space_to_move_to[:coords]

        # Stop wandering after this.
        stop_wandering = true
      end

      # If the Lumberjack moves onto a slot with a bear, they get mawed.
      if new_space_to_move_to[:content]&.bear?
        # Empty the original slot since we don't want the lumberjack to
        # be in that old slot anymore.
        empty_slot!(curr_x, curr_y)
        # Increment the Mawing Counter™.
        @tick_stats[:newly_mawed_lumberjacks] += 1

        # If we reach zero lumberjacks because the last one was mawed,
        # spawn a new one somewhere.
        if count_lumberjacks.zero?
          populate_an_empty_grid_space(Lumberjack.new)
        end

        stop_wandering = true
      end

      # If we want to stop wandering because we've hit a tree or bear,
      # break the loop and stop wandering.
      break if stop_wandering
    end

    lumberjack.tick!
  end

  # Perform a tick for a bear.
  #
  # @param bear [Bear]
  # @param x [Integer]
  # @param y [Integer]
  # @return [void]
  def bear_think(bear, x, y)
    # Skip this Bear if it's already acted on this tick.
    return if bear.acted_on_current_tick?

    # Track movements so we don't go above the max movements for the bear.
    movements = 0
    # Copy the current x and y so we can update it to match the location
    # of the bear after each movement.
    curr_x = x
    curr_y = y

    # Do Bear stuff, mawing and whatnot.
    until movements >= Bear::MAX_MOVEMENT
      movements += 1
      stop_wandering = false

      # Get spaces which are adjacent to this bear.
      # Then filter out trees (since bears can't interact with trees)
      # and other bears (since there's no interaction between bears,
      # so we don't want them to move onto the same tile).
      adjacent_spaces = get_adjacent_spaces(curr_x, curr_y)
      new_space_to_move_to = adjacent_spaces.reject do |space|
        space[:content]&.any_tree? || space[:content]&.bear?
      end.sample

      # Just stop wandering if there's nothing to move to, since there
      # aren't any valid spaces for the bear to move to.
      break if new_space_to_move_to.nil?

      # If the new slot is nil, populate the new slot, empty the old
      # slot, and update the current x and y coords.
      if new_space_to_move_to[:content].nil?
        populate(*new_space_to_move_to[:coords], bear)
        empty_slot!(curr_x, curr_y)
        curr_x, curr_y = *new_space_to_move_to[:coords]
      end

      # If the Bear moves onto a slot with a Lumberjack, maw them.
      if new_space_to_move_to[:content]&.lumberjack?
        # Empty the original slot since we don't want the bear to
        # be in that old slot anymore.
        empty_slot!(curr_x, curr_y)

        # Empty the new slot since we don't want the lumberjack to
        # be in that slot, since they're being mawed.
        empty_slot!(*new_space_to_move_to[:coords])

        # Populate the new slot with the bear since we've mawed the
        # lumberjack. Then update the current x and current y to the
        # new coordinates.
        populate(*new_space_to_move_to[:coords], bear)
        curr_x, curr_y = *new_space_to_move_to[:coords]

        # Increment the Mawing Counter™.
        @tick_stats[:newly_mawed_lumberjacks] += 1

        # If we reach zero lumberjacks because the last one was mawed,
        # spawn a new one somewhere.
        if count_lumberjacks.zero?
          populate_an_empty_grid_space(Lumberjack.new)
        end

        stop_wandering = true
      end

      # If we want to stop wandering because we've hit a lumberjack,
      # break the loop and stop wandering.
      break if stop_wandering
    end

    bear.tick!
  end

  # Empty a slot on the grid.
  #
  # @param x [Integer]
  # @param y [Integer]
  # @param [void]
  def empty_slot!(x, y)
    raise StandardError, "This space (#{[x, y]}) is already empty!" if @grid[y][x].nil?

    puts "Emptying #{[x, y]}." if ENV['DEBUG']
    @grid[y][x] = nil
  end

  # Populate a slot on the grid with a slottable.
  #
  # @param x [Integer]
  # @param y [Integer]
  # @param slottable [Slottable] 
  # @param [void]
  def populate(x, y, slottable)
    raise StandardError, "Cannot populate a space with nil, use Forest#empty_slot! instead!" if slottable.nil?
    raise StandardError, "This space (#{[x, y]}) is already populated!" unless @grid[y][x].nil?

    puts "Populating #{[x, y]} with #{slottable.class}." if ENV['DEBUG']
    @grid[y][x] = slottable
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
  #
  # @return [Integer]
  def count_elder_trees
    @grid.flatten.compact.filter(&:elder_tree?).size
  end

  # Count the number of lumberjacks.
  #
  # @return [Integer]
  def count_lumberjacks
    @grid.flatten.compact.filter(&:lumberjack?).size
  end

  # Count the number of bears.
  #
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

    # Filter out adjacent spaces that are out of bounds.
    adjacent_spaces.reject! do |space|
      space[0] > size - 1 || space[0] < 0 || space[1] > size - 1 || space[1] < 0
    end

    adjacent_spaces.map do |x, y|
      {
        coords: [x, y],
        content: @grid[y][x].dup
      }
    end
  end

  private

  # Perform actions that need to be done every month.
  #
  # @return [void]
  def perform_monthly_actions
    # Monthly outputs.
    puts "Month [#{formatted_month_number}]: [#{@tick_stats[:new_saplings_spawned]}] new saplings created." unless @tick_stats[:new_saplings_spawned].zero?
    puts "Month [#{formatted_month_number}]: [#{@tick_stats[:new_elder_trees_spawned]}] trees became elder trees." unless @tick_stats[:new_elder_trees_spawned].zero?
    puts "Month [#{formatted_month_number}]: [#{@tick_stats[:newly_mawed_lumberjacks]}] Lumberjacks were Maw'd by bears." unless @tick_stats[:newly_mawed_lumberjacks].zero?
    puts "Month [#{formatted_month_number}]: [#{@tick_stats[:newly_harvested_lumber]}] pieces of lumber harvested by Lumberjacks." unless @tick_stats[:newly_harvested_lumber].zero?

    @mawings += @tick_stats[:newly_mawed_lumberjacks]
    @lumber += @tick_stats[:newly_harvested_lumber]

    perform_annual_actions if @month % 12 == 0
    @month += 1

    reset_actions_for_current_tick!
  end

  # Perform actions that need to be done every 12 months.
  #
  # @return [void]
  def perform_annual_actions
    puts "Year [#{formatted_year_number}]: Forest has #{count_trees} Trees, #{count_saplings} Saplings, #{count_elder_trees} Elder Trees, #{count_lumberjacks} Lumberjacks, and #{count_bears} Bears."

    # Spawn a new bear if there were no mawings this year.
    # Otherwise, pick a random bear from the grid and then have the Zoo
    # catch it.
    if @mawings.zero?
      populate_an_empty_grid_space(Bear.new)
      puts "Year [#{formatted_year_number}]: 1 new Bear added."
    else
      bear_coords = []
      @grid.each_with_index do |row, y|
        row.each_with_index do |slottable, x|
          next if slottable.nil?
          bear_coords << [x, y] if slottable.bear?
        end
      end
      empty_slot!(*bear_coords.sample)

      puts "Year [#{formatted_year_number}]: 1 Bear captured by Zoo."
    end

    # Fire a lumberjack if the lumberjacks don't harvest more lumber than
    # there are lumberjacks. Otherwise, hire new lumberjacks based on the
    # amount of lumber harvested this year.
    if @lumber < count_lumberjacks
      lumberjack_coords = []
      @grid.each_with_index do |row, y|
        row.each_with_index do |slottable, x|
          next if slottable.nil?
          lumberjack_coords << [x, y] if slottable.lumberjack?
        end
      end

      # Fire a random lumberjack unless there aren't any to fire.
      # This _probably_ shouldn't ever happen because if the last lumberjack
      # is mawed he'll be replaced immediately.
      empty_slot!(*lumberjack_coords.sample) unless lumberjack_coords.size.zero?

      # If we reach zero lumberjacks because we fired the last one, spawn a
      # new one somewhere.
      if count_lumberjacks.zero?
        populate_an_empty_grid_space(Lumberjack.new)
      end

      # We don't really care that this is inaccurate in some cases (e.g. if the last lumberjack is fired).
      puts "Year [#{formatted_year_number}]: #{@lumber} pieces of lumber harvested, 1 Lumberjack fired."
    else
      lumberjacks_hired = (@lumber / count_lumberjacks).floor
      lumberjacks_hired.times do
        populate_an_empty_grid_space(Lumberjack.new)
      end
      puts "Year [#{formatted_year_number}]: #{@lumber} pieces of lumber harvested, #{lumberjacks_hired} new Lumberjack hired."
    end

    # Each year, reset mawings and lumber to zero.
    @mawings = 0
    @lumber = 0
  end

  # Iterate through the grid and reset all lumberjacks and bears so they're no
  # longer marked as having acted.
  #
  # @return [void]
  def reset_actions_for_current_tick!
    @grid.each do |row|
      row.each do |slottable|
        next if slottable.nil?

        if slottable.lumberjack? || slottable.bear?
          slottable.acted_on_current_tick = false
        end
      end
    end
  end

  # Converts the months into a value with leading 0s (if necessary).
  #
  # @return [String]
  def formatted_month_number
    @month.to_s.rjust(4, '0')
  end

  # Converts the months into a year value with leading 0s (if necessary).
  #
  # @return [String]
  def formatted_year_number
    (@month / 12).to_s.rjust(3, '0')
  end
end
