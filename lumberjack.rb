require_relative 'slottable'

# And they called him... The Tree Slayer.
class Lumberjack < Slottable
  # Spawn in 10% of slots.
  SPAWN_RATE = 0.1

  # Move a maximum of 3 times per tick.
  MAX_MOVEMENT = 3

  # @attr [Boolean] Whether the Lumberjack has acted already this tick. This
  #                 prevents us from repeatedly moving the same Lumberjack
  #                 in the same tick as we iterate through the grid.
  attr_accessor :acted_on_current_tick

  def initialize
    @acted_on_current_tick = false
  end

  def acted_on_current_tick?
    @acted_on_current_tick
  end

  # After the tick, mark the lumberjack as having acted.
  # @return [void]
  def tick!
    @acted_on_current_tick = true
  end

  # @return [String] Return a string representing this, for rendering in a grid.
  def representation
    'L'
  end
end
