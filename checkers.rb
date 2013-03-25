require 'colorize'

class Piece
  attr_accessor :color, :position
  attr_reader :board

  def initialize(color, position, board)
    @color, @position, @board = color, position, board
  end

  def try_move(move)
    # puts "in try move"
    # puts "position: #{position}"
    # puts "move: #{move}"
    position.zip(move).map { |pair| pair.reduce(:+) }
  end

  def valid_move?(move)
    destination = try_move(move)

    return false unless advances.include?(move) || valid_jump?(move)
    return false if board[*destination].is_a? Piece
    return false if destination.any? { |z| !z.between?(0, board.rows.size - 1) }
    true
  end

  def can_make_a_move?
    advances.each { |advance| return true if valid_move?(advance) }
    jumps.each { |jump| return true if valid_move?(jump) }

    false
  end

  def can_make_a_jump?
    jumps.each { |jump| return true if valid_move?(jump) }

    false
  end

  def valid_jump?(move)
    puts "in valid jump"
    puts "move: #{move}"

    jumped_square = try_move(jumped_squares[move])
    puts "jumped square #{jumped_square}"
    maybe_a_piece = board[*jumped_square]

    jumps.include?(move) && maybe_a_piece.class.is_a?(Piece) && maybe_a_piece.color != color
  end

  def find_move(destination)
    # puts "in find move"
    # puts "destination #{destination}"
    # puts "position #{position}"
    destination.zip(position).map { |pair| pair.reduce(:-) }
  end

  def move_to(destination)
    move = find_move(destination)
    # puts "in move to"
    # puts "destination #{destination}"
    # puts "move #{move}"
    if valid_move?(move)
      board[*position] = nil
      board[*destination] = self
      self.position = destination

      if valid_jump?(move)
        jumped_square = try_move(jumped_squares[move])
        board[*jumped_square] = nil
      end
    end
  end

end

class Pawn < Piece

  def render
    " o".colorize(color)
  end

  def multi_jump?
  end

  def jumped_squares
    return {[-2,2] => [-1,1] , [2,2] => [1,1]} if color == :white
    return {[-2,-2] => [-1,-1], [2,-2] => [1,-1]} if color == :red
  end

  def advances
    return [[-1,1],[1,1]] if color == :white
    return [[-1,-1],[1,-1]] if color == :red
  end

  def jumps
    return [[-2,2],[2,2]] if color == :white
    return [[-2,-2],[2,-2]] if color == :red
  end

  def promote
    board[*position] = King.new(color, position, board)
  end

end

class King < Piece
  def render
    "OO".colorize(color)
  end

  def jumped_squares
    {[-2,2] => [-1,1] , [2,2] => [1,1], [-2,-2] => [-1,-1], [2,-2] => [1,-1]}
  end

  def advances
    [[-1,1],[1,1],[-1,-1],[1,-1]]
  end

  def jumps
    [[-2,2],[2,2],[-2,-2],[2,-2]]
  end

end

class Board
  attr_accessor :rows

  def initialize
    @rows = Array.new(8) { Array.new(8) } #check chess
    build_start_position
  end

  def [](x,y)
    @rows[y][x]
  end

  def []=(x, y, item)
    @rows[y][x] = item
  end

  def build_start_position
    fill_three_rows(0..2, :white)
    fill_three_rows(5..7, :red)

    nil
  end

  def place_piece(piece)
    self[*piece.position] = piece
  end

  def fill_three_rows(three_rows, color)
    three_rows.each do |row_i|
      rows.length.times do |col_i|
        if black_square?(col_i, row_i)
          self[col_i, row_i] = Pawn.new(color, [col_i, row_i], self)
        end
      end
    end

    nil
  end

  def black_square?(x, y)
    (x.odd? && y.even?) || (x.even? && y.odd?)
  end

  def render_square(x, y)
    if (x.odd? && y.even?) || (x.even? && y.odd?)
      color = :blue
    else
      color = :white
    end

    if self[x, y].nil?
      piece_or_empty = "  "
    else
      piece_or_empty = self[x, y].render
    end

    print piece_or_empty.colorize(:background => color)
  end

  def display
    puts "   1 2 3 4 5 6 7 8 ".colorize(:color => :yellow)
    rows.each_with_index do |row, y|
      print "#{y+1} ".colorize(:color => :yellow)
      row.each_index do |x|
        render_square(x, y)
      end
      puts
    end

    puts
    nil
  end

  def valid_piece?(piece, player)
    return false if self[*piece].nil?
    true if player.color == self[*piece].color
  end

  def game_over?
  end

  def win?
  end

  def lose?
  end

  def draw?
  end

end

class Player
  attr_accessor :color

  def initialize(color)
    @color = color
  end

end

class HumanPlayer < Player

  def make_move(board)
    piece_coords = get_origin(board)
    x, y = piece_coords

    destination = get_destination(piece_coords, board)
    board[x, y].move_to(destination)

    while board[x, y].can_make_a_jump?
      destination = get_destination(piece_coords, board)
      # puts "in make move"
      # puts "piece_coords #{piece_coords}"
      # puts "origin #{x},#{y}"
      # puts "destination #{destination}"
      board[x, y].move_to(destination)
      x, y = destination
    end
  end

  def get_origin(board)
    piece_coords = nil
    until piece_coords
      puts "Choose a piece to move by its x and y coordinates (ex: 1, 3)"
      piece_coords = gets.chomp.split(/\W+/).map(&:to_i)
      piece_coords = adjust_coords(piece_coords)
      x, y = piece_coords
      piece_coords = nil if origin_wrong?(x, y, board)
    end


    piece_coords
  end

  def origin_wrong?(x, y, board)
    if board[x, y].nil?
      puts "That's an empty square, bud."
    elsif board[x, y].color != color
      puts "Wrong color, friend."
    elsif !board[x, y].can_make_a_move?
      puts "That piece can't make a move."
    else
      return false
    end

    true
  end

  def get_destination(origin, board)
    destination = nil
    until destination
      puts "Choose a destination by its x and y coordinates (ex: 1, 3)"
      destination = gets.chomp.split(/\W+/).map(&:to_i)
      destination = adjust_coords(destination)
      x, y = destination
      destination = nil if destination_wrong?(x, y, origin, board)
    end

    # puts "in destination"
    # puts "destination #{destination}"

    destination
  end

  def destination_wrong?(x, y, origin, board)
    piece = board[*origin]
    move = piece.find_move([x, y])

    # puts "in destination wrong"
    # puts "#{move}"

    unless piece.valid_move?(move)
      puts "Invalid move!"
      return true
    end

    false
  end

  def adjust_coords(coords)
    [coords[0] - 1, coords[1] - 1]
  end

end

class ComputerPlayer < Player
  def make_move(board)
    piece_coords = "random" #board[rand(8)][rand(8)] !nil
  end
end

class Checkers
  def play
    player_color = choose_color
    computer_color = ([:red, :white] - [player_color]).first
    human = HumanPlayer.new(player_color)
    computer = ComputerPlayer.new(computer_color)
    board = Board.new

    until board.game_over?
      board.display
      make_moves(human, computer, board)
    end

    final message(board)
  end

  def choose_color
    color = nil
    until ["red", "white"].include?(color)
      print "Choose your color (red, white): "
      color = gets.chomp
      puts "Invalid color!" unless ["red", "white"].include?(color)
    end

    color.to_sym
  end

  def make_moves(human, computer, board)
    if human.color == :white
      human.make_move(board)
      computer.make_move(board)
    else
      computer.make_move(board)
      human.make_move(board)
    end
  end

  def final_message(board)
    return "You win!" if board.win?
    return "You lose, sucka!" if board.lose?
    return "It's a draw" if board.draw?

    "Something went terribly wrong..."
  end
end

g = Checkers.new
g.play

