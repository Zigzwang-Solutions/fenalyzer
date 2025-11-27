import chess.pgn
import sqlite3
import sys
import os
import hashlib

# --- Path Configuration ---
# Robust relative path: ../data/positions.db
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(CURRENT_DIR)
DB_PATH = os.path.join(ROOT_DIR, "data", "positions.db")

def setup_database():
    """Ensures the data directory and database file exist."""
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    # Optimized table for fast Hash lookups
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS positions (
            hash_id TEXT PRIMARY KEY,
            fen TEXT NOT NULL
        )
    ''')
    conn.commit()
    return conn

def generate_id(fen):
    """Generates a unique ID (Zobrist-like) via SHA-256."""
    return hashlib.sha256(fen.encode('utf-8')).hexdigest()[:16]

def process_pgn(pgn_path):
    # If the PGN path is not absolute, assume it is relative to the current execution directory
    if not os.path.exists(pgn_path):
        # Fallback: try searching in the project root
        fallback_path = os.path.join(ROOT_DIR, pgn_path)
        if os.path.exists(fallback_path):
            pgn_path = fallback_path
        else:
            print(f"[ERROR] File not found: {pgn_path}")
            return

    conn = setup_database()
    cursor = conn.cursor()
    
    print(f"[INFO] Reading: {pgn_path}")
    print(f"[INFO] Destination: {DB_PATH}")
    
    games = 0
    positions = 0
    
    with open(pgn_path, "r", encoding="utf-8") as pgn_file:
        while True:
            try:
                game = chess.pgn.read_game(pgn_file)
            except ValueError:
                continue # Skip corrupted games

            if game is None: break
            
            games += 1
            board = game.board()
            batch = []
            
            # Add initial position
            batch.append((generate_id(board.fen()), board.fen()))
            
            # Process moves
            for move in game.mainline_moves():
                board.push(move)
                batch.append((generate_id(board.fen()), board.fen()))
            
            # Bulk Insert ignoring duplicates
            cursor.executemany("INSERT OR IGNORE INTO positions (hash_id, fen) VALUES (?, ?)", batch)
            positions += len(batch)
            
            # Commit every 50 games to manage memory usage
            if games % 50 == 0:
                conn.commit()
                print(f"Games: {games} | Positions: {positions}...", end="\r")

    conn.commit()
    conn.close()
    print(f"\n[SUCCESS] Import completed! Total positions processed: {positions}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python tools/pgn_to_sqlite.py <pgn_file>")
    else:
        process_pgn(sys.argv[1])