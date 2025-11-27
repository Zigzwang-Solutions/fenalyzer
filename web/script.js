/**
 * FENalyzer Web Viewer
 * Handles FEN string parsing, board rendering, and UI updates.
 */

document.addEventListener('DOMContentLoaded', () => {
    // DOM Elements
    const dom = {
        board: document.getElementById('board'),
        fenDisplay: document.getElementById('fen-display'),
        turnValue: document.getElementById('turn-value'),
        moveValue: document.getElementById('move-value'),
        jsonInput: document.getElementById('json-input'),
        btnRender: document.getElementById('btn-render'),
        errorMsg: document.getElementById('error-msg')
    };

    // Unicode Chess Pieces Mapping
    const pieceMap = {
        'r': '♜', 'n': '♞', 'b': '♝', 'q': '♛', 'k': '♚', 'p': '♟', // Black
        'R': '♖', 'N': '♘', 'B': '♗', 'Q': '♕', 'K': '♔', 'P': '♙'  // White
    };

    /**
     * Renders the chess board based on a FEN string.
     */
    function renderGame(fen) {
        clearError();
        dom.board.innerHTML = ''; 

        // Safe cleanup if FEN is messy or has extra quotes
        const cleanFen = fen.replace(/['"]+/g, '').trim();

        const parts = cleanFen.split(' ');
        const boardFen = parts[0];
        const activeColor = parts[1] || '-';
        const fullMoves = parts[5] || '-';

        // Update Metadata UI
        dom.fenDisplay.textContent = cleanFen;
        dom.turnValue.textContent = activeColor === 'w' ? 'White' : (activeColor === 'b' ? 'Black' : '?');
        dom.moveValue.textContent = fullMoves;

        // Render Board Grid
        const rows = boardFen.split('/');
        let isWhiteSquare = true;

        rows.forEach(row => {
            for (const char of row) {
                if (!isNaN(parseInt(char))) {
                    // It's a number representing empty squares
                    const emptyCount = parseInt(char);
                    for (let i = 0; i < emptyCount; i++) {
                        createSquare(null, isWhiteSquare);
                        isWhiteSquare = !isWhiteSquare;
                    }
                } else {
                    // It's a piece character
                    createSquare(pieceMap[char] || '?', isWhiteSquare);
                    isWhiteSquare = !isWhiteSquare;
                }
            }
            // Flip color at the end of the rank to maintain checker pattern
            isWhiteSquare = !isWhiteSquare;
        });
    }

    /**
     * Helper to create a single DOM square.
     */
    function createSquare(piece, isWhite) {
        const div = document.createElement('div');
        div.className = `square ${isWhite ? 'light' : 'dark'}`;
        if (piece) {
            div.textContent = piece;
            // Accessibility
            div.setAttribute('aria-label', piece); 
        }
        dom.board.appendChild(div);
    }

    function showError(message) {
        dom.errorMsg.textContent = `Error: ${message}`;
        dom.errorMsg.classList.remove('hidden');
    }

    function clearError() {
        dom.errorMsg.classList.add('hidden');
        dom.errorMsg.textContent = '';
    }

    // --- INITIALIZATION LOGIC ---
    
    // Priority 1: Check if PowerShell injected data into window.FEN_DATA
    if (window.FEN_DATA) {
        console.log("Loading FEN from local data.js:", window.FEN_DATA);
        renderGame(window.FEN_DATA);
    } 
    // Priority 2: Fallback to URL parameters (useful if hosted on a web server)
    else {
        const params = new URLSearchParams(window.location.search);
        if (params.has('fen')) {
            renderGame(decodeURIComponent(params.get('fen')));
        }
    }

    // Manual JSON Input Handler
    dom.btnRender.addEventListener('click', () => {
        const rawInput = dom.jsonInput.value.trim();
        if (!rawInput) return;

        try {
            const data = JSON.parse(rawInput);

            if (data.valid === false) {
                throw new Error(data.error || "JSON marked as invalid by parser.");
            }

            // Construct FEN from JSON object if strict fields exist
            if (data.board_fen) {
                const active = data.active_color === 'white' ? 'w' : 'b';
                // Use defaults for visualization if fields are missing
                const reconstructedFen = `${data.board_fen} ${active} - - 0 1`;
                renderGame(reconstructedFen);
            } else {
                throw new Error("JSON missing 'board_fen' property.");
            }

        } catch (e) {
            showError(e.message);
        }
    });
});