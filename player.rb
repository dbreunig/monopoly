class Player
  attr_accessor :properties, :funds, :position, :token, :in_jail, :jail_turns, :bankrupt, :monopolies
  def initialize(token)
    @token      = token
    @properties = []
    @funds      = 1500
    @position   = 0
    @in_jail    = false
    @jail_turns = 0
    @bankrupt   = false
    @monopolies = [] # [ "color_name" ]
  end
  # - - -
  # Actions
  def move(number_of_spaces)
    @position += number_of_spaces
    if @position > 39
      @position = @position - 40
    end
    return @position
  end
  # - - -
  # Purchases
  def pay_rent(property)
    rent = property.rent
    self.pay_fee(rent)
    property.owner.earn_money(rent)
    property.total_value += rent
  end
  def buy_property(property)
    property.owner = self
    self.pay_fee(property.price)
    @properties << property
    # check if monopoly
    if @properties.count { |p| p.color == property.color } == property.color_count
      @monopolies << property.color
      @monopolies.uniq!
    end
  end
  def buy_house_on_property(property)
    return false if property.houses == 5 || property.owner != self || !(@monopolies.find_index(property.color)) || @funds < property.build_price
    property.houses += 1
    self.pay_fee(property.build_price)
    return true
  end
  def unmortgage_property(property)
    property.mortgaged = false
    self.pay_fee(property.price/2)
  end
  def mortgage_property(property)
    property.mortgaged = true
    self.earn_money(property.price/2)
  end
  def sell_house_on_property(property)
    return if property.houses == 0 || property.owner != self
    property.houses -= 1
    self.earn_money(property.build_price/2)
  end
  def go_broke
    puts "!!!! #{@token} GOES BROKE !!!!"
    @funds      = 0
    @bankrupt   = true
    @monopolies = []
    @in_jail    = false
    @properties.each { |p| p.owner = nil; p.mortgaged = false; p.houses = 0 }
  end
  # - - -
  # Transactions
  def pay_fee(fee)
    @funds -= fee
  end
  def earn_money(revenue)
    @funds += revenue
  end
  # - - -
  # State
  def monolopy_for_color(color)
    return true if @monopolies.find_index(color)
    return false
  end
  def number_of_railroads_owned
    return @properties.count { |p| p.type == TileType::RAILROAD }
  end
  def number_of_utilities_owned
    return @properties.count { |p| p.type == TileType::UTILITY }
  end
end