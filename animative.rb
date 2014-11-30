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
