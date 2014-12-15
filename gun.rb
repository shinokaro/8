class Gun
  def initialize(owner)
    @owner = owner
  end

end

class SingleGun < Gun

  def fire
    Shooter.single_gun(@owner, target:Game.instance.player)
  end

end

class TwoWayGun < Gun

  def fire
    Shooter.two_way_gun(@owner, target:Game.instance.player)
  end

end
