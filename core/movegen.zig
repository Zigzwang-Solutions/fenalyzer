const std = @import("std");
const board_mod = @import("board.zig");
const geometry = @import("geometry.zig");

const Board = board_mod.Board;
const Move = board_mod.Move; // Imported from Board now
const Bitboard = board_mod.Bitboard;
const Square = board_mod.Square;
const Color = board_mod.Color;
const PieceType = board_mod.PieceType;

/// Bounded list for moves (Max possible is around 218).
pub const MoveList = std.BoundedArray(Move, 256);

pub const MoveGenerator = struct {

    /// Generates strictly LEGAL moves.
    /// Filters out any move that leaves the king in check.
    pub fn generateLegalMoves(b: Board, list: *MoveList) void {
        var pseudo_list = MoveList.init() catch return;
        
        // 1. Generate all physical possibilities
        generatePseudoMoves(b, &pseudo_list);

        const us = b.turn;

        // 2. Filter illegal moves
        for (pseudo_list.slice()) |move| {
            // Apply move to a temporary board
            const next_board = b.makeMove(move);
            
            // Find our King's new location
            const king_bb = next_board.pieces[@intFromEnum(us)][@intFromEnum(PieceType.King)];
            
            // Sanity check: King must exist
            if (king_bb == 0) continue; 
            
            const king_sq: Square = @enumFromInt(@ctz(king_bb));

            // 3. Is the King attacked?
            if (!next_board.isSquareAttacked(king_sq, us.flip())) {
                list.append(move) catch return;
            }
        }
    }

    /// Internal: Generates moves based on geometry and blocking, ignoring King safety.
    fn generatePseudoMoves(b: Board, list: *MoveList) void {
        const us = b.turn;
        const them = us.flip();
        
        const our_pieces = b.occupancy[@intFromEnum(us)];
        const enemy_pieces = b.occupancy[@intFromEnum(them)];
        const all_pieces = b.occupancy[2];

        // Pawn Moves
        genPawnMoves(b, us, enemy_pieces, all_pieces, list);

        // Piece Moves
        const types = [_]PieceType{ .Knight, .Bishop, .Rook, .Queen, .King };
        for (types) |ptype| {
            var pieces = b.pieces[@intFromEnum(us)][@intFromEnum(ptype)];
            while (pieces != 0) {
                const from_idx = @ctz(pieces);
                const from_sq: Square = @enumFromInt(from_idx);
                
                var attacks: Bitboard = 0;
                switch (ptype) {
                    .Knight => attacks = geometry.lookups.knight[from_idx],
                    .King => attacks = geometry.lookups.king[from_idx],
                    // For sliders, we should reuse the helpers (currently duplicated in board.zig)
                    // In a real engine, these helpers live in `magic.zig` or `sliders.zig`.
                    .Bishop => attacks = getBishopAttacks(from_idx, all_pieces),
                    .Rook => attacks = getRookAttacks(from_idx, all_pieces),
                    .Queen => attacks = getBishopAttacks(from_idx, all_pieces) | getRookAttacks(from_idx, all_pieces),
                    else => unreachable,
                }

                attacks &= ~our_pieces; // Block self-capture

                while (attacks != 0) {
                    const to_idx = @ctz(attacks);
                    const to_sq: Square = @enumFromInt(to_idx);
                    
                    const is_capture = (enemy_pieces & (@as(u64, 1) << @intCast(to_idx))) != 0;
                    const flag: u4 = if (is_capture) Move.CAPTURE else Move.QUIET;

                    list.append(Move.init(from_sq, to_sq, flag)) catch return;
                    attacks &= attacks - 1;
                }
                pieces &= pieces - 1;
            }
        }
    }

    fn genPawnMoves(b: Board, us: Color, enemies: Bitboard, all: Bitboard, list: *MoveList) void {
        const pawns = b.pieces[@intFromEnum(us)][@intFromEnum(PieceType.Pawn)];
        const up: i8 = if (us == .White) 8 else -8;
        const start_rank_mask: u64 = if (us == .White) 0x000000000000FF00 else 0x00FF000000000000;
        const prom_rank_mask: u64 = if (us == .White) 0xFF00000000000000 else 0x00000000000000FF;

        var p = pawns;
        while (p != 0) {
            const from_idx = @ctz(p);
            const from_sq: Square = @enumFromInt(from_idx);
            
            // 1. Push
            const to_idx_1 = @as(i16, @intCast(from_idx)) + up;
            if (to_idx_1 >= 0 and to_idx_1 < 64) {
                const to_bit_1 = @as(u64, 1) << @intCast(to_idx_1);
                if ((to_bit_1 & all) == 0) {
                    const is_prom = (to_bit_1 & prom_rank_mask) != 0;
                    addPawnMove(from_sq, @enumFromInt(to_idx_1), is_prom, Move.QUIET, list);

                    // 2. Double Push
                    if ((@as(u64, 1) << @intCast(from_idx) & start_rank_mask) != 0) {
                        const to_idx_2 = to_idx_1 + up;
                        if ((to_idx_2 >= 0) and ((@as(u64, 1) << @intCast(to_idx_2)) & all) == 0) {
                            addPawnMove(from_sq, @enumFromInt(to_idx_2), false, Move.DOUBLE_PUSH, list);
                        }
                    }
                }
            }

            // 3. Captures
            var attacks = geometry.lookups.pawn[@intFromEnum(us)][from_idx];
            var targets = attacks & enemies;
            while (targets != 0) {
                const to_idx = @ctz(targets);
                const is_prom = ((@as(u64, 1) << @intCast(to_idx)) & prom_rank_mask) != 0;
                addPawnMove(from_sq, @enumFromInt(to_idx), is_prom, Move.CAPTURE, list);
                targets &= targets - 1;
            }

            // 4. En Passant
            if (b.ep_square) |ep_sq| {
                if ((attacks & ep_sq.bitboard()) != 0) {
                    addPawnMove(from_sq, ep_sq, false, Move.EP_CAPTURE, list);
                }
            }

            p &= p - 1;
        }
    }

    fn addPawnMove(f: Square, t: Square, prom: bool, flag: u4, list: *MoveList) void {
        if (prom) {
            const cap_offset: u4 = if (flag == Move.CAPTURE) 4 else 0;
            list.append(Move.init(f, t, Move.PROMOTE_Q + cap_offset)) catch return;
            list.append(Move.init(f, t, Move.PROMOTE_R + cap_offset)) catch return;
            list.append(Move.init(f, t, Move.PROMOTE_B + cap_offset)) catch return;
            list.append(Move.init(f, t, Move.PROMOTE_N + cap_offset)) catch return;
        } else {
            list.append(Move.init(f, t, flag)) catch return;
        }
    }

    // --- Temporary Sliders (Duplicated to avoid circular imports until common util exists) ---
    fn getRookAttacks(sq_idx: usize, blockers: u64) u64 {
        var attacks: u64 = 0;
        const rank = sq_idx / 8;
        const file = sq_idx % 8;
        var r = rank + 1;
        while (r < 8) : (r += 1) { const b = @as(u64, 1) << @intCast(r*8+file); attacks |= b; if ((b&blockers)!=0) break; }
        if (rank>0) { r=rank-1; while(true) { const b = @as(u64, 1) << @intCast(r*8+file); attacks |= b; if ((b&blockers)!=0) break; if(r==0) break; r-=1; } }
        var f = file + 1;
        while (f < 8) : (f += 1) { const b = @as(u64, 1) << @intCast(rank*8+f); attacks |= b; if ((b&blockers)!=0) break; }
        if (file>0) { f=file-1; while(true) { const b = @as(u64, 1) << @intCast(rank*8+f); attacks |= b; if ((b&blockers)!=0) break; if(f==0) break; f-=1; } }
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
                const b = @as(u64, 1) << @intCast(@as(u6, @intCast(r*8+f)));
                attacks |= b;
                if ((b & blockers) != 0) break;
                r += d[0]; f += d[1];
            }
        }
        return attacks;
    }
};

// --- Unit Tests ---

test "Legal Moves: Start Position" {
    const b = try Board.parseFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
    var moves = MoveList.init() catch unreachable;
    MoveGenerator.generateLegalMoves(b, &moves);
    
    // Initial position has exactly 20 legal moves
    try std.testing.expectEqual(@as(usize, 20), moves.len);
}

test "Legal Moves: Check Evasion" {
    // White King on E1, Black Rook on E8. White MUST move king or block.
    // ..r..
    // .....
    // ..K..
    const b = try Board.parseFen("4r3/8/8/8/8/8/4K3/8 w - - 0 1");
    var moves = MoveList.init() catch unreachable;
    MoveGenerator.generateLegalMoves(b, &moves);

    // King can move to d1, f1, d2, f2, d3, f3 (6 moves).
    // Cannot move to e2, e3 (Still attacked).
    try std.testing.expectEqual(@as(usize, 6), moves.len);
}