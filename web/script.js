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

    const pieceMap = {
        'r': '♜', 'n': '♞', 'b': '♝', 'q': '♛', 'k': '♚', 'p': '♟',
        'R': '♖', 'N': '♘', 'B': '♗', 'Q': '♕', 'K': '♔', 'P': '♙'
    };

    function renderGame(fen) {
        clearError();
        dom.board.innerHTML = ''; 

        // Cleanup
        const cleanFen = fen.replace(/['"]+/g, '').trim();

        const parts = cleanFen.split(' ');
        const boardFen = parts[0];
        const activeColor = parts[1] || '-';
        const fullMoves = parts[5] || '-';

        dom.fenDisplay.textContent = cleanFen;
        dom.turnValue.textContent = activeColor === 'w' ? 'White' : (activeColor === 'b' ? 'Black' : '?');
        dom.moveValue.textContent = fullMoves;

        const rows = boardFen.split('/');
        let isWhiteSquare = true;

        rows.forEach(row => {
            for (const char of row) {
                if (!isNaN(parseInt(char))) {
                    const emptyCount = parseInt(char);
                    for (let i = 0; i < emptyCount; i++) {
                        createSquare(null, isWhiteSquare);
                        isWhiteSquare = !isWhiteSquare;
                    }
                } else {
                    createSquare(pieceMap[char] || '?', isWhiteSquare);
                    isWhiteSquare = !isWhiteSquare;
                }
            }
            isWhiteSquare = !isWhiteSquare;
        });
    }

    function createSquare(piece, isWhite) {
        const div = document.createElement('div');
        div.className = `square ${isWhite ? 'light' : 'dark'}`;
        if (piece) div.textContent = piece;
        dom.board.appendChild(div);
    }

    function showError(msg) {
        dom.errorMsg.textContent = `Error: ${msg}`;
        dom.errorMsg.classList.remove('hidden');
    }
    function clearError() {
        dom.errorMsg.classList.add('hidden');
        dom.errorMsg.textContent = '';
    }

    // --- INITIALIZATION ---
    
    // Priority 1: Check injected Base64 data
    if (window.FEN_DATA_B64) {
        try {
            // SECURITY: Decode Base64 to get original FEN
            const decodedFen = atob(window.FEN_DATA_B64);
            console.log("Loaded Secure FEN:", decodedFen);
            renderGame(decodedFen);
        } catch (e) {
            showError("Failed to decode Base64 data.");
        }
    } 
    // Priority 2: Fallback to URL
    else {
        const params = new URLSearchParams(window.location.search);
        if (params.has('fen')) {
            renderGame(decodeURIComponent(params.get('fen')));
        }
    }

    dom.btnRender.addEventListener('click', () => {
        const rawInput = dom.jsonInput.value.trim();
        if (!rawInput) return;
        try {
            const data = JSON.parse(rawInput);
            if (data.valid === false) throw new Error(data.error);
            if (data.board_fen) {
                const active = data.active_color === 'white' ? 'w' : 'b';
                renderGame(`${data.board_fen} ${active} - - 0 1`);
            }
        } catch (e) {
            showError(e.message);
        }
    });
});