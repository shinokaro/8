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

require_relative 'animative'
require_relative 'unit'
require_relative 'player'
require_relative 'enemy'
require_relative 'gun'
require_relative 'shooter'
require_relative 'stage'
require_relative 'game'

spriteset = Image.load_tiles(Graphics['spriteset.png'], 8, 8)

Assets = {
  player:    spriteset[ 0.. 3],
  e_fighter: spriteset[ 8..11],
  e_octopas: spriteset[12..15],
  shot:      spriteset[16..18],
  bullet:    spriteset[24..26]
}



AI = {
  course_v: -> vx {
    -> enemy, game {
      Fiber.new {
        enemy.vx = vx
        150.times do |i|
          enemy.vy = Math.sin(i/300.0 * 2 * Math::PI) * 1.5
          Fiber.yield
        end
        enemy.fire
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
        enemy.fire
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
  fighter:   EnemyModel[Assets[:e_fighter], [1,5,14,16], 12, TwoWayGun, AI[:course_z][1.32, 0.8]],
  fighter_b: EnemyModel[Assets[:e_fighter], [1,5,14,16], 12, TwoWayGun, AI[:course_v][0.33]],
  octopas:   EnemyModel[Assets[:e_octopas], [1,3,14,16], 12, SingleGun, AI[:course_v][-0.33]]
}

stage_data = [
  [
    [-16, 32, :fighter],
    [-16, 28, :fighter],
    [-16, 24, :fighter],
    [-16, 20, :fighter],
    [-16, 16, :fighter],
    [-16, 12, :fighter],
    [-16,  8, :fighter],
    [-16,  4, :fighter]
  ],
  [
    [320 - 32, -16, :octopas],
    [320 - 28, -16, :octopas],
    [320 - 24, -16, :octopas],
    [320 - 20, -16, :octopas],
    [320 - 16, -16, :octopas],
    [320 - 12, -16, :octopas],
    [320 -  8, -16, :octopas],
    [320 -  4, -16, :octopas]
  ],
  [
    [32, -16, :fighter_b],
    [28, -16, :fighter_b],
    [24, -16, :fighter_b],
    [20, -16, :fighter_b],
    [16, -16, :fighter_b],
    [12, -16, :fighter_b],
    [ 8, -16, :fighter_b],
    [ 4, -16, :fighter_b]
  ],
  [
    [320 - 32, -16, :octopas],
    [320 - 28, -16, :octopas],
    [320 - 24, -16, :octopas],
    [320 - 20, -16, :octopas],
    [320 - 16, -16, :octopas],
    [320 - 12, -16, :octopas],
    [320 -  8, -16, :octopas],
    [320 -  4, -16, :octopas]
  ],
]


bgm = Sound.new(BGM['8.wav']).tap{|sound|
  sound.loop_count = -1
}
game_state = :title

Window.mag_filter = TEXF_POINT

Window.loop do
  case game_state
  when :title
    Window.draw_font_ex(224, 224, "press Z key to start", Font.default)
    game_state = :init     if     Game.instance.player_accept?
  when :init
    Game.instance.setup(stage_data.dup)
    Input.set_key_repeat(K_Z, 6, 6)
    bgm.play
    game_state = :prelude
  when :prelude
    Game.instance.prelude_play
    game_state = :play     unless Game.instance.prelude_play?
  when :play
    Game.instance.play
    game_state = :gameover unless Game.instance.player_alive?
  when :gameover
    bgm.stop
    Window.draw_font_ex(256, 224, "GAMEOVER", Font.default)
    game_state = :after    if     Game.instance.player_accept?
  when :after
    Input.set_key_repeat(K_Z, 0, 0)
    game_state = :title
  else
    raise
  end
end
