class TileType
  PROPERTY    = 0
  CHANCE      = 1
  CHEST       = 2
  GO          = 3
  TAX         = 4
  RAILROAD    = 5
  UTILITY     = 6
  JAIL        = 7
  PARKING     = 8
  GO_TO_JAIL  = 9
end

class Property
  attr_accessor :name, :type, :color, :position, :price, :build_price, :rent0, :rent1, :rent2, :rent3, :rent4, :rent5, :color_count, :total_value
  attr_accessor :houses, :owner, :mortgaged
  def initialize(row)
    @name = row[0]
    @type = case row[1]
      when "Street" then TileType::PROPERTY
      when "Chance" then TileType::CHANCE
      when "Chest" then TileType::CHEST
      when "Go" then TileType::GO
      when "Tax" then TileType::TAX
      when "Railroad" then TileType::RAILROAD
      when "Jail" then TileType::JAIL
      when "Parking" then TileType::PARKING
      when "GoToJail" then TileType::GO_TO_JAIL
      when "Utility" then TileType::UTILITY  
    end
    @color      = row[2]
    @position   = row[3].to_i
    @price      = row[4].to_i
    @build_price = row[5].to_i
    @rent0      = row[6].to_i
    @rent1      = row[7].to_i
    @rent2      = row[8].to_i
    @rent3      = row[9].to_i
    @rent4      = row[10].to_i
    @rent5      = row[11].to_i
    @color_count = row[12].to_i
    @mortgaged  = false
    @houses     = 0
    @total_value = 0
  end
  def purchased?
    return false if !@owner
    return true
  end
  def rent
    rent = @rent0
    if @houses == 0
      case @type
      when TileType::PROPERTY
        # determine if monopoly in effect
        rent = @owner.monolopy_for_color(@color) ? (@rent0 * 2) : @rent0
      when TileType::RAILROAD
        # determine railroad
        rent = 25 * @owner.number_of_railroads_owned
      when TileType::UTILITY
        # determine utility
        rent = @owner.number_of_utilities_owned == 2 ? 10 : 4
      end
    else
      rent = case @houses        
        when 1 then @rent1
        when 2 then @rent2
        when 3 then @rent3
        when 4 then @rent4
        when 5 then @rent5
      end
    end
    return rent
  end
  def to_s
    "#{@name}: #{@price}"
  end
  def rank
    case @color
    when "Brown" then return 0
    when "LightBlue" then return 1
    when "Pink" then return 2
    when "Orange" then return 3
    when "Red" then return 4
    when "Yellow" then return 5
    when "Green" then return 6
    when "Blue" then return 7
    else return -1
    end
  end
end