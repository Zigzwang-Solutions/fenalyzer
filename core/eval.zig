const std = @import("std");
const board_mod = @import("board.zig");
const Board = board_mod.Board;
const Color = board_mod.Color;
const PieceType = board_mod.PieceType;
const Bitboard = board_mod.Bitboard;

/// Score values in centipawns (1 pawn = 100 cp).
const Score = i32;

/// Standard material values.
const MATERIAL_VALUES = [_]Score{
    100,   // Pawn
    320,   // Knight
    330,   // Bishop
    500,   // Rook
    900,   // Queen
    20000, // King (Infinite value)
    0      // None
};

/// Piece-Square Tables (Middle Game).
/// Values are from White's perspective. Black mirrors them.
/// A1 is index 0, H8 is index 63.
const PST_PAWN = [64]Score{
     0,  0,  0,  0,  0,  0,  0,  0,
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
     5,  5, 10, 25, 25, 10,  5,  5,
     0,  0,  0, 20, 20,  0,  0,  0,
     5, -5,-10,  0,  0,-10, -5,  5,
     5, 10, 10,-20,-20, 10, 10,  5,
     0,  0,  0,  0,  0,  0,  0,  0
};

const PST_KNIGHT = [64]Score{
    -50,-40,-30,-30,-30,-30,-40,-50,
    -40,-20,  0,  0,  0,  0,-20,-40,
    -30,  0, 10, 15, 15, 10,  0,-30,
    -30,  5, 15, 20, 20, 15,  5,-30,
    -30,  0, 15, 20, 20, 15,  0,-30,
    -30,  5, 10, 15, 15, 10,  5,-30,
    -40,-20,  0,  5,  5,  0,-20,-40,
    -50,-40,-30,-30,-30,-30,-40,-50
};

// Simplified tables for other pieces (flat for now)
const PST_DEFAULT = [64]Score{ 0 } ** 64;

pub const Evaluator = struct {
    
    /// Main static evaluation function.
    /// Returns a positive value if White is winning, negative if Black is winning.
    /// The final result is returned relative to the side to move.
    pub fn evaluate(b: Board) Score {
        var score: Score = 0;

        score += evalMaterial(b, .White) - evalMaterial(b, .Black);
        score += evalPosition(b, .White) - evalPosition(b, .Black);

        // Return score relative to the side to move (Standard Engine Protocol)
        // If it's Black's turn and score is -100 (Black winning), we return +100.
        return if (b.turn == .White) score else -score;
    }

    /// Calculates total material value based on piece counts.
    fn evalMaterial(b: Board, color: Color) Score {
        var mat: Score = 0;
        const side = @intFromEnum(color);

        // Iterate over piece types (Pawn to Queen)
        // We usually skip King (5) in simple material count as it cannot be captured
        for (0..5) |i| { 
            const count = @popCount(b.pieces[side][i]);
            mat += @as(Score, @intCast(count)) * MATERIAL_VALUES[i];
        }
        return mat;
    }

    /// Calculates positional bonuses using Piece-Square Tables.
    fn evalPosition(b: Board, color: Color) Score {
        var pos_score: Score = 0;
        const side = @intFromEnum(color);

        // 1. Pawns
        var pawns = b.pieces[side][@intFromEnum(PieceType.Pawn)];
        while (pawns != 0) {
            const sq_idx = @ctz(pawns); // Get index of least significant bit (LSB)
            pos_score += getPstValue(PST_PAWN, sq_idx, color);
            pawns &= pawns - 1; // Clear LSB (move to next piece)
        }

        // 2. Knights
        var knights = b.pieces[side][@intFromEnum(PieceType.Knight)];
        while (knights != 0) {
            const sq_idx = @ctz(knights);
            pos_score += getPstValue(PST_KNIGHT, sq_idx, color);
            knights &= knights - 1;
        }

        // Future: Add Bishops, Rooks, Queens, Kings logic here

        return pos_score;
    }

    /// Fetches the PST value, mirroring the board index if the color is Black.
    fn getPstValue(table: [64]Score, index: usize, color: Color) Score {
        if (color == .White) {
            // White: Index 0 is A1. Table is mapped Rank 1..8
            return table[index];
        } else {
            // Black: Mirror the board vertically.
            // Index 0 (a1) becomes Index 56 (a8) relative to the table structure
            const rank = index / 8;
            const file = index % 8;
            const mirror_rank = 7 - rank;
            const mirror_index = (mirror_rank * 8) + file;
            return table[mirror_index];
        }
    }
};

// --- Unit Tests ---

test "Eval: Start Position Equality" {
    // The starting position should be exactly equal (Score 0)
    const fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
    const b = try Board.parseFen(fen);
    const score = Evaluator.evaluate(b);
    try std.testing.expectEqual(@as(Score, 0), score);
}

test "Eval: Material Advantage" {
    // Test position: White has an extra pawn
    const fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
    var b = try Board.parseFen(fen);
    
    // Hack: Manually add a white pawn on e4 for testing purposes
    // e4 is index 28
    const e4_bit = @as(u64, 1) << 28;
    b.pieces[@intFromEnum(Color.White)][@intFromEnum(PieceType.Pawn)] |= e4_bit;

    // Recalculate occupancies since we hacked the bitboard
    b.updateOccupancies();

    // White should be winning significantly
    const score = Evaluator.evaluate(b);
    
    // Base Pawn value (100) + PST Bonus for e4 (20) = 120
    try std.testing.expect(score >= 120); 
}