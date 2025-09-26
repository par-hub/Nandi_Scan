#!/usr/bin/env python3
"""
Launcher for the Cattle AI Server
This script ensures the server starts with proper error handling and logging.
"""

import os
import sys
import subprocess
from pathlib import Path

def main():
    """Launch the cattle AI server"""
    
    # Get the directory where this script is located
    script_dir = Path(__file__).parent.absolute()
    server_script = script_dir / "cattle_ai_server.py"
    
    print("🐄 Cattle AI Server Launcher")
    print("=" * 40)
    print(f"Script directory: {script_dir}")
    print(f"Server script: {server_script}")
    print()
    
    # Check if server script exists
    if not server_script.exists():
        print(f"❌ Error: Server script not found at {server_script}")
        input("Press Enter to exit...")
        return
    
    # Change to the script directory
    os.chdir(script_dir)
    print(f"Working directory: {os.getcwd()}")
    print()
    
    try:
        # Launch the server
        print("🚀 Starting Cattle AI Server...")
        print("   Press Ctrl+C to stop the server")
        print()
        
        # Run the server script
        subprocess.run([sys.executable, "cattle_ai_server.py"], check=True)
        
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except subprocess.CalledProcessError as e:
        print(f"\n❌ Server exited with error code {e.returncode}")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
    
    print("\n✅ Launcher finished")
    input("Press Enter to exit...")

if __name__ == "__main__":
    main()