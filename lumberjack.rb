require_relative 'slottable'

# And they called him... The Tree Slayer.
class Lumberjack < Slottable
  # Spawn in 10% of slots.
  SPAWN_RATE = 0.1

  def initialize; end

  # TODO: Do something on a tick.
  # @return [void]
  def tick!; end

  # @return [String] Return a string representing this, for rendering in a grid.
  def representation
    'L'
  end
end
