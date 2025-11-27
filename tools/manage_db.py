import sqlite3
import sys
import os

# --- Path Configuration ---
# 1. Get the directory where this script is located (/tools)
# 2. Go up one level to the project root (..)
# 3. Define the database path at /data/positions.db
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(CURRENT_DIR)
DB_PATH = os.path.join(ROOT_DIR, "data", "positions.db")

def get_db():
    """Connects to the database and creates the table if it doesn't exist."""
    # Ensure the data directory exists
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS positions (
            hash_id TEXT PRIMARY KEY,
            fen TEXT NOT NULL
        )
    ''')
    conn.commit()
    return conn

def save_position(hash_id, fen):
    """Saves a new position (Ignores if it already exists)."""
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("INSERT OR IGNORE INTO positions (hash_id, fen) VALUES (?, ?)", (hash_id, fen))
        rows = cursor.rowcount
        conn.commit()
        conn.close()
        
        if rows > 0:
            print(f"[DB] New position saved: {hash_id}")
        else:
            print(f"[DB] Position already exists: {hash_id}")
            
    except Exception as e:
        print(f"[ERROR] DB Save failed: {e}")
        sys.exit(1)

def get_position(hash_id):
    """Retrieves a FEN string by its Hash ID."""
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("SELECT fen FROM positions WHERE hash_id = ?", (hash_id,))
        row = cursor.fetchone()
        conn.close()
        
        if row:
            # Print only the FEN for PowerShell to capture
            print(row[0])
        else:
            sys.exit(1) # Exit code 1 = Not Found
            
    except Exception:
        sys.exit(1)

if __name__ == "__main__":
    # Simple CLI interface for PowerShell
    # Usage: python manage_db.py [save|get] [hash] [fen?]
    
    if len(sys.argv) < 3:
        sys.exit(1)
    
    command = sys.argv[1]
    hash_id = sys.argv[2]

    if command == "save" and len(sys.argv) >= 4:
        # Reconstruct FEN in case it was split by argument spaces
        fen_input = " ".join(sys.argv[3:])
        save_position(hash_id, fen_input)
        
    elif command == "get":
        get_position(hash_id)