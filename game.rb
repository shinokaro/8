require 'singleton'

class Game

  include Singleton

  attr_accessor :screen, :player, :enemies, :shots, :bullets, :stage
  attr_accessor :prelude, :finale

  def initialize
  end

  def setup(stage_data)
    self.screen = RenderTarget.new(Window.width/2, Window.height/2)
    self.player = Player.new(Assets[:player]).tap{|player|
      player.target    = self.screen
      player.collision = [5, 3, 10, 12]
    }
    self.stage    = Stage.new(stage_data)
    self.player.x = (self.screen.width - self.player.image.width) / 2
    self.player.y = self.screen.height
    self.enemies  = []
    self.shots    = []
    self.bullets  = []

    tap do |game|
      game.prelude = Fiber.new do
      Fiber.yield
      v = 5
      while v > 0.9
        v *= 0.9
          game.player.y -= v
        Fiber.yield
      end
        game.player.vy = -0.9
      end
      game.finale = Fiber.new{}
    end
  end

  def play
    update
    cleanup
    draw
  end

  private

  def update
    stage.update
    if player.alive?
      player.update_input
      if Input.key_push?(K_Z)
        shots.push(*player.fire)
      end
      Sprite.update(player)
      Sprite.update(shots)
      Sprite.update(enemies)
      Sprite.update(bullets)
      Sprite.check(enemies, player,  :shot_player, :hit_enemy)
      Sprite.check(bullets, player,  :shot_player, :hit_bullet)
      Sprite.check(shots,   enemies, :shot_enemy,  :hit_shot)
    end
  end

  def cleanup
    shots.each   do |shot|
      shot.vanish   unless self.stage === shot
    end
    enemies.each do |enemy|
      enemy.vanish  unless self.stage === enemy
    end
    bullets.each do |bullet|
      bullet.vanish unless self.stage === bullet
    end
    Sprite.clean(shots)
    Sprite.clean(enemies)
    Sprite.clean(bullets)
  end

  def draw
    Sprite.draw(bullets)
    Sprite.draw(enemies)
    Sprite.draw(shots)
    Sprite.draw(player)
    Window.draw_scale(Window.width/4, Window.height/4, screen, 2, 2)
  end

end
