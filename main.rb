require 'dxruby'
require 'weakref'
require 'fiber'
require 'forwardable'

class Graphics

  def self.[](file) "#{__dir__}/gfx/#{file}" end

end

class BGM

  def self.[](file) "#{__dir__}/bgm/#{file}" end

end

module Animative

  attr_accessor :animation_images, :animator

  def init_animation(images, wait=6)
    self.animation_images = images
    self.image = images[0]
    self.tap do |animation|
      animation.animator = Fiber.new {
        loop do
          animation.animation_images.each do |image|
            wait.times do
              Fiber.yield(image)
            end
          end
        end
      }
    end
  end

  def update_animation
    self.image = self.animator.resume
  end

end

class Unit < Sprite

  attr_accessor :vx, :vy

  def initialize(x, y)
    super(x, y)
    self.vx = 0
    self.vy = 0
  end

  def update
    update_animation
    self.x += self.vx
    self.y += self.vy
  end

  def centering_vertical(image)
    self.y + (self.image.height - image.height) / 2
  end

  def centering_horizontal(image)
    self.x + (self.image.width - image.width) / 2
  end

  def rad2deg(r)
    r * 180 / Math::PI
  end

  def angle(x, y)
    rad2deg(Math.atan2(y - self.y, x - self.x))
  end

end

class Bullet < Unit

  include Animative

  def initialize(x, y, animation_images)
    super(x, y)
    init_animation(animation_images)
  end

end

class Character < Unit

  include Animative

  attr_accessor :durability

  def initialize(x, y, animation_images)
    super(x, y)
    init_animation(animation_images)
  end

end

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

class Stage < Sprite

  attr_accessor :enemy_spawner, :enemy_wave, :sequence

  def initialize(game, wave)
    super(0, 0)
    self.collision = [-16, -16, 336, 256]
    self.game = game
    self.enemy_spawner = EnemySpawner.new(self.game)
    self.enemy_wave = wave
    self.sequence = Fiber.new {
      loop do
        enemy_wave.each do |enemies|
          150.times do
            Fiber.yield
          end
          enemies.each do |x, y, enemy_name|
            60.times do
              Fiber.yield
            end
            game.enemies << enemy_spawner.spawn(x, y, EnemyData[enemy_name])
          end
          150.times do
            Fiber.yield
          end
        end
      end
    }
  end

  def game=(game)
    @game = WeakRef.new(game)
  end

  def game
    @game.__getobj__
  end

  def update
    sequence.resume if sequence.alive?
  end

end

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

spriteset = Image.load_tiles(Graphics['spriteset.png'], 8, 8)

Assets = {
  player: spriteset[0..3],
  e_fighter: spriteset[8..11],
  e_octopas: spriteset[12..15],
  shot: spriteset[16..18],
  bullet: spriteset[24..26]
}

Window.mag_filter = TEXF_POINT

AI = {
  course_v: -> vx {
    -> enemy, game {
      Fiber.new {
        enemy.vx = vx
        150.times do |i|
          enemy.vy = Math.sin(i/300.0 * 2 * Math::PI) * 1.5
          Fiber.yield
        end
        game.bullets.push(*enemy.fire(game.player))
        150.times do |i|
          enemy.vy = Math.sin((150+i)/300.0 * 2 * Math::PI) * 1.5
          Fiber.yield
        end
        enemy.vy = -1
      }
    }
  },
  course_z: -> vx, vy {
    -> enemy, game {
      Fiber.new {
        enemy.vx = vx
        enemy.vy = 0
        150.times do |i|
          Fiber.yield
        end
        enemy.vx = vx / -3
        enemy.vy = vy
        90.times do |i|
          Fiber.yield
        end
        game.bullets.push(*enemy.fire(game.player))
        enemy.vx = vx
        enemy.vy = 0
        150.times do |i|
          Fiber.yield
        end
      }
    }
  }
}

EnemyData = {
  fighter: EnemyModel[Assets[:e_fighter], [1,5,14,16], 12, TwoWayGun, AI[:course_z][1.32, 0.8]],
  fighter_b: EnemyModel[Assets[:e_fighter], [1,5,14,16], 12, TwoWayGun, AI[:course_v][0.33]],
  octopas: EnemyModel[Assets[:e_octopas], [1,3,14,16], 12, SingleGun, AI[:course_v][-0.33]]
}

stage_data = [
  [
    [-16, 32, :fighter],
    [-16, 28, :fighter],
    [-16, 24, :fighter],
    [-16, 20, :fighter],
    [-16, 16, :fighter],
    [-16, 12, :fighter],
    [-16, 8, :fighter],
    [-16, 4, :fighter]
  ],
  [
    [320 - 32, -16, :octopas],
    [320 - 28, -16, :octopas],
    [320 - 24, -16, :octopas],
    [320 - 20, -16, :octopas],
    [320 - 16, -16, :octopas],
    [320 - 12, -16, :octopas],
    [320 - 8, -16, :octopas],
    [320 - 4, -16, :octopas]
  ],
  [
    [32, -16, :fighter_b],
    [28, -16, :fighter_b],
    [24, -16, :fighter_b],
    [20, -16, :fighter_b],
    [16, -16, :fighter_b],
    [12, -16, :fighter_b],
    [8, -16, :fighter_b],
    [4, -16, :fighter_b]
  ],
  [
    [320 - 32, -16, :octopas],
    [320 - 28, -16, :octopas],
    [320 - 24, -16, :octopas],
    [320 - 20, -16, :octopas],
    [320 - 16, -16, :octopas],
    [320 - 12, -16, :octopas],
    [320 - 8, -16, :octopas],
    [320 - 4, -16, :octopas]
  ],
]

game = nil
bgm = Sound.new(BGM['8.wav'])
bgm.loop_count = -1

Window.loop do
  if game
    if game.prelude.alive?
      game.prelude.resume
    else
      if game.update
        game.cleanup
        game.draw
      else
        bgm.stop
        Window.draw_font_ex(256, 224, "GAMEOVER", Font.default)
        if Input.key_push?(K_Z) or Input.key_push?(K_RETURN)
          game = nil
          Input.set_key_repeat(K_Z, 0, 0)
        end
      end
    end
  else
    Window.draw_font_ex(224, 224, "press Z key to start", Font.default)
    if Input.key_push?(K_Z) or Input.key_push?(K_RETURN)
      game = Game.new(stage_data.dup)
      Input.set_key_repeat(K_Z, 6, 6)
      bgm.play
    end
  end
end
