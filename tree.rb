# It's a tree.
class Tree
  # Spawn in 50% of slots.
  SPAWN_RATE = 0.5

  # @attr [Symbol] Can be a :sapling, :tree, or :elder_tree.
  attr_accessor :type

  def initialize(type:)
    @type = type
  end

  # @return [String] Return a string representing this, for rendering in a grid.
  def representation
    case type
    when :sapling
      '.'
    when :tree
      't'
    when :elder_tree
      'T'
    end
  end
end
