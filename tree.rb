# It's a tree.
class Tree
  # Spawn in 50% of slots.
  SPAWN_RATE = 0.5

  # @attr [Symbol] Can be a :sapling, :tree, or :elder_tree.
  attr_accessor :type

  # @attr [Integer] The number of tick since the tree spawned.
  attr_accessor :age

  def initialize(type:, age:)
    @type = type
    @age = age
  end

  # On a tick, age the tree by 1 tick.
  # @return [void]
  def tick!
    @age += 1

    if @type != :elder_tree
      if @age > 120 && @type == :tree
        @type = :elder_tree
      elsif @age > 12 && @type == :sapling
        @type = :tree
      end
    end
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
