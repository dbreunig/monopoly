require 'csv'
require_relative 'property'
require_relative 'player'

class Board
  attr_accessor :players, :bankrupt_players, :tiles, :current_player, :free_houses, :free_hotels, :jailbirds
  def initialize(board_location)
    self.load_board(board_location)
    @players          = []
    @bankrupt_players = []
    @current_player   = -1
    @free_houses      = 32
    @free_hotels      = 12
    @jailbirds        = []
  end
  def load_board(board_location)
    @tiles = []
    CSV.foreach(board_location) do | square |   
      # Ignore header
      next if $. == 1
      # Load square
      # Name,Space,Color,Position,Price,PriceBuild,Rent,RentBuild1,RentBuild2,RentBuild3,RentBuild4,RentBuild5
      @tiles << Property.new(square)
    end
  end
  
  # ----------------------------------------
  # Utilities
  
  def roll_dice
    return ((1 + rand(6)) + (1 + rand(6)))
  end
  
  def roll_die
    (1 + rand(6))
  end
  
  def advance_turn
    @current_player += 1
    @current_player = 0 if @current_player > (@players.count - 1)
    return @players[@current_player]
  end
  
  def draw_chance(player)
    puts "(draws chance)"
  end
  
  def draw_chest(player)
    puts "(draws chest)"
  end
  
  # ----------------------------------------
  # Player Actions
  
  def put_in_jail(player)
    player.in_jail  = true
    player.jail_turns = 0
    @jailbirds << player
  end
  
  def release_from_jail(player)
    player.in_jail    = false
    player.jail_turns = 0
    @jailbirds.delete(player)
  end
  
  def go_broke(player)
    @players.delete(player)
    @bankrupt_players << player
    player.go_broke
  end
  
  # ----------------------------------------
  # Trading
  
  def trade_up_color(color)
    case color
    when "Brown" then return "LightBlue"
    when "LightBlue" then return "Pink"
    when "Pink" then return "Orange"
    when "Orange" then return "Red"
    when "Red" then return "Yellow"
    when "Yellow" then return "Green"
    when "Green" then return "Blue"
    else return nil
    end
  end
  
  def trade_down_color(color)
    case color
    when "LightBlue" then return "Brown"
    when "Pink" then return "LightBlue"
    when "Orange" then return "Pink"
    when "Red" then return "Orange"
    when "Yellow" then return "Red"
    when "Green" then return "Yellow"
    when "Blue" then return "Green"
    else return nil
    end
  end
  
  def rank(color)
      case color
      when "Brown" then return 0
      when "LightBlue" then return 1
      when "Pink" then return 2
      when "Orange" then return 3
      when "Red" then return 4
      when "Yellow" then return 5
      when "Green" then return 6
      when "Blue" then return 7
      else return nil
      end
  end
  
  # ----------------------------------------
  # States
  
  def winner
    winner = nil
    if @players.count == 1
      winner = @players[0]
    end
    return winner
  end
  
  def unsold_properties
    @tiles.find_all { |t| ( t.type == TileType::PROPERTY || t.type == TileType::RAILROAD || t.type == TileType::UTILITY ) && t.owner == nil }
  end
  
end