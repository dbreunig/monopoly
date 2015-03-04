require_relative 'board'
require_relative 'player'
require_relative 'property'

# SETTINGS
UNMATCHED_PROPERTIES_OPEN_TO_EXIT_JAIL = 5
# MATCHED_PROPERTIES_OPEN_TO_EXIT_JAIL   = 1

@debug = true

# GAME SET UP
@board  = Board.new("board.csv")
@board.players << Player.new("Iron")
@board.players << Player.new("Dog")
# @board.players << Player.new("Car")
# @board.players << Player.new("Hat")

# LOGIC

def exit_jail?(player)
  unsold = @board.unsold_properties.count
  if unsold > UNMATCHED_PROPERTIES_OPEN_TO_EXIT_JAIL && player.funds > 50
    puts "#{player.token} pays $50 to exit jail." if @debug
    player.pay_fee(50)
    @board.release_from_jail(player)
    return true
  end
  return false
end

def buy_property?(player, property)
  if player.funds >= ( property.price + 500 )
    puts "#{player.token} buys #{property.name} for $#{property.price}."
    player.buy_property(property)
    return true
  end
  return false
end

def buy_house?(player, property)
  return player.buy_house_on_property(property)
end

def build_all_possible_houses(player)
  return false if @board.free_houses == 0
  return false if player.monopolies.count == 0
  # Find all monoplies and arrange them into array
  blocks = []
  player.monopolies.each do | color |
    blocks << player.properties.find_all { |p| p.color == color }
  end
  # Sort by most expensive
  blocks.sort! { |a,b| b[0].rent <=> a[0].rent }
  blocks.each do |block|
    # Sort the block ascending by houses
    block.sort! { |a,b| a.houses <=> b.houses }
    # Buy until you run out of funds or available houses
    block.each { |p| break if !buy_house?(player, p) }
  end
end

def find_money(player, needed)
  puts "#{player.token} trying to find $#{needed}..." if @debug
  return if player.funds > needed
  # Get properties without houses
  avail_properties  = player.properties.find_all { |p| !p.mortgaged }
  # Order by rent value, ascending(?)
  avail_properties.sort! { | a, b | a.rent <=> b.rent }
  # Get properties without houses
  no_houses         = avail_properties.find_all { |p| p.houses == 0 }
  # Get properties without monopoly
  no_monopolies     = no_houses.find_all { |p| !(player.monopolies.find_index(p.color)) }
  # Search for funds in no monopoly properties
  puts "Checking unmatched" if @debug
  no_monopolies.each do |p|
    return if player.funds > needed
    puts "#{player.token} mortgages #{p.name} for $#{p.price/2}" if @debug && !p.mortgaged
    player.mortgage_property(p) unless p.mortgaged
  end
  # Search for funds in the unbuilt properties
  puts "Checking unbuilt" if @debug
  no_houses.each do |p|
    return if player.funds > needed
    puts "#{player.token} mortgages #{p.name} for $#{p.price/2}" if @debug && !p.mortgaged
    player.mortgage_property(p) unless p.mortgaged
  end
  # If still no funds, sell houses
  puts "Selling houses" if @debug
  avail_properties.each do |p|
    return if player.funds > needed
    while p.houses > 0 && player.funds <= needed
      puts "#{player.token} sells house on #{p.name} for $#{p.build_price/2}" if @debug
      player.sell_house_on_property(p)
    end
  end
  # Mortage monopolies with no houses
  puts "Checking matched" if @debug
  avail_properties.each do |p|
    return if player.funds > needed
    puts "#{player.token} mortgages #{p.name} for $#{p.price/2}" if @debug && !p.mortgaged
    player.mortgage_property(p) unless p.mortgaged
  end
  # If broke, set player to $0 and bankrupt to true
  return if player.funds > needed
  puts "#{player.token} GOES BROKE!" if @debug
  @board.go_broke(player)
end

def pay_rent(player, property)
  rent = property.rent
  rent = property.type == TileType::UTILITY ? rent * @board.roll_dice : rent
  while player.funds < rent
    break if player.bankrupt
    puts "Has $#{player.funds}, needs $#{rent}..."
    find_money(player, rent)
  end
  if player.funds > rent
    puts "#{player.token} pays $#{rent} to #{property.owner.token}." if @debug
    player.pay_rent(property)
  end
end

def pay_or_buy(player, property)
  # Determine if owned by other player
  if property.owner && property.owner != player && !property.mortgaged
    # Pay rent
    pay_rent(player, property)
  elsif !property.owner
    # Purchase if possible
    buy_property?(player, property)
  end
end

def unmortgage_all_properties(player)
  # Get properties without houses
  mortgages  = player.properties.find_all { |p| p.mortgaged }
  # Order by rent value, descending(?)
  mortgages.sort! { | a, b | b.rent <=> a.rent }
  mortgages.each do |p|
    if player.funds > (p.price / 2)
      puts "#{player.token} unmortgages #{p.name} for $#{p.price/2}!" if @debug
      player.unmortgage_property(p)
    end
  end  
end

# ----------------------------------------
# Politics

def wheel_and_deal(player)
  sold = @board.tiles.count { |p| p.owner }
  if sold == 28 && player.monopolies.count == 0
    partner = find_ideal_partner(player)
  end
end

def find_ideal_partner(player)
  ideal_partners    = [] # In order of best deal
  candidate_colors  = player.properties.sort { |a,b| b.rank <=> a.rank } # In order of best monopoly
  candidate_colors.each { |a| puts "#{a.color}: #{a}" }
  # Sort colors by ideal
  # Sort properties by (1) missing one card, (2) 2 of 3, (3) potential rent
  @board.players.each do | partner |
    next if partner == player
    # Go through properties
    
    # Rules
    # - Both players accept monopoly
    # - If Blue or Green, ensure cash for building
    # - A monopoly next to another monopoly is ideal
    # 
    
    
    abort()
  end
end

# ----------------------------------------
# Tests

def run_test()
  open = @board.tiles.count { |p| !p.owner }
  sold = @board.tiles.count { |p| p.owner }
  puts "#{open} unsold, #{sold} sold"
  if (open + sold) != @board.tiles.count
    puts "ERROR"
    puts @board
    puts @board.players
    exit
  end
end

# TURNS
@turns        = 0
@double_count = 0
while !@board.winner
  
  puts "- - - - - - -"
  
  # Get Next Player
  @turns += 1
  player  = @board.advance_turn
  
  # Check for Jail    
  next if player.in_jail && exit_jail?(player)
  
  # Roll Dice for Next Player
  old_pos = player.position
  die1    = @board.roll_die
  die2    = @board.roll_die
  roll    = die1 + die2
  
  # If in jail, check for releasing doubles
  if player.in_jail && (die1 == die2)
    puts "#{player.token} rolls doubles to break out of jail!" if @debug
    @board.release_from_jail(player)
    next
  end
  
  # Check for 3rd Double
  if (die1 == die2) && @double_count == 2 
    puts "#{player.token} rolls third double and goes to jail!" if @debug
    @double_count = 0
    @board.put_in_jail(player)
    next
  end
  
  # Move Player
  tile    = @board.tiles[player.move(roll)]
  if old_pos > player.position
    puts "#{player.token} crosses Go, earns $200." if @debug
    player.earn_money(200)
  end
  puts "#{player.token} rolls #{roll}, and lands on #{tile.name}." if @debug
  
  # Process
  case tile.type
  when TileType::PROPERTY
    pay_or_buy(player, tile)
  when TileType::CHANCE
    @board.draw_chance(player)
  when TileType::CHEST
    @board.draw_chest(player)
  when TileType::GO
    # Nothing
  when TileType::TAX
    player.pay_fee(tile.rent)
  when TileType::RAILROAD
    pay_or_buy(player, tile)
  when TileType::UTILITY
    pay_or_buy(player, tile)
  when TileType::JAIL
    # Nothing (for now)
  when TileType::PARKING
    # Nothing
  when TileType::GO_TO_JAIL
    @board.put_in_jail(player)
    next # Advance even if doubles
  end
  
  # Unmorgage properties if needed
  unmortgage_all_properties(player)
  
  # Consider buying houses & hotels
  build_all_possible_houses(player)
  
  # Check for negative funds
  while player.funds < 0
    # Find money
    find_money(player, (0 - player.funds))
  end
  
  puts "Funds:      #{player.funds}" if @debug
  puts "Properties: #{player.properties.count}, #{player.properties.count{|p| p.mortgaged}} mortgaged" if @debug
  
  # Wheel and deal!
  wheel_and_deal(player)
  
  # If Doubles, Roll Again
  if die1 == die2
    puts "#{player.token} rolls again!" if @debug
    @board.current_player -= 1
    @double_count += 1
  else
    @double_count = 0
  end
  
  run_test()
  
  # sleep 1
end

# Print Summary
puts "- - - -" if @debug

winner = @board.winner
puts "#{winner.token} wins with $#{winner.funds} in #{@turns} turns!!!\n\nSUMMARY:" if @debug

if @debug
  @board.tiles.sort{ |a, b| b.total_value <=> a.total_value }.each do |p|
    puts "#{p.name.rjust(30)} $#{p.total_value.to_s}" if p.total_value > 0
  end
end
