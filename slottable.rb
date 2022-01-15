# Anything that can go into a slot is a slottable.
# Mainly just here to add convenience methods for checking types.
class Slottable
  # @return [Boolean]
  def bear?
    self.class.to_s == 'Bear'
  end

  # @return [Boolean]
  def lumberjack?
    self.class.to_s == 'Lumberjack'
  end

  # Is it a tree of any type?
  # @return [Boolean]
  def any_tree?
    self.class.to_s == 'Tree'
  end

  # @return [Boolean]
  def sapling?
    self.class.to_s == 'Tree' && type == :sapling
  end

  # @return [Boolean]
  def tree?
    self.class.to_s == 'Tree' && type == :tree
  end

  # @return [Boolean]
  def elder_tree?
    self.class.to_s == 'Tree' && type == :elder_tree
  end
end
