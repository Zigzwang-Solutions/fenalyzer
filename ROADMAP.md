# Project Roadmap

This document outlines the strategic development trajectory for FENalyzer.
**Current Stable Version:** v0.1.3

---

## 🚧 v0.1.4 - Persistence & UI Overhaul (Next Release)
**Goal:** Transform the viewer from a temporary visualizer into a persistent FEN database with enhanced user experience.

### 💾 Core: Hash-Based Persistence
The goal is to allow saving and sharing of positions, rather than just transient visualization.
- [ ] **SHA-256 Identification**: Implement logic in `run.ps1` to calculate a unique 16-char Hash (Zobrist-like) from the FEN string.
- [ ] **Permanent Storage**: Change storage strategy from temporary (`web/data.js`) to a persistent database folder (`web/data/<hash>.js`).
- [ ] **Load-by-Hash**: Update `script.js` to dynamically load positions based on the URL Hash (e.g., `index.html#id=a1b2c3d4...`).

### 🎨 Frontend: Visual Enhancements
- [ ] **Board Coordinates**: Implement a CSS Grid layout to display Ranks (1-8) and Files (A-H) around the board.
- [ ] **Perspective Rotation**: Add a "Flip Board" button to toggle between White and Black perspectives (reversing rendering order and coordinates).
- [ ] **Responsive Layout**: Ensure coordinates adjust correctly on smaller screens.

---

## 🔮 Future Versions

### v0.2.0 - Engine Integration
- [ ] **UCI Protocol**: Implement a wrapper to allow Chess GUIs (Arena, Banksia) to communicate with FENalyzer as a validation engine.
- [ ] **Move Validation**: Expand Zig core to validate if specific moves (like Castling or En Passant) are legally possible given the board geometry.