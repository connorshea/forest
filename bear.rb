# 🐻
class Bear
  # Spawn in 2% of slots.
  SPAWN_RATE = 0.02

  # TODO: Do something on a tick.
  # @return [void]
  def tick!; end

  # @return [String] Return a string representing this, for rendering in a grid.
  def representation
    'B'
  end
end
