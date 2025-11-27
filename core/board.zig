const std = @import("std");
const geometry = @import("geometry.zig");

// --- Types & Constants ---

pub const Bitboard = u64;

pub const Color = enum(u1) {
    White = 0,
    Black = 1,

    pub fn flip(self: Color) Color {
        return @enumFromInt(1 - @intFromEnum(self));
    }
};

pub const PieceType = enum(u3) {
    Pawn = 0,
    Knight = 1,
    Bishop = 2,
    Rook = 3,
    Queen = 4,
    King = 5,
    None = 6,
};

pub const Square = enum(u6) {
    a1, b1, c1, d1, e1, f1, g1, h1,
    a2, b2, c2, d2, e2, f2, g2, h2,
    a3, b3, c3, d3, e3, f3, g3, h3,
    a4, b4, c4, d4, e4, f4, g4, h4,
    a5, b5, c5, d5, e5, f5, g5, h5,
    a6, b6, c6, d6, e6, f6, g6, h6,
    a7, b7, c7, d7, e7, f7, g7, h7,
    a8, b8, c8, d8, e8, f8, g8, h8,

    pub fn parse(str: []const u8) !Square {
        if (str.len != 2) return error.InvalidSquare;
        if (str[0] < 'a' or str[0] > 'h') return error.InvalidSquare;
        if (str[1] < '1' or str[1] > '8') return error.InvalidSquare;
        return @enumFromInt((str[1] - '1') * 8 + (str[0] - 'a'));
    }

    pub fn bitboard(self: Square) Bitboard {
        return @as(u64, 1) << @intCast(@intFromEnum(self));
    }
};

pub const CastlingRights = struct {
    pub const WK: u4 = 1;
    pub const WQ: u4 = 2;
    pub const BK: u4 = 4;
    pub const BQ: u4 = 8;
    pub const All: u4 = 15;
};

// --- Move Definition (Moved here to avoid circular dependency) ---

pub const Move = packed struct(u16) {
    from: u6,
    to: u6,
    flags: u4,

    // Flags
    pub const QUIET = 0;
    pub const DOUBLE_PUSH = 1;
    pub const CASTLE_KS = 2;
    pub const CASTLE_QS = 3;
    pub const CAPTURE = 4;
    pub const EP_CAPTURE = 5;
    pub const PROMOTE_N = 8;
    pub const PROMOTE_B = 9;
    pub const PROMOTE_R = 10;
    pub const PROMOTE_Q = 11;
    pub const PROM_CAP_N = 12;
    pub const PROM_CAP_B = 13;
    pub const PROM_CAP_R = 14;
    pub const PROM_CAP_Q = 15;

    pub fn init(f: Square, t: Square, fl: u4) Move {
        return Move{
            .from = @intCast(@intFromEnum(f)),
            .to = @intCast(@intFromEnum(t)),
            .flags = fl,
        };
    }
};

// --- Main Board Struct ---

pub const Board = struct {
    pieces: [2][6]Bitboard,
    occupancy: [3]Bitboard, // 0:White, 1:Black, 2:Both
    turn: Color,
    castling: u4,
    ep_square: ?Square,
    half_move: u16,
    full_move: u16,

    pub fn init() Board {
        return Board{
            .pieces = [2][6]Bitboard{ [_]u64{0} ** 6, [_]u64{0} ** 6 },
            .occupancy = [_]u64{0} ** 3,
            .turn = .White,
            .castling = 0,
            .ep_square = null,
            .half_move = 0,
            .full_move = 1,
        };
    }

    pub fn parseFen(fen: []const u8) !Board {
        var b = Board.init();
        var it = std.mem.tokenizeScalar(u8, fen, ' ');

        // 1. Board
        const board_part = it.next() orelse return error.InvalidFen;
        var rank: i8 = 7;
        var file: i8 = 0;

        for (board_part) |c| {
            if (c == '/') {
                rank -= 1;
                file = 0;
            } else if (std.ascii.isDigit(c)) {
                file += @intCast(c - '0');
            } else {
                const sq_idx = rank * 8 + file;
                const sq: Square = @enumFromInt(sq_idx);
                switch (c) {
                    'P' => b.addPiece(.White, .Pawn, sq),
                    'N' => b.addPiece(.White, .Knight, sq),
                    'B' => b.addPiece(.White, .Bishop, sq),
                    'R' => b.addPiece(.White, .Rook, sq),
                    'Q' => b.addPiece(.White, .Queen, sq),
                    'K' => b.addPiece(.White, .King, sq),
                    'p' => b.addPiece(.Black, .Pawn, sq),
                    'n' => b.addPiece(.Black, .Knight, sq),
                    'b' => b.addPiece(.Black, .Bishop, sq),
                    'r' => b.addPiece(.Black, .Rook, sq),
                    'q' => b.addPiece(.Black, .Queen, sq),
                    'k' => b.addPiece(.Black, .King, sq),
                    else => return error.InvalidPiece,
                }
                file += 1;
            }
        }

        // 2. Active Color
        const turn_part = it.next() orelse return error.InvalidFen;
        b.turn = if (turn_part[0] == 'w') .White else .Black;

        // 3. Castling
        const castle_part = it.next() orelse return error.InvalidFen;
        if (!std.mem.eql(u8, castle_part, "-")) {
            for (castle_part) |c| {
                switch (c) {
                    'K' => b.castling |= CastlingRights.WK,
                    'Q' => b.castling |= CastlingRights.WQ,
                    'k' => b.castling |= CastlingRights.BK,
                    'q' => b.castling |= CastlingRights.BQ,
                    else => {},
                }
            }
        }

        // 4. En Passant
        const ep_part = it.next() orelse return error.InvalidFen;
        if (!std.mem.eql(u8, ep_part, "-")) {
            b.ep_square = try Square.parse(ep_part);
        }

        b.updateOccupancies();
        return b;
    }

    fn addPiece(self: *Board, c: Color, p: PieceType, sq: Square) void {
        self.pieces[@intFromEnum(c)][@intFromEnum(p)] |= sq.bitboard();
    }

    pub fn updateOccupancies(self: *Board) void {
        var w: u64 = 0;
        var b: u64 = 0;
        for (0..6) |i| {
            w |= self.pieces[0][i];
            b |= self.pieces[1][i];
        }
        self.occupancy[0] = w;
        self.occupancy[1] = b;
        self.occupancy[2] = w | b;
    }

    /// Determines if a specific square is attacked by a specific color.
    pub fn isSquareAttacked(self: Board, sq: Square, attacker: Color) bool {
        const sq_idx = @intFromEnum(sq);
        const enemy_pieces = self.pieces[@intFromEnum(attacker)];
        const all = self.occupancy[2];

        // 1. Pawn Attacks (Reciprocal logic)
        // If I place a pawn of MY color at 'sq', does it capture an enemy pawn?
        // If yes, then an enemy pawn at that spot attacks 'sq'.
        const defender_color = attacker.flip();
        const pawn_geometry = geometry.lookups.pawn[@intFromEnum(defender_color)][sq_idx];
        if ((pawn_geometry & enemy_pieces[@intFromEnum(PieceType.Pawn)]) != 0) return true;

        // 2. Knights
        if ((geometry.lookups.knight[sq_idx] & enemy_pieces[@intFromEnum(PieceType.Knight)]) != 0) return true;

        // 3. Kings
        if ((geometry.lookups.king[sq_idx] & enemy_pieces[@intFromEnum(PieceType.King)]) != 0) return true;

        // 4. Sliding Pieces (Rooks/Queens)
        const rook_like = enemy_pieces[@intFromEnum(PieceType.Rook)] | enemy_pieces[@intFromEnum(PieceType.Queen)];
        if (rook_like != 0) {
            if ((getRookAttacks(sq_idx, all) & rook_like) != 0) return true;
        }

        // 5. Sliding Pieces (Bishops/Queens)
        const bishop_like = enemy_pieces[@intFromEnum(PieceType.Bishop)] | enemy_pieces[@intFromEnum(PieceType.Queen)];
        if (bishop_like != 0) {
            if ((getBishopAttacks(sq_idx, all) & bishop_like) != 0) return true;
        }

        return false;
    }

    /// Executes a move and returns a new Board state.
    pub fn makeMove(self: Board, m: Move) Board {
        var next = self;
        const us = next.turn;
        const them = us.flip();
        const us_idx = @intFromEnum(us);
        const them_idx = @intFromEnum(them);

        const from_bb = @as(u64, 1) << m.from;
        const to_bb = @as(u64, 1) << m.to;

        // 1. Identify moving piece
        var ptype: PieceType = .None;
        for (0..6) |i| {
            if ((next.pieces[us_idx][i] & from_bb) != 0) {
                ptype = @enumFromInt(i);
                break;
            }
        }

        // 2. Remove from source, Add to dest
        next.pieces[us_idx][@intFromEnum(ptype)] &= ~from_bb;
        next.pieces[us_idx][@intFromEnum(ptype)] |= to_bb;

        // 3. Handle Captures
        next.pieces[them_idx][0] &= ~to_bb; // Pawn
        next.pieces[them_idx][1] &= ~to_bb; // Knight
        next.pieces[them_idx][2] &= ~to_bb; // Bishop
        next.pieces[them_idx][3] &= ~to_bb; // Rook
        next.pieces[them_idx][4] &= ~to_bb; // Queen
        // King cannot be captured

        // 4. Special Moves
        
        // Promotion
        if (m.flags >= Move.PROMOTE_N) {
            // Remove the pawn we just moved
            next.pieces[us_idx][@intFromEnum(PieceType.Pawn)] &= ~to_bb;
            // Add the promoted piece
            const prom_type: PieceType = switch (m.flags) {
                Move.PROMOTE_Q, Move.PROM_CAP_Q => .Queen,
                Move.PROMOTE_R, Move.PROM_CAP_R => .Rook,
                Move.PROMOTE_B, Move.PROM_CAP_B => .Bishop,
                else => .Knight,
            };
            next.pieces[us_idx][@intFromEnum(prom_type)] |= to_bb;
        }

        // En Passant Capture
        if (m.flags == Move.EP_CAPTURE) {
            // The captured pawn is NOT on 'to' square, but on the same file as 'to' and rank of 'from'
            // Simplified: capture square is 'to' + 8 (if Black capturing) or 'to' - 8 (if White capturing)
            const cap_idx: u6 = if (us == .White) m.to - 8 else m.to + 8;
            const cap_bb = @as(u64, 1) << cap_idx;
            next.pieces[them_idx][@intFromEnum(PieceType.Pawn)] &= ~cap_bb;
        }

        // Castling
        if (m.flags == Move.CASTLE_KS) {
            // Move Rook from H1/H8 to F1/F8
            const r_from = if (us == .White) Square.h1 else Square.h8;
            const r_to = if (us == .White) Square.f1 else Square.f8;
            next.pieces[us_idx][@intFromEnum(PieceType.Rook)] &= ~r_from.bitboard();
            next.pieces[us_idx][@intFromEnum(PieceType.Rook)] |= r_to.bitboard();
        } else if (m.flags == Move.CASTLE_QS) {
            // Move Rook from A1/A8 to D1/D8
            const r_from = if (us == .White) Square.a1 else Square.a8;
            const r_to = if (us == .White) Square.d1 else Square.d8;
            next.pieces[us_idx][@intFromEnum(PieceType.Rook)] &= ~r_from.bitboard();
            next.pieces[us_idx][@intFromEnum(PieceType.Rook)] |= r_to.bitboard();
        }

        // 5. Update State (Turn, Clocks, Castling Rights, EP)
        next.turn = them;
        next.ep_square = null; // Reset EP
        if (m.flags == Move.DOUBLE_PUSH) {
            // Set EP target
            next.ep_square = @enumFromInt(if (us == .White) m.to - 8 else m.to + 8);
        }

        // Update Occupancies
        next.updateOccupancies();
        return next;
    }
};

// --- Helper Functions (Duplicated from MoveGen to avoid circular dep for now) ---
// Ideally, these go into a "sliding_attacks.zig" utility later.

fn getRookAttacks(sq_idx: usize, blockers: u64) u64 {
    var attacks: u64 = 0;
    const rank = sq_idx / 8;
    const file = sq_idx % 8;
    
    // North
    var r = rank + 1;
    while (r < 8) : (r += 1) {
        const bit = @as(u64, 1) << @intCast(r * 8 + file);
        attacks |= bit;
        if ((bit & blockers) != 0) break;
    }
    // South
    if (rank > 0) {
        r = rank - 1;
        while (true) {
            const bit = @as(u64, 1) << @intCast(r * 8 + file);
            attacks |= bit;
            if ((bit & blockers) != 0) break;
            if (r == 0) break;
            r -= 1;
        }
    }
    // East
    var f = file + 1;
    while (f < 8) : (f += 1) {
        const bit = @as(u64, 1) << @intCast(rank * 8 + f);
        attacks |= bit;
        if ((bit & blockers) != 0) break;
    }
    // West
    if (file > 0) {
        f = file - 1;
        while (true) {
            const bit = @as(u64, 1) << @intCast(rank * 8 + f);
            attacks |= bit;
            if ((bit & blockers) != 0) break;
            if (f == 0) break;
            f -= 1;
        }
    }
    return attacks;
}

fn getBishopAttacks(sq_idx: usize, blockers: u64) u64 {
    var attacks: u64 = 0;
    const rank = @as(i8, @intCast(sq_idx / 8));
    const file = @as(i8, @intCast(sq_idx % 8));
    const dirs = [_][2]i8{ .{1, 1}, .{1, -1}, .{-1, 1}, .{-1, -1} };

    for (dirs) |d| {
        var r = rank + d[0];
        var f = file + d[1];
        while (r >= 0 and r < 8 and f >= 0 and f < 8) {
            const bit = @as(u64, 1) << @intCast(@as(u6, @intCast(r * 8 + f)));
            attacks |= bit;
            if ((bit & blockers) != 0) break;
            r += d[0];
            f += d[1];
        }
    }
    return attacks;
}