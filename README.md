# FENalyzer

**A High-Performance, Memory-Safe FEN Parser & Visualizer.**

FENalyzer is a robust tool designed to validate Chess [Forsyth–Edwards Notation (FEN)](https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation) strings. Built with **Zig** for maximum performance and memory safety, it serves as a strict validator for chess engines, interfaces, and databases. It includes a cross-platform CLI and a vanilla JS web visualizer.

---

## 🚀 Features

### Core Validation Engine (Zig)
The parser enforces strict adherence to chess rules, rejecting invalid states that simple regex parsers often miss:
* **Board Geometry:** Ensures exactly 8 ranks and 8 files per rank.
* **King Safety:** Validates the existence of exactly one White King and one Black King.
* **Pawn Placement:** Rejects pawns on rank 1 or 8 (illegal in standard chess).
* **Castling Rights:** Checks for syntax correctness and logic.
* **En Passant:** Validates target squares logic based on the active color.
* **Numeric Integrity:** Safe parsing of Half-move and Full-move counters.

### Polyglot Architecture
* **Core:** Zig (v0.11 - v0.13) for `O(n)` parsing speed and binary portability.
* **CLI:** Split "Build" and "Run" scripts for instant execution without recompilation overhead.
* **Viewer:** A standalone HTML/JS web interface using Base64 data injection for secure local rendering.
* **Containerization:** Multi-stage Docker build producing a minimal, secure (non-root) Alpine image.

---

## 📂 Project Structure

```text
fenalyzer/
├── fen_parser.zig       # Core Validation Logic (Source)
├── tests/               # Quality Assurance Suite
│   ├── tests.ps1        # Windows Integration Tests
│   ├── tests.sh         # Unix Integration Tests
│   ├── docker_tests.ps1 # Windows Docker Validation
│   └── docker_tests.sh  # Unix Docker Validation
├── build.sh             # Compilation Script (Linux/macOS)
├── run.sh               # Execution Script (Linux/macOS)
├── build.ps1            # Compilation Script (Windows)
├── run.ps1              # Execution Script (Windows)
├── Dockerfile           # Production Build Config
├── web/                 # Visualization Module
│   ├── index.html
│   ├── style.css
│   ├── script.js
│   └── data.js          # (Generated) Temporary data injection file
├── .gitignore
├── CHANGELOG.md
├── LICENSE
└── README.md
```

---

## 🛠️ Installation & Usage

### Prerequisites
* **Zig Compiler:** v0.11.0 up to v0.13.x (Note: v0.14+ dev builds are not supported).

### 1. Windows (PowerShell)

**Step 1: Build (Compile Once)**
```powershell
.\build.ps1
```

**Step 2: Run (Validate FEN)**
```powershell
# Validate JSON output
.\run.ps1 "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

# Validate & Open Web Viewer
.\run.ps1 -Web "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
```

### 2. Linux / macOS (Bash)

**Step 1: Build (Compile Once)**
```bash
chmod +x build.sh run.sh
./build.sh
```

**Step 2: Run (Validate FEN)**
```bash
# Validate JSON output
./run.sh "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

# Validate & Open Web Viewer
./run.sh -w "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
```

### 3. Docker Usage

Run the parser in an isolated environment without installing Zig locally.

```bash
# Build the image
docker build -t fenalyzer .

# Run validation
docker run --rm fenalyzer "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
```

---

## 🧪 Testing & Quality Assurance

The project includes a comprehensive suite of integration tests to ensure binary logic, CLI wrappers, and Docker container integrity.

**Run Integration Tests:**
```bash
# Windows
.\tests\tests.ps1

# Linux/macOS
./tests/tests.sh
```

**Run Docker Tests (Build, Security, Logic):**
```bash
# Windows
.\tests\docker_tests.ps1

# Linux/macOS
./tests/docker_tests.sh
```

---

## 📡 JSON Data Format

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