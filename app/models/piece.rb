class Piece < ApplicationRecord
  belongs_to :user
  belongs_to :game
  has_many :moves

  self.inheritance_column = :piece_type

  scope :kings,   -> { where(piece_type: 'King') }
  scope :queens,  -> { where(piece_type: 'Queen') }
  scope :rooks,   -> { where(piece_type: 'Rook') }
  scope :bishops, -> { where(piece_type: 'Bishop') }
  scope :knights, -> { where(piece_type: 'Knight') }
  scope :pawns,   -> { where(piece_type: 'Pawn') }

  # PIECE_MOVED METHOD

  def has_moved?
    self.created_at != self.updated_at
  end

  # MOVE_PIECE

  def castling_move_rook(destination_x, destination_y)
    rook = get_rook(destination_x, destination_y)
    if destination_x == 2
      rook_dest_x = 3
    elsif destination_x == 6
      rook_dest_x = 5
    end 
    rook.only_move(rook_dest_x, destination_y)
  end

  def only_move(destination_x, destination_y)
    self.current_x = destination_x
    self.current_y = destination_y
    self.save
  end

  def opposite_color
    self.piece_color == "white" ? "black" : "white"
  end

  def capture(destination_x,destination_y)
    if self.piece_type == "Pawn"
      destination_x, destination_y = pawn_coord_for_capture(destination_x, destination_y)
    end
    piece = Piece.find_by(current_x: destination_x, current_y: destination_y)
    if piece
      piece.only_move(nil,nil) if piece.piece_color == self.opposite_color
    end
  end

  # MOVE_PIECE
  def move_piece(destination_x, destination_y)
    game = Game.find(self.game_id)
    if self.valid_move?(destination_x, destination_y)
      if self.piece_type == "King" && self.castling?(destination_x, destination_y)
        castling_move_rook(destination_x, destination_y)
      end
      self.capture(destination_x,destination_y) if self.piece_type != "Pawn"
      Piece.transaction do  
        #self.current_x = destination_x
        #self.current_y = destination_y
        #self.save
        self.only_move(destination_x,destination_y)
        if game.check == true
         raise ActiveRecord::Rollback, 'Move forbidden, as it exposes your king to check'
        end
        game.turn_change
      end
    end
  end

  # NOT_OCCUPIED_BY_ME? METHOD

  def not_occupied_by_me?(destination_x, destination_y)
    game.pieces.where(piece_color: self.piece_color, current_x: destination_x,
                      current_y: destination_y).empty?
  end

  # VALID_MOVE METHOD

  def valid_move?(destination_x, destination_y)
    destination_x.between?(0, 7) && destination_y.between?(0, 7) &&
    is_move_blocked(destination_x, destination_y) == false &&
    not_occupied_by_me?(destination_x, destination_y)
  end

  # MOVE_BLOCKED METHODS

  def is_horizontal_move_blocked(destination_x)
    destination_x > self.current_x ? dir_x = 1 : dir_x = -1
    (1..((destination_x - dir_x) - self.current_x ).abs).each do |i|
      x = self.current_x + i * dir_x
      return true if Piece.find_by(current_x: x, current_y: self.current_y)
    end
    false
  end

  def is_vertical_move_blocked(destination_y)
    destination_y > self.current_y ? dir_y = 1 : dir_y = -1
    (1..((destination_y - dir_y) - self.current_y).abs).each do |i|
      y = self.current_y + i * dir_y
      return true if Piece.find_by(current_x: self.current_x, current_y: y)
    end
    false
  end

  def is_diagonal_move_blocked(destination_x, destination_y)
    destination_x > self.current_x ? dir_x = 1 : dir_x = -1
    destination_y > self.current_y ? dir_y = 1 : dir_y = -1
    (1..((destination_x - dir_x) - self.current_x).abs).each do |i|
      x = self.current_x + i * dir_x
      y = self.current_y + i * dir_y
      return true if Piece.find_by(current_x: x, current_y: y)
    end
    false
  end

  def is_move_blocked(destination_x, destination_y)
    if self.current_y == destination_y
      return is_horizontal_move_blocked(destination_x)
    elsif self.current_x == destination_x
      return is_vertical_move_blocked(destination_y)
    else
      return is_diagonal_move_blocked(destination_x, destination_y)
    end
  end
end