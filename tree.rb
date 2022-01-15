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
  # Also check whether we can spawn a new sapling in an adjacent slot, and
  # return a boolean for whether to spawn one.
  # @return [Boolean]
  def tick!
    @age += 1

    if @type != :elder_tree
      if @age >= 120 && @type == :tree
        @type = :elder_tree
      elsif @age >= 12 && @type == :sapling
        @type = :tree
      end
    end

    # Return false if the tree is a sapling, since it can't spawn other saplings.
    return false if @type == :sapling

    rand_num = rand(100)

    # If an elder_tree, 20% chance to spawn a sapling in an adjacent slot.
    # If a tree, 10% chance to spawn a sapling in an adjacent slot.
    if (@type == :elder_tree && rand_num <= 20) || (@type == :tree && rand_num <= 10)
      true
    else
      false
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
