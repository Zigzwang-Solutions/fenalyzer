# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.3] - 2025-11-26

### Added
- **Build Scripts**: Introduced dedicated build scripts (`build.ps1` for Windows, `build.sh` for Unix) to separate the compilation process from the execution process.
- **Local Data Injection**: Implemented a strategy in `run.ps1` to generate a temporary `web/data.js` file containing the FEN data. This allows the Web Viewer to bypass modern browser security restrictions that strip query parameters from local file (`file://`) protocols.

### Changed
- **Architecture**: Refactored the CLI workflow to "Compile Once, Run Anywhere". Users must now explicitly run the build script once before using the run script, significantly improving execution speed by removing redundant compilation checks.
- **Documentation**: Updated `README.md` to reflect the new "Build -> Run" workflow and clarified Zig compiler version compatibility (v0.11 - v0.13).

### Fixed
- **Web Viewer**: Fixed an issue where the chess board would fail to render on Windows because browsers (Edge/Chrome) stripped URL parameters from local files. The new data injection strategy resolves this completely.

## [0.1.2] - 2025-11-26

### Fixed
- **Core Engine (`fen_parser.zig`)**: Fixed a compilation error regarding unreachable error handling in `main`. The parser now correctly exposes `FenError.InvalidHalfMoveClock` and `FenError.InvalidFullMoveNumber` instead of swallowing the internal `ParseIntError`.
- **PowerShell CLI (`run.ps1`)**:
  - **Syntax Error**: Moved the `param` block to the top of the script to comply with PowerShell strict mode requirements.
  - **Crash on Launch**: Replaced the legacy `System.Web` assembly dependency with `[System.Uri]`, preventing crashes on systems where the web assembly is missing or incompatible.
  - **URL Formatting**: Fixed a bug where using Windows file paths (backslashes) caused browsers to strip the `?fen=...` query parameters. The script now correctly converts paths to standard file URIs (`file:///...`).
  - **Browser Launch**: Implemented a more robust browser launch strategy using `cmd /c start` and added a fallback that prints the full clickable URL to the terminal if the automatic launch fails.
- **Documentation**: Updated `README.md` to restrict supported Zig versions to v0.11.0 through v0.13.x, warning users against using v0.14+ (nightly/dev) builds due to breaking standard library changes.

## [0.1.1] - 2025-11-26

### Added
- **Web Visualization Module**: Added a `web/` directory containing a lightweight, vanilla HTML5/CSS3/ES6 viewer to render validated FEN strings on a graphical board.
- **CLI Browser Integration**:
  - Added `-w` flag to `run.sh` (Linux/macOS) to automatically open the default browser with the validated FEN.
  - Added `-Web` switch to `run.ps1` (Windows) for the same functionality.
  - Implemented URL encoding logic in CLI scripts to safely pass FEN strings as query parameters.
- **Manual Debugging**: The Web Viewer now accepts pasted JSON output from the CLI to render boards or debug validation errors directly in the UI.

### Changed
- **Error Handling**: Enhanced CLI scripts to handle browser launch failures gracefully, providing fallback instructions if the browser cannot be opened automatically.

## [0.1.0] - 2025-11-26

### Added
- **Core Engine (`fen_parser.zig`)**: Initial release of the FEN parser.
  - Implemented `O(n)` parsing logic using Zig's memory-safe features (Slices, Optionals, Error Unions).
  - Added strict validation for:
    - **Board Geometry:** Verifying 8x8 grid structure and rank/file integrity.
    - **Piece Placement:** Enforcing rules against pawns on back ranks and ensuring King existence.
    - **Castling Rights:** Checking syntax validity and duplicate characters.
    - **En Passant:** Validating target squares against the active color.
    - **Move Counters:** Safe integer parsing for Half-move and Full-move clocks.
- **CLI Wrappers**:
  - `run.sh`: Bash entrypoint with auto-compilation, dependency checking, and colorized output.
  - `run.ps1`: PowerShell entrypoint for native Windows support.
- **Containerization**: Added multi-stage `Dockerfile` (Alpine Linux) for minimal footprint production builds (~5MB image size).
- **Output Standard**: Defined strictly typed JSON output schema for both success and error states to facilitate integration with external tools (Python, Node.js, etc).