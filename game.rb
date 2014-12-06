require 'singleton'

class Game

  include Singleton

  attr_accessor :screen, :player, :enemies, :shots, :bullets, :stage
  attr_accessor :prelude, :finale

<<<<<<< HEAD
  def initialize(stage_data)
    @screen = RenderTarget.new(Window.width/2, Window.height/2)
    @stage  = Stage.new(self, stage_data)
    @player = Player.new(Assets[:player])
    @player.target    = @screen
    @player.collision = [5, 3, 10, 12]
    setup
  end

  def setup
    @player.x = (@screen.width - @player.width) / 2
    @player.y = @screen.height
    @enemies  = []
    @shots    = []
    @bullets  = []
=======
  def initialize
    self.screen = RenderTarget.new(Window.width/2, Window.height/2)
    self.player = Player.new(Assets[:player]).tap{|player|
      player.target    = self.screen
      player.collision = [5, 3, 10, 12]
    }
    #self.setup
  end

  def setup(stage_data)
    self.stage    = Stage.new(stage_data)
    self.player.x = (self.screen.width - self.player.image.width) / 2
    self.player.y = self.screen.height
    self.enemies  = []
    self.shots    = []
    self.bullets  = []
>>>>>>> origin/master

    @prelude = Fiber.new{
      Fiber.yield
      v = 5
      while v > 0.9
        v *= 0.9
        @player.y -= v
        Fiber.yield
      end
<<<<<<< HEAD
      @player.vy = -0.9
    }
    @finale = Fiber.new{}
  end

  def update
    @stage.update
    if @player.alive?
      @player.update_input
      @shots.push(*@player.fire) if Input.key_push?(K_Z)
      @player.update
      Sprite.update(@shots)
      Sprite.update(@enemies)
      Sprite.update(@bullets)
      Sprite.check(@bullets, @player)
      Sprite.check(@enemies, @player)
      Sprite.check(@shots,   @enemies)
=======
      game.finale = Fiber.new{}
    end
  end

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
      Sprite.check(enemies, player)
      Sprite.check(bullets, player)
      Sprite.check(shots,   enemies)
>>>>>>> origin/master
      true
    else
      false
    end
  end

  def cleanup
<<<<<<< HEAD
    @bullets.each do |bullet|
      bullet.vanish unless @stage === bullet
    end
    @enemies.each do |enemy|
      enemy.vanish  unless @stage === enemy
=======
    shots.each   do |shot|
      shot.vanish   unless self.stage === shot
    end
    enemies.each do |enemy|
      enemy.vanish  unless self.stage === enemy
>>>>>>> origin/master
    end
    @shots.each   do |shot|
      shot.vanish   unless @stage === shot
    end
    Sprite.clean(@bullets)
    Sprite.clean(@enemies)
    Sprite.clean(@shots)
  end

  def draw
<<<<<<< HEAD
    Sprite.draw(@bullets)
    Sprite.draw(@enemies)
    Sprite.draw(@shots)
    @player.draw
    Window.draw_scale(Window.width/4, Window.height/4, @screen, 2, 2)
=======
    Sprite.draw(bullets)
    Sprite.draw(enemies)
    Sprite.draw(shots)
    Sprite.draw(player)
    Window.draw_scale(Window.width/4, Window.height/4, screen, 2, 2)
>>>>>>> origin/master
  end

end
