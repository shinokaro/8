class Stage < Sprite

  attr_accessor :enemy_spawner, :enemy_wave, :sequence

  def initialize(wave)
    super(0, 0)
    self.collision = [-16, -16, 336, 256]
    self.enemy_spawner = EnemySpawner.new
    self.enemy_wave = wave
    game = Game.instance
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

  def update
    sequence.resume if sequence.alive?
  end

end
