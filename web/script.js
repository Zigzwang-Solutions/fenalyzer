/**
 * FENalyzer Web Viewer
 * Handles FEN string parsing, board rendering, and UI updates.
 */

document.addEventListener('DOMContentLoaded', () => {
    // DOM Elements
    const dom = {
        board: document.getElementById('board'),
        fenDisplay: document.getElementById('fen-display'),
        jsonInput: document.getElementById('json-input'),
        btnRender: document.getElementById('btn-render'),
        errorMsg: document.getElementById('error-msg'),
        turnValue: document.getElementById('turn-value'),
        moveValue: document.getElementById('move-value')
    };

    // Unicode Chess Pieces Mapping
    const pieceMap = {
        'r': '♜', 'n': '♞', 'b': '♝', 'q': '♛', 'k': '♚', 'p': '♟', // Black
        'R': '♖', 'N': '♘', 'B': '♗', 'Q': '♕', 'K': '♔', 'P': '♙'  // White
    };

    /**
     * Renders the chess board based on a FEN string.
     * @param {string} fen - The full FEN string.
     */
    function renderGame(fen) {
        clearError();
        dom.board.innerHTML = ''; // Clear previous board

        const parts = fen.trim().split(' ');
        const boardFen = parts[0];
        const activeColor = parts[1] || '-';
        const fullMoves = parts[5] || '-';

        // Update Metadata UI
        dom.fenDisplay.textContent = fen;
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
            // Accessibility: screen readers can read the piece
            div.setAttribute('aria-label', getPieceName(piece)); 
        }
        dom.board.appendChild(div);
    }

    /**
     * Map Unicode to text name for Accessibility (A11y)
     */
    function getPieceName(unicode) {
        const names = {
            '♜': 'Black Rook', '♞': 'Black Knight', '♝': 'Black Bishop', '♛': 'Black Queen', '♚': 'Black King', '♟': 'Black Pawn',
            '♖': 'White Rook', '♘': 'White Knight', '♗': 'White Bishop', '♕': 'White Queen', '♔': 'White King', '♙': 'White Pawn'
        };
        return names[unicode] || 'Unknown Piece';
    }

    function showError(message) {
        dom.errorMsg.textContent = `Error: ${message}`;
        dom.errorMsg.classList.remove('hidden');
    }

    function clearError() {
        dom.errorMsg.classList.add('hidden');
        dom.errorMsg.textContent = '';
    }

    // --- Event Listeners & Initialization ---

    // 1. Check URL Parameters (from CLI automation)
    const params = new URLSearchParams(window.location.search);
    if (params.has('fen')) {
        try {
            const fen = decodeURIComponent(params.get('fen'));
            renderGame(fen);
        } catch (e) {
            showError("Could not decode FEN from URL.");
        }
    }

    // 2. Handle Manual JSON Input
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
                // Fallbacks for optional fields to reconstruct a valid FEN string
                const castling = data.castling || '-';
                const ep = data.en_passant || '-';
                const half = data.half_move !== undefined ? data.half_move : 0;
                const full = data.full_move !== undefined ? data.full_move : 1;

                const reconstructedFen = `${data.board_fen} ${active} ${castling} ${ep} ${half} ${full}`;
                renderGame(reconstructedFen);
            } else {
                throw new Error("JSON missing 'board_fen' property.");
            }

        } catch (e) {
            showError(e.message);
        }
    });
});