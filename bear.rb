require_relative 'slottable'

# 🐻
class Bear < Slottable
  # Spawn in 2% of slots.
  SPAWN_RATE = 0.02

  # @attr [Boolean] Whether the Bear has acted already this tick. This
  #                 prevents us from repeatedly moving the same Bear
  #                 in the same tick as we iterate through the grid.
  attr_accessor :acted_on_current_tick

  def initialize
    @acted_on_current_tick = false
  end

  def acted_on_current_tick?
    @acted_on_current_tick
  end

  # After the tick, mark the bear as having acted.
  # @return [void]
  def tick!
    @acted_on_current_tick = true
  end

  # @return [String] Return a string representing this, for rendering in a grid.
  def representation
    'B'
  end
end
