# Project Roadmap

This document outlines the strategic development trajectory for FENalyzer.
**Current Stable Version:** v0.1.6

---

## 🚧 v0.2.0 - The Rule Master (Core Mechanics)
**Goal:** Evolve from a static FEN validator to a dynamic Chess State Machine capable of making moves, detecting checks, and maintaining game history.

### 🧠 Core Architecture (Zig)
- [ ] **Modular Refactor:** Fully migrate `fen_parser.zig` (CLI) to use the new `src/core/` library (`board.zig`, `movegen.zig`, `geometry.zig`).
- [ ] **Incremental Zobrist Hashing:** Implement "True" Zobrist Hashing in `board.zig`. The hash must update incrementally with `makeMove` (XOR operations) rather than re-calculating SHA-256 from scratch.
- [ ] **Strict Legality:** Implement `generateLegalMoves` by filtering pseudo-legal moves that leave the King in check.
- [ ] **Perft Test Suite:** Implement a **Perft (Performance Test)** module to verify move generation accuracy against millions of known positions (e.g., Kiwipete).

### 🛠️ Tooling & Scripts
- [ ] **Perft CLI:** Add a command `run.ps1 -Perft <depth>` to benchmark the engine's speed and accuracy.

---

## 🤖 v0.3.0 - The Thinker (Search & Evaluation)
**Goal:** Implement the artificial intelligence layer to allow the engine to evaluate positions and look ahead.

### 🔍 Search Engine (`src/engine/search.zig`)
- [ ] **Alpha-Beta Pruning:** Implement the standard Minimax algorithm with Alpha-Beta pruning to discard bad branches.
- [ ] **Iterative Deepening:** Implement time management logic to search depth 1, then 2, then 3, allowing interruption at any time.
- [ ] **Quiescence Search (QS):** mitigate the "Horizon Effect" by continuing to search capture sequences until a quiet position is reached.

### 📊 Evaluation Function (`src/engine/eval.zig`)
- [ ] **Material Balance:** Efficient piece counting using `popcount`.
- [ ] **Piece-Square Tables (PST):** Implement mid-game and end-game tables for positional intuition.
- [ ] **Mobility & Safety:** Use `movegen` data to reward active pieces and penalize exposed Kings.

---

## 🗣️ v0.4.0 - The Interface (UCI Protocol)
**Goal:** Make the engine compatible with Chess GUIs (Arena, Banksia, Lichess) via standard communication protocol.

### 🔌 UCI Layer (`src/uci/`)
- [ ] **Main Loop:** Create a loop that reads `stdin` and prints to `stdout`.
- [ ] **Commands:** Implement `uci`, `isready`, `ucinewgame`, `position`, `go`, `stop`, `quit`.
- [ ] **Time Management:** Parse `wtime`, `btime`, `winc`, `binc` to allocate thinking time smartly.

---

## 🏆 v1.0.0 - The Competitor (Optimization & Stability)
**Goal:** Reach "Club Player" strength (~2000 ELO) and code stability.

### ⚡ Performance Optimization
- [ ] **Transposition Table (TT):** Use the Zobrist Hash to store search results in RAM, avoiding re-calculation of identical positions reached via different move orders.
- [ ] **Move Ordering:** Implement MVV-LVA (Most Valuable Victim - Least Valuable Aggressor) and Killer Heuristics to improve Alpha-Beta cutoffs.
- [ ] **Magic Bitboards:** Replace current "Ray Casting" loop logic for sliders (Rook/Bishop) with O(1) Magic Bitboard lookups.

### 📦 Ecosystem
- [ ] **API Freeze:** Finalize the JSON output format for the Validator tool.
- [ ] **Full Documentation:** Complete architectural documentation in `docs/`.