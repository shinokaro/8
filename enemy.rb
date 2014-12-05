class Enemy < Character

  attr_accessor :gun, :routine

  def update
    routine.resume if routine and routine.alive?
    super
  end

  def fire
    self.gun.fire
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

class EnemyModel < Struct.new(:image, :collision, :durability, :gun, :routine)
end

class EnemySpawner

  def initialize
    self.game = Game.instance
  end

  def spawn(x, y, enemy_model)
    enemy = Enemy.new(x, y, enemy_model.image).tap{|enemy|
      enemy.collision  = enemy_model.collision
      enemy.durability = enemy_model.durability
      enemy.routine    = enemy_model.routine[enemy, self.game]
      enemy.target     = self.game.screen
      enemy.gun        = enemy_model.gun.new(enemy)
    }
  end

  def game=(game)
    @game = WeakRef.new(game)
  end

  def game
    @game.__getobj__
  end

end
