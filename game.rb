class Game

  attr_accessor :screen, :player, :enemies, :shots, :bullets, :stage
  attr_accessor :prelude, :finale

  def initialize(stage_data)
    self.screen = RenderTarget.new(Window.width/2, Window.height/2)
    self.stage = Stage.new(self, stage_data)
    self.player = Player.new(Assets[:player])
    self.player.target = self.screen
    self.player.collision = [5, 3, 10, 12]
    self.setup
  end

  def setup
    self.player.x = (self.screen.width - self.player.image.width) / 2
    self.player.y = self.screen.height
    self.enemies = []
    self.shots = []
    self.bullets = []

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
      game.finale = Fiber.new do

      end
    end
  end

  def update
    stage.update
    if player.alive?
      player.update_input
      if Input.key_push?(K_Z)
        shots.push(*player.fire)
      end
      player.update
      Sprite.update(shots)
      Sprite.update(enemies)
      Sprite.update(bullets)
      Sprite.check(enemies, player)
      Sprite.check(bullets, player)
      Sprite.check(shots, enemies)
      true
    else
      false
    end
  end

  def cleanup
    shots.each do |shot|
      shot.vanish unless self.stage === shot
    end
    enemies.each do |enemy|
      enemy.vanish unless self.stage === enemy
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
    player.draw
    Window.draw_scale(Window.width/4, Window.height/4, screen, 2, 2)
  end

end
