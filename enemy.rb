class Enemy < Character

  attr_accessor :gun, :routine

  def update
    routine.resume if routine and routine.alive?
    super
  end

  def fire(player)
    self.gun.fire(player)
  end

  def hit(o)
    case o
    when Bullet
      o.vanish
      self.durability -= 1
      if self.durability < 1
        self.vanish
      end
    end
  end

end

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

class EnemyModel < Struct.new(:image, :collision, :durability, :gun, :routine)
end

class EnemySpawner

  def initialize(game)
    self.game = game
  end

  def spawn(x, y, enemy_model)
    enemy = Enemy.new(x, y, enemy_model.image)
    enemy.collision =  enemy_model.collision
    enemy.durability = enemy_model.durability
    enemy.routine = enemy_model.routine[enemy, self.game]
    enemy.target = self.game.screen
    enemy.gun = enemy_model.gun.new(enemy)
    enemy
  end

  def game=(game)
    @game = WeakRef.new(game)
  end

  def game
    @game.__getobj__
  end

end
