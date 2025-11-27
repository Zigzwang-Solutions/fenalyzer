const std = @import("std");
const board_mod = @import("board.zig");
const movegen = @import("movegen.zig");

const Board = board_mod.Board;
const Color = board_mod.Color;

pub const GameState = enum {
    Ongoing,
    Checkmate,
    Stalemate,
    DrawRepetition,
    DrawInsufficientMaterial,
    DrawFiftyMove,
};

pub const Arbiter = struct {
    
    /// Verifica o estado final do jogo.
    /// Exige gerar lances legais para saber se há mate/afogamento.
    pub fn checkGameState(b: Board, history: []const u64) GameState {
        // 1. Regra dos 50 lances
        if (b.half_move >= 100) return .DrawFiftyMove;

        // 2. Repetição (Requer Hash Zobrist no histórico)
        // if (countRepetitions(b.hash, history) >= 3) return .DrawRepetition;

        // 3. Insuficiência Material
        if (isInsufficientMaterial(b)) return .DrawInsufficientMaterial;

        // 4. Mate ou Afogamento
        // Precisamos tentar gerar lances. Se não houver lances legais:
        var moves = movegen.MoveList.init();
        movegen.MoveGenerator.generateLegalMoves(b, &moves);

        if (moves.len == 0) {
            // Sem lances legais. É xeque?
            const king_sq = getKingSquare(b, b.turn); // Helper needed
            if (b.isSquareAttacked(king_sq, b.turn.flip())) {
                return .Checkmate;
            } else {
                return .Stalemate;
            }
        }

        return .Ongoing;
    }

    fn isInsufficientMaterial(b: Board) bool {
        // Popcount total das peças
        const w_pieces = @popCount(b.occupancy[0]);
        const b_pieces = @popCount(b.occupancy[1]);
        
        // K vs K
        if (w_pieces == 1 and b_pieces == 1) return true;
        
        // K+N vs K or K+B vs K (Simplificado)
        if (w_pieces + b_pieces == 3) {
            // Verifica se não há Damas, Torres ou Peões
            // ... lógica detalhada ...
            return true;
        }
        return false;
    }
};