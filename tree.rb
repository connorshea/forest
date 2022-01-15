# It's a tree.
class Tree
  # Spawn in 50% of slots.
  SPAWN_RATE = 0.5

  # @attr [Symbol] Can be a :sapling, :tree, or :elder_tree.
  attr_accessor :type

  def initialize(type:)
    @type = type
  end
end
