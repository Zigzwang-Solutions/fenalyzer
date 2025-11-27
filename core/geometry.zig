const std = @import("std");
const board = @import("board.zig");
const Bitboard = board.Bitboard;
const Square = board.Square;
const Color = board.Color;

/// Pre-computed geometry tables.
/// These define the physical reach of pieces on an empty board.
pub const GeometryTables = struct {
    knight: [64]Bitboard,
    king: [64]Bitboard,
    pawn: [2][64]Bitboard, // [Color][Square]

    /// This function is executed entirely by the compiler.
    /// It returns a fully populated struct to be embedded in the binary.
    pub fn init() GeometryTables {
        // We use @setEvalBranchQuota to ensure the compiler has enough 
        // iterations allowed to compute all 64 squares if necessary.
        @setEvalBranchQuota(10000);

        var tables = GeometryTables{
            .knight = [_]u64{0} ** 64,
            .king = [_]u64{0} ** 64,
            .pawn = [_][64]u64{[_]u64{0} ** 64} ** 2,
        };

        // Compile-time loop over all 64 squares
        for (0..64) |i| {
            const sq: Square = @enumFromInt(i);
            
            tables.knight[i] = genKnightMoves(sq);
            tables.king[i] = genKingMoves(sq);
            
            // Generate Pawn Capture Geometry (Diagonals)
            tables.pawn[@intFromEnum(Color.White)][i] = genPawnCaptures(sq, .White);
            tables.pawn[@intFromEnum(Color.Black)][i] = genPawnCaptures(sq, .Black);
        }

        return tables;
    }
};

/// THE GLOBAL LOOKUP TABLE
/// The assignment to 'comptime' forces execution during compilation.
/// At runtime, this is just a block of read-only memory (.rodata).
pub const lookups: GeometryTables = comptime GeometryTables.init();


// --- Generator Functions (Execution: Compile-Time Only) ---

/// File masks used to prevent pieces from wrapping around the board.
/// Defined as 'comptime' constants to ensure they are immediate values.
const not_a_file: u64 = 0xfefefefefefefefe; // ~File A
const not_h_file: u64 = 0x7f7f7f7f7f7f7f7f; // ~File H
const not_ab_file: u64 = 0xfcfcfcfcfcfcfcfc; // ~File A & B
const not_gh_file: u64 = 0x3f3f3f3f3f3f3f3f; // ~File G & H

fn genKnightMoves(sq: Square) Bitboard {
    var moves: Bitboard = 0;
    const bit = sq.bitboard();

    // North Shifts (<<)
    moves |= (bit << 17) & not_a_file; // North-North-East
    moves |= (bit << 10) & not_ab_file; // North-East-East
    moves |= (bit << 15) & not_h_file; // North-North-West
    moves |= (bit << 6)  & not_gh_file; // North-West-West

    // South Shifts (>>)
    moves |= (bit >> 17) & not_h_file; // South-South-West
    moves |= (bit >> 10) & not_gh_file; // South-West-West
    moves |= (bit >> 15) & not_a_file; // South-South-East
    moves |= (bit >> 6)  & not_ab_file; // South-East-East

    return moves;
}

fn genKingMoves(sq: Square) Bitboard {
    var moves: Bitboard = 0;
    const bit = sq.bitboard();

    // Horizontal clips
    const west = (bit >> 1) & not_h_file; // Careful: bit shifting right moves towards A, but if we are on H... wait.
    // Correction: In Little Endian (a1=0), moving West is (-1). 
    // If we are on File A, (bit >> 1) wraps to previous rank's H file? No, just shifts.
    // We just need to ensure we don't calculate neighbors if we are on the edge.
    
    // Let's use a simpler "Spot" approach safe for comptime
    
    // West neighbor (check if not on File A)
    let w = if ((bit & ~not_a_file) == 0) (bit >> 1) else 0;
    
    // East neighbor (check if not on File H)
    let e = if ((bit & ~not_h_file) == 0) (bit << 1) else 0;

    const row = bit | w | e;

    moves |= row << 8; // North neighbors
    moves |= row >> 8; // South neighbors
    moves |= w | e;    // Horizontal neighbors

    return moves;
}

fn genPawnCaptures(sq: Square, color: Color) Bitboard {
    // Note: This calculates geometrical CAPTURE targets (diagonals).
    // Push moves are generated dynamically based on blockers.
    var attacks: Bitboard = 0;
    const bit = sq.bitboard();

    switch (color) {
        .White => {
            // North West (7) - Requires not File A
            if ((bit & ~not_a_file) == 0) attacks |= (bit << 7);
            // North East (9) - Requires not File H
            if ((bit & ~not_h_file) == 0) attacks |= (bit << 9);
        },
        .Black => {
            // South East (7) - Requires not File H
            // Note: Down-right from b8(57) is c7(50). 57-50 = 7. 
            // Correct shift is >> 7.
            if ((bit & ~not_h_file) == 0) attacks |= (bit >> 7);
            
            // South West (9) - Requires not File A
            if ((bit & ~not_a_file) == 0) attacks |= (bit >> 9);
        },
    }
    return attacks;
}

// --- Comptime Verification Tests ---

test "Geometry: Comptime Execution" {
    // This test ensures the lookup table is actually usable
    const e4 = try board.Square.parse("e4"); // Index 28
    const knight_moves = lookups.knight[@intFromEnum(e4)];
    
    // Verify a specific target: f6 (Index 45)
    const f6_bit = (try board.Square.parse("f6")).bitboard();
    
    try std.testing.expect((knight_moves & f6_bit) != 0);
}

test "Geometry: Boundary Checks" {
    // King on h1 (Index 7) should not attack a1 or a2
    const h1 = try board.Square.parse("h1");
    const king_moves = lookups.king[@intFromEnum(h1)];
    
    const a1_bit = (try board.Square.parse("a1")).bitboard();
    
    try std.testing.expect((king_moves & a1_bit) == 0);
}