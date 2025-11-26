# FENalyzer

**A High-Performance, Memory-Safe FEN Parser & Visualizer.**

FENalyzer is a robust tool designed to validate Chess [Forsyth–Edwards Notation (FEN)](https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation) strings. Built with **Zig** for maximum performance and memory safety, it serves as a strict validator for chess engines, interfaces, and databases. It includes a cross-platform CLI and a vanilla JS web visualizer.

---

## 🚀 Features

### Core Validation Engine (Zig)
The parser enforces strict adherence to chess rules, rejecting invalid states that simple regex parsers often miss:
* **Board Geometry:** Ensures exactly 8 ranks and 8 files per rank (summing pieces and empty squares).
* **King Safety:** Validates the existence of exactly one White King and one Black King.
* **Pawn Placement:** Rejects pawns on rank 1 or 8 (illegal in standard chess).
* **Castling Rights:** Checks for syntax correctness, duplication, and prevents rights for non-existent pieces.
* **En Passant:** Validates target squares logic based on the active color (e.g., White to move implies target must be on rank 6).
* **Numeric Integrity:** Safe parsing of Half-move and Full-move counters preventing integer overflows.

### Polyglot Architecture
* **Core:** Zig (v0.11+) for `O(n)` parsing speed and binary portability.
* **CLI:** Bash (Linux/macOS) and PowerShell (Windows) wrappers for automated building and execution.
* **Viewer:** A standalone, dependency-free HTML/JS web interface to visualize validated FENs.
* **Containerization:** Multi-stage Docker build producing a minimal Alpine image.

---

## 📂 Project Structure

```text
fenalyzer/
├── fen_parser.zig       # Core Validation Logic (Source)
├── run.sh               # CLI Entrypoint (Linux/macOS)
├── run.ps1              # CLI Entrypoint (Windows)
├── Dockerfile           # Production Build Config
├── requirements.txt     # System Dependencies Manifest
├── web/                 # Visualization Module
│   ├── index.html
│   ├── style.css
│   └── script.js
├── .gitignore
├── CHANGELOG.md
├── LICENSE
└── README.md
```

---

## 🛠️ Installation & Usage

### Prerequisites
* **Zig Compiler:** v0.11.0 or newer.
* **Python 3:** (Optional, Linux only) Recommended for safe URL encoding when using the Web Viewer via CLI.

### 1. CLI Usage (Local)

The wrapper scripts automatically compile the Zig binary (ReleaseSafe mode) on the first run.

**Linux / macOS:**
```bash
chmod +x run.sh

# Validate only (JSON output)
./run.sh "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

# Validate and Open in Browser
./run.sh -w "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
```

**Windows (PowerShell):**
```powershell
# Validate only
.\run.ps1 "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

# Validate and Open in Browser
.\run.ps1 -Web "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
```

### 2. Docker Usage

Run the parser in an isolated environment without installing Zig locally.

```bash
# Build the image
docker build -t fenalyzer .

# Run validation
docker run --rm fenalyzer "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
```

---

## 📡 JSON Data Format

The tool outputs structured JSON for easy integration with other software pipelines.

**Success Response:**
```json
{
  "valid": true,
  "active_color": "white",
  "castling": "KQkq",
  "en_passant": "-",
  "half_move": 0,
  "full_move": 1,
  "board_fen": "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR"
}
```

**Error Response:**
```json
{
  "valid": false,
  "error": "Pawns found on the first or last rank",
  "code": "PawnsOnBackRank"
}
```

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.  
Copyright © 2025 **Zigzwang-Solutions**.