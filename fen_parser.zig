const std = @import("std");

/// Exhaustive set of possible errors during FEN parsing.
const FenError = error{
    InputEmpty,
    InputTooLong,
    InvalidFieldCount,
    InvalidRankCount,
    InvalidFileSum,
    InvalidPieceChar,
    InvalidConsecutiveNumbers,
    MissingKings,
    PawnsOnBackRank,
    InvalidActiveColor,
    InvalidCastlingRights,
    InvalidEnPassantSquare,
    InvalidHalfMoveClock,
    InvalidFullMoveNumber,
};

const FenState = struct {
    board_fen: []const u8,
    active_color: u8,
    castling: []const u8,
    en_passant: []const u8,
    half_move: u32,
    full_move: u32,

    pub fn toJson(self: FenState, allocator: std.mem.Allocator) ![]u8 {
        var string = std.ArrayList(u8).init(allocator);
        try std.json.stringify(.{
            .valid = true,
            .active_color = @as([]const u8, if (self.active_color == 'w') "white" else "black"),
            .castling = self.castling,
            .en_passant = self.en_passant,
            .half_move = self.half_move,
            .full_move = self.full_move,
            .board_fen = self.board_fen,
        }, .{}, string.writer());
        return string.toOwnedSlice();
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} \"<fen_string>\"\n", .{args[0]});
        std.process.exit(1);
    }

    const raw_fen = args[1];

    const result = parseFen(allocator, raw_fen) catch |err| {
        const err_msg = switch (err) {
            FenError.InputEmpty => "Input is empty",
            FenError.InputTooLong => "Input exceeds maximum allowed length",
            FenError.InvalidFieldCount => "Incorrect number of fields (expected 6)",
            FenError.InvalidRankCount => "Board must have exactly 8 ranks",
            FenError.InvalidFileSum => "One or more ranks do not sum to 8 files",
            FenError.MissingKings => "Missing kings on the board",
            FenError.PawnsOnBackRank => "Pawns found on the first or last rank",
            FenError.InvalidActiveColor => "Invalid active color (must be 'w' or 'b')",
            FenError.InvalidCastlingRights => "Invalid castling rights",
            FenError.InvalidEnPassantSquare => "Invalid En Passant square",
            error.ParseIntError => "Error parsing numeric fields (half/full moves)",
            else => "Generic invalid FEN format",
        };
        
        const stdout = std.io.getStdOut().writer();
        try stdout.print("{{\"valid\": false, \"error\": \"{s}\", \"code\": \"{s}\"}}\n", .{ err_msg, @errorName(err) });
        std.process.exit(1);
    };
    defer allocator.free(result);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{result});
}

fn parseFen(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const trimmed = std.mem.trim(u8, input, " \t\n\r");
    if (trimmed.len == 0) return FenError.InputEmpty;
    if (trimmed.len > 128) return FenError.InputTooLong;

    var it = std.mem.tokenizeScalar(u8, trimmed, ' ');
    
    const board_part = it.next() orelse return FenError.InvalidFieldCount;
    const color_part = it.next() orelse return FenError.InvalidFieldCount;
    const castling_part = it.next() orelse return FenError.InvalidFieldCount;
    const ep_part = it.next() orelse return FenError.InvalidFieldCount;
    const half_move_str = it.next() orelse return FenError.InvalidFieldCount;
    const full_move_str = it.next() orelse return FenError.InvalidFieldCount;

    if (it.next() != null) return FenError.InvalidFieldCount;

    try validateBoard(board_part);

    if (color_part.len != 1 or (color_part[0] != 'w' and color_part[0] != 'b')) {
        return FenError.InvalidActiveColor;
    }

    try validateCastling(castling_part);
    try validateEnPassant(ep_part, color_part[0]);

    const half_move = std.fmt.parseInt(u32, half_move_str, 10) catch return FenError.InvalidHalfMoveClock;
    const full_move = std.fmt.parseInt(u32, full_move_str, 10) catch return FenError.InvalidFullMoveNumber;

    const state = FenState{
        .board_fen = board_part,
        .active_color = color_part[0],
        .castling = castling_part,
        .en_passant = ep_part,
        .half_move = half_move,
        .full_move = full_move,
    };

    return state.toJson(allocator);
}

fn validateBoard(board: []const u8) !void {
    var rank_count: u8 = 0;
    var w_king: bool = false;
    var b_king: bool = false;

    var ranks_it = std.mem.splitScalar(u8, board, '/');
    while (ranks_it.next()) |rank| {
        rank_count += 1;
        if (rank_count > 8) return FenError.InvalidRankCount;

        var file_sum: u8 = 0;
        var prev_was_digit: bool = false;

        for (rank) |c| {
            if (std.ascii.isDigit(c)) {
                if (prev_was_digit) return FenError.InvalidConsecutiveNumbers;
                const val = c - '0';
                if (val == 0) return FenError.InvalidPieceChar;
                file_sum += val;
                prev_was_digit = true;
            } else {
                prev_was_digit = false;
                file_sum += 1;
                switch (c) {
                    'p', 'P' => {
                        if (rank_count == 1 or rank_count == 8) return FenError.PawnsOnBackRank;
                    },
                    'k' => { if(b_king) return FenError.InvalidPieceChar; b_king = true; },
                    'K' => { if(w_king) return FenError.InvalidPieceChar; w_king = true; },
                    'n', 'b', 'r', 'q', 'N', 'B', 'R', 'Q' => {},
                    else => return FenError.InvalidPieceChar,
                }
            }
        }
        if (file_sum != 8) return FenError.InvalidFileSum;
    }

    if (rank_count != 8) return FenError.InvalidRankCount;
    if (!w_king or !b_king) return FenError.MissingKings;
}

fn validateCastling(s: []const u8) !void {
    if (std.mem.eql(u8, s, "-")) return;
    if (s.len > 4) return FenError.InvalidCastlingRights;
    
    var seen = [_]bool{false} ** 256;
    for (s) |c| {
        switch (c) {
            'K', 'Q', 'k', 'q' => {
                if (seen[c]) return FenError.InvalidCastlingRights;
                seen[c] = true;
            },
            else => return FenError.InvalidCastlingRights,
        }
    }
}

fn validateEnPassant(s: []const u8, active_color: u8) !void {
    if (std.mem.eql(u8, s, "-")) return;
    if (s.len != 2) return FenError.InvalidEnPassantSquare;

    const file = s[0];
    const rank = s[1];

    if (file < 'a' or file > 'h') return FenError.InvalidEnPassantSquare;
    
    if (active_color == 'w') {
        if (rank != '6') return FenError.InvalidEnPassantSquare;
    } else {
        if (rank != '3') return FenError.InvalidEnPassantSquare;
    }
}