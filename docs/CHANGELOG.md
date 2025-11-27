# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.6] - 2025-11-27

### Added (Core Engine) 🧠
- **Library Architecture**: Established `src/core/` as the foundational Zig library for the engine, implementing a Bitboard-based representation independent of the CLI.
- **`src/core/board.zig`**:
  - Implemented **Bitboard** struct (64-bit integers) for high-performance state tracking.
  - Added `makeMove()` function to handle state transitions (captures, promotions, castling).
  - Added `isSquareAttacked()` for King safety and check detection.
  - Added `Move` packed struct (u16) for memory-efficient move storage.
- **`src/core/geometry.zig`**:
  - Implemented **Comptime** generation of attack tables for Leaper pieces (Knights, Kings, Pawns). This ensures zero runtime cost for geometric calculations.
- **`src/core/movegen.zig`**:
  - Implemented `generatePseudoMoves()` and `generateLegalMoves()` logic.
  - Added support for sliding pieces (Rook/Bishop/Queen) using optimized ray-casting loops.
- **`src/core/arbiter.zig`**: 
  - Added game state logic to detect Checkmate, Stalemate, 50-Move Rule, and Insufficient Material.
- **`src/core/eval.zig`**:
  - Implemented basic **Static Evaluation** function.
  - Added Material counting and Piece-Square Tables (PST) for positional scoring.

### Documentation 📚
- **Strategic Roadmap**: Complete rewrite of `docs/ROADMAP.md`. The document now formally outlines the engineering path to evolve FENalyzer from a static validator into a dynamic Chess Engine. It details specific milestones for **v0.2.0** (Core Mechanics & Zobrist), **v0.3.0** (Search & Eval), and **v0.4.0** (UCI Protocol).
- **README Compatibility**: Replaced the dynamic Mermaid.js architecture diagram in `README.md` with static ASCII art. This resolves `TAG_START` parsing errors encountered in Markdown viewers that do not support inline script execution.


## [0.1.5] - 2025-11-27

### Refactor 🏗️
- **Directory Structure Overhaul**: Massive reorganization of the project file system to declutter the root directory and enforce separation of concerns.
  - **`scripts/`**: Now houses all lifecycle automation scripts (`build.ps1`, `run.ps1`, `build.sh`, `run.sh`).
  - **`tools/`**: Dedicated folder for Python ETL scripts and data science utilities.
  - **`tests/`**: Moved all integration and docker test suites here.
  - **`docs/`**: New home for `CHANGELOG.md` and `ROADMAP.md`.
  - **`data/`**: Created for persistent SQLite storage (git-ignored).
  - **`logs/`**: Created for execution logs (git-ignored).
- **Relative Path Resolution**: Updated all moved scripts (`.ps1`, `.sh`, `.py`) to correctly resolve file paths relative to the project root (using `..` or dynamic path calculation), ensuring they function correctly regardless of the execution context.

### Added
- **Dependency Management**: Added `tools/requirements.txt` with pinned versions (e.g., `python-chess==1.9.4`) to ensure reproducible environments for the tooling layer.
- **Git Hygiene**: Added `.gitkeep` files to `data/` and `logs/` to preserve directory structure in version control without committing binary blobs or logs.

### Changed
- **Documentation Links**: Updated `README.md` to reflect the new directory structure and updated installation commands (e.g., `.\scripts\run.ps1` instead of `.\run.ps1`).


## [0.1.4] - 2025-11-27

### Security 🛡️
- **XSS Prevention (Data Injection)**: Overhauled the communication layer between the CLI (`run.ps1`) and the Web Viewer (`script.js`). The raw FEN string is now encoded in **Base64** before injection into the generated `web/data.js` file. This neutralizes potential Code Injection vectors.
- **Docker Hardening**: Refactored the `Dockerfile` runtime stage to create and switch to a non-privileged user (`appuser`) instead of running as root.

### Added
- **Quality Assurance Suite**: Established a comprehensive automated testing framework located in the `tests/` directory.
  - **Integration Tests**: `tests.ps1` and `tests.sh` validate the compiled binary against edge-case FENs.
  - **Container Tests**: `docker_tests.ps1` and `docker_tests.sh` verify the Docker image build process and security compliance.


## [0.1.3] - 2025-11-26

### Added
- **Build Scripts**: Introduced dedicated build scripts to separate compilation from execution.
- **Persistence Layer (SQLite)**: Integrated a Python-based backend (`tools/manage_db.py`) capable of storing valid FENs into a local SQLite database.
- **Serverless Web Architecture**: Implemented a "Local Data Injection" strategy via temporary `web/data.js` files, bypassing browser security restrictions on local files.

### Changed
- **CLI Workflow**: Shifted to a "Compile-Once, Run-Anywhere" model, drastically improving startup time.

### Fixed
- **Web Viewer**: Fixed an issue on Windows where browsers would strip URL query parameters from local files.


## [0.1.2] - 2025-11-26

### Fixed
- **Core Engine**: Fixed a panic in `fen_parser.zig` related to error handling scopes.
- **Windows CLI**: Fixed syntax errors in `run.ps1`, replaced legacy `.NET` dependencies with `System.Uri`, and fixed URI formatting bugs.


## [0.1.1] - 2025-11-26

### Added
- **Web Visualization Module**: Added a vanilla JS viewer with CSS Grid layout.
- **CLI Browser Integration**: Added flags to automatically open the default browser with the validated FEN.


## [0.1.0] - 2025-11-26

### Added
- **Core Engine**: Initial release of the high-performance FEN parser in Zig.
- **Docker Support**: Multi-stage Alpine Linux build.
- **Output Standard**: JSON schema definition for validation results.