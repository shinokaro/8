class Player < Character

  attr_accessor :equipment

  def initialize(image)
    super(0, 0, image)
    self.durability = 1
    self.equipment = {}
    @diagonal_verocity_max = Math.sqrt(2)
    @diagonal_verocity = @diagonal_verocity_max / 6
    @verocity_max = 2.0
    @verocity = @verocity_max / 6
    @shot_force = 4
  end

  def alive?
    self.durability > 0
  end

  def update_input
    if Input.x.nonzero? and Input.y.nonzero?
      self.vx += Input.x * @diagonal_verocity if self.vx.abs < @diagonal_verocity_max
      self.vy += Input.y * @diagonal_verocity if self.vy.abs < @diagonal_verocity_max
    else
      self.vx += Input.x * @verocity if self.vx.abs < @verocity_max
      self.vy += Input.y * @verocity if self.vy.abs < @verocity_max
    end
  end

  def fire
    [-4, 4].map do |x|
    bullet = Bullet.new(self.x + x, centering_vertical(Assets[:shot][0]), Assets[:shot])
      bullet.collision = [7, 3, 8, 12]
      bullet.target = self.target
      bullet.vy = -@shot_force
      bullet
    end
  end

  def hit(o)
    case o
    when Enemy, Bullet
      o.vanish
      self.durability -= 1
      if self.durability < 1
        self.vanish
      end
    end
  end

  def update
    super
    self.vx *= 0.8
    self.vy *= 0.8
  end

end
