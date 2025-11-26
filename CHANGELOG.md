# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-11-26

### Added
- **Web Visualization Module**: Added a `web/` directory containing a lightweight, vanilla HTML5/CSS3/ES6 viewer to render validated FEN strings on a graphical board.
- **CLI Browser Integration**:
  - Added `-w` flag to `run.sh` (Linux/macOS) to automatically open the default browser with the validated FEN.
  - Added `-Web` switch to `run.ps1` (Windows) for the same functionality.
  - Implemented URL encoding logic in CLI scripts to safely pass FEN strings as query parameters.
- **Manual Debugging**: The Web Viewer now accepts pasted JSON output from the CLI to render boards or debug validation errors directly in the UI.

### Changed
- **Error Handling**: Enhanced CLI scripts to handle browser launch failures gracefully, providing fallback instructions if the browser cannot be opened automatically.

## [1.0.0] - 2025-11-26

### Added
- **Core Engine (`fen_parser.zig`)**: Initial release of the FEN parser.
  - Implemented `O(n)` parsing logic using Zig's memory-safe features (Slices, Optionals, Error Unions).
  - Added strict validation for:
    - **Board Geometry:** Verifying 8x8 grid structure and rank/file integrity.
    - **Piece Placement:** Enforcing rules against pawns on back ranks and ensuring King existence.
    - **Castling Rights:** Checking syntax validity and duplicate characters.
    - **En Passant:** Validating target squares against the active color (e.g., White to move target must be rank 6).
    - **Move Counters:** Safe integer parsing for Half-move and Full-move clocks.
- **CLI Wrappers**:
  - `run.sh`: Bash entrypoint with auto-compilation, dependency checking, and colorized output.
  - `run.ps1`: PowerShell entrypoint for native Windows support.
- **Containerization**: Added multi-stage `Dockerfile` (Alpine Linux) for minimal footprint production builds (~5MB image size).
- **Output Standard**: Defined strictly typed JSON output schema for both success and error states to facilitate integration with external tools (Python, Node.js, etc).