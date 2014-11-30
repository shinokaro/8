class Gun

  extend Forwardable

  def_delegators :@owner, :x, :y, :target, :angle, :centering_vertical, :centering_horizontal

  def initialize(owner)
    @owner = owner
  end

end

class SingleGun < Gun

  def fire(player)
    bullet = Bullet.new(self.x, self.centering_vertical(Assets[:bullet][0]), Assets[:bullet])
    bullet.collision = [3, 3, 12, 12]
    bullet.target = self.target
    self.angle(player.x, player.y).tap do |deg|
      bullet.vx = 1.2 * Math.cos(deg/180*Math::PI)
      bullet.vy = 1.2 * Math.sin(deg/180*Math::PI)
    end
    bullet
  end

end

class TwoWayGun < Gun

  def fire(player)
    [-1, 1].map do |i|
      bullet = Bullet.new(self.x, centering_vertical(Assets[:bullet][0]), Assets[:bullet])
      bullet.collision = [3, 3, 12, 12]
      bullet.target = self.target
      self.angle(player.x, player.y).tap do |deg|
        bullet.vx = 1.2 * Math.cos((deg+30*i)/180*Math::PI)
        bullet.vy = 1.2 * Math.sin((deg+30*i)/180*Math::PI)
      end
      bullet
    end
  end

end
