/**
 * FENalyzer Web Viewer
 * Handles FEN string parsing, board rendering, and UI interactions.
 */

document.addEventListener('DOMContentLoaded', () => {
    // --- State ---
    let currentFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
    let isFlipped = false;

    // --- DOM Elements ---
    const dom = {
        board: document.getElementById('board'),
        coordsRanks: document.getElementById('coords-ranks'),
        coordsFiles: document.getElementById('coords-files'),
        fenDisplay: document.getElementById('fen-display'),
        hashId: document.getElementById('hash-id'),
        turnValue: document.getElementById('turn-value'),
        moveValue: document.getElementById('move-value'),
        jsonInput: document.getElementById('json-input'),
        btnRender: document.getElementById('btn-render'),
        btnFlip: document.getElementById('btn-flip'),
        errorMsg: document.getElementById('error-msg')
    };

    // Unicode Chess Pieces
    const pieceMap = {
        'r': '♜', 'n': '♞', 'b': '♝', 'q': '♛', 'k': '♚', 'p': '♟', // Black
        'R': '♖', 'N': '♘', 'B': '♗', 'Q': '♕', 'K': '♔', 'P': '♙'  // White
    };

    // --- Core Rendering Logic ---

    function renderBoard() {
        dom.board.innerHTML = '';
        dom.coordsRanks.innerHTML = '';
        dom.coordsFiles.innerHTML = '';

        // 1. Parse Board Geometry from FEN
        const boardPart = currentFen.split(' ')[0];
        const rows = boardPart.split('/');
        
        // 2. Expand FEN into a 64-square array
        let squares = [];
        rows.forEach(row => {
            for (const char of row) {
                if (!isNaN(parseInt(char))) {
                    for (let i = 0; i < parseInt(char); i++) squares.push(null);
                } else {
                    squares.push(char);
                }
            }
        });

        // 3. Handle Perspective (Flip)
        // Standard: Rank 8 (Index 0-7) -> Rank 1 (Index 56-63)
        // Flipped: Rank 1 -> Rank 8
        const renderOrder = isFlipped ? [...squares].reverse() : squares;

        // 4. Draw Squares
        renderOrder.forEach((piece, index) => {
            const div = document.createElement('div');
            
            // Color Logic: 0 is top-left. Row = floor(i/8), Col = i%8.
            // Even row+col = Light. Odd = Dark.
            const row = Math.floor(index / 8);
            const col = index % 8;
            const isLight = (row + col) % 2 === 0;

            div.className = `square ${isLight ? 'light' : 'dark'}`;
            if (piece) {
                div.textContent = pieceMap[piece] || piece;
                div.setAttribute('aria-label', getPieceName(piece));
            }
            dom.board.appendChild(div);
        });

        renderCoordinates();
    }

    function renderCoordinates() {
        const files = ['a','b','c','d','e','f','g','h'];
        const ranks = ['8','7','6','5','4','3','2','1'];

        // Flip logic for labels
        const displayFiles = isFlipped ? [...files].reverse() : files;
        const displayRanks = isFlipped ? [...ranks].reverse() : ranks;

        displayRanks.forEach(r => {
            const div = document.createElement('div');
            div.textContent = r;
            dom.coordsRanks.appendChild(div);
        });

        displayFiles.forEach(f => {
            const div = document.createElement('div');
            div.textContent = f;
            dom.coordsFiles.appendChild(div);
        });
    }

    function updateUI(fen, hash = "-") {
        currentFen = fen;
        dom.hashId.value = hash;

        // Parse Metadata
        const parts = fen.trim().split(' ');
        dom.fenDisplay.textContent = fen;
        
        // Active Color
        const active = parts[1] || '-';
        dom.turnValue.textContent = active === 'w' ? 'White' : (active === 'b' ? 'Black' : '-');
        
        // Move Count
        dom.moveValue.textContent = parts[5] || '-';

        renderBoard();
        clearError();
    }

    function getPieceName(char) {
        const names = {
            'p': 'Black Pawn', 'r': 'Black Rook', 'n': 'Black Knight', 'b': 'Black Bishop', 'q': 'Black Queen', 'k': 'Black King',
            'P': 'White Pawn', 'R': 'White Rook', 'N': 'White Knight', 'B': 'White Bishop', 'Q': 'White Queen', 'K': 'White King'
        };
        return names[char] || 'Piece';
    }

    function showError(msg) {
        dom.errorMsg.textContent = `Error: ${msg}`;
        dom.errorMsg.classList.remove('hidden');
    }

    function clearError() {
        dom.errorMsg.classList.add('hidden');
        dom.errorMsg.textContent = '';
    }

    // --- Initialization Strategy ---

    function init() {
        // Priority 1: Check for Base64 Data Injection (Secure local method)
        if (window.FEN_DATA_B64) {
            try {
                const decodedFen = atob(window.FEN_DATA_B64);
                const hash = window.FEN_HASH || "generated-local";
                console.log("Loaded Secure FEN from data.js");
                updateUI(decodedFen, hash);
                return;
            } catch (e) {
                console.error("Base64 decode failed:", e);
                showError("Failed to decode injected data.");
            }
        }

        // Priority 2: Fallback to URL Query/Hash (Legacy/Server method)
        const rawParams = window.location.search || window.location.hash.substring(1);
        const params = new URLSearchParams(rawParams);
        
        if (params.has('fen')) {
            try {
                const fen = decodeURIComponent(params.get('fen'));
                updateUI(fen);
            } catch (e) {
                showError("Invalid FEN in URL.");
            }
        } else {
            // Priority 3: Default Start Position
            updateUI(currentFen);
        }
    }

    // --- Event Listeners ---

    dom.btnFlip.addEventListener('click', () => {
        isFlipped = !isFlipped;
        renderBoard();
    });

    dom.btnRender.addEventListener('click', () => {
        const rawInput = dom.jsonInput.value.trim();
        if (!rawInput) return;

        try {
            const data = JSON.parse(rawInput);
            if (data.valid === false) throw new Error(data.error || "Invalid FEN");

            if (data.board_fen) {
                const active = data.active_color === 'white' ? 'w' : 'b';
                // Reconstruct simple FEN
                const fullFen = `${data.board_fen} ${active} - - 0 1`;
                updateUI(fullFen, "manual-input");
            } else {
                throw new Error("JSON missing 'board_fen'");
            }
        } catch (e) {
            showError(e.message);
        }
    });

    // Run Init
    init();
});