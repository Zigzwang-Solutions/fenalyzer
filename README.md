# FENalyzer

**A High-Performance, Memory-Safe Chess FEN Engine & Data Pipeline.**

FENalyzer is more than just a validator; it is a comprehensive toolkit for processing, storing, and visualizing Chess [Forsyth–Edwards Notation (FEN)](https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation). 

Built on a **Zig** core for maximum performance and safety, it orchestrates a hybrid environment using **Python** for ETL (Extract, Transform, Load) operations and **PowerShell/Bash** for automation, all connected to a serverless **Web Viewer**.

---

## 🏛️ System Architecture

The project operates on a "Compile Once, Run Anywhere" philosophy with a decoupled architecture:

```mermaid
graph TD
    User((User)) -->|CLI Commands| Script[Orchestrator (run.ps1/sh)]
    
    subgraph "Core Layer (Zig)"
        Script -->|Executes| Binary[fen_parser.exe]
        Binary -->|Validates| JSON[JSON Output]
    end
    
    subgraph "Data Layer (Python + SQLite)"
        Script -->|Hashes & Stores| PY[tools/manage_db.py]
        PY <-->|Persists| DB[(data/positions.db)]
    end
    
    subgraph "Presentation Layer (Web)"
        Script -->|Injects Base64| DataFile[web/data.js]
        Browser[Web Viewer] -->|Reads| DataFile
    end
```

---

## 🚀 Key Features

### ⚡ Core Engine (Zig)
* **Memory Safety:** Written in Zig to prevent buffer overflows and memory leaks.
* **O(n) Performance:** Single-pass parsing logic for high-throughput processing.
* **Strict Validation:** Enforces complex rules including King safety, pawn rank limits, and En Passant logic legality.

### 🐍 Data Pipeline (Python)
* **PGN Ingestion:** Tools to parse massive PGN files (`.pgn`) and extract millions of unique FENs.
* **Deduplication:** Automatic hashing (SHA-256) to prevent duplicate positions in the database.
* **SQLite Integration:** A zero-config, serverless database to store position history permanently.

### 🌐 Secure Web Viewer
* **Serverless:** Runs entirely in the browser via `file://` protocol.
* **Secure Injection:** Uses **Base64 encoding** to pass data from the CLI to the Browser, neutralizing XSS vectors.
* **Responsive UI:** CSS Grid layout with Board Flip capabilities and coordinate systems.

---

## 📂 Project Structure

```text
fenalyzer/
├── fen_parser.zig       # [CORE] The Zig Source Code
├── scripts/             # [CLI] Automation & Orchestration
│   ├── build.ps1        # Compiles Zig binary (Windows)
│   └── run.ps1          # Main Entrypoint (Windows)
├── tools/               # [ETL] Python Data Science Tools
│   ├── pgn_to_sqlite.py # Bulk Import PGN -> SQLite
│   └── manage_db.py     # Database CRUD Bridge
├── data/                # [DB] Persistent Storage (SQLite)
├── web/                 # [UI] Frontend Viewer
│   └── data.js          # Generated data injection file
├── tests/               # [QA] Automated Test Suite
├── logs/                # [LOGS] Execution logs
├── docs/                # Documentation & Roadmap
├── Dockerfile           # Secure Multi-stage Build config
└── README.md            # You are here
```

---

## 🛠️ Installation & Usage

### Prerequisites
* **Zig Compiler:** v0.11.0 - v0.13.x (Required for Core).
* **Python 3.x:** Required for Database Persistence and PGN tools.
* **Docker:** (Optional) For containerized execution.

### 1. Windows (PowerShell)

**Step 1: Build the Core (Run once)**
```powershell
.\scripts\build.ps1
```

**Step 2: Validate & Visualize**
This command validates the FEN, saves it to the SQLite DB, and opens the viewer.
```powershell
.\scripts\run.ps1 -Web "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
```

### 2. Linux / macOS (Bash)

**Step 1: Build**
```bash
chmod +x scripts/*.sh
./scripts/build.sh
```

**Step 2: Run**
```bash
./scripts/run.sh -w "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
```

---

## 🧪 Testing & Quality Assurance

We enforce code quality through a dedicated test suite located in `tests/`.

* **Integration Tests:** Verify that the Zig binary handles edge cases correctly (valid/invalid FENs).
* **Docker Tests:** Verify the build process and ensure the container runs as a **non-root user** (`appuser`) for security compliance.

**Run the Suite:**
```bash
# Windows
.\tests\tests.ps1
.\tests\docker_tests.ps1

# Linux
./tests/tests.sh
```

---

## 📊 Data Science Tools

Populate your local database with millions of real-world positions using the Python tools.

1.  **Install Dependencies:**
    ```bash
    pip install -r tools/requirements.txt
    ```

2.  **Bulk Import PGN:**
    ```bash
    python tools/pgn_to_sqlite.py path/to/my_games.pgn
    ```
    *This will process the PGN and create/update `data/positions.db` automatically.*

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.  
Copyright © 2025 **Zigzwang-Solutions**.