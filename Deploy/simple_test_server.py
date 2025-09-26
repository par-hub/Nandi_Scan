import http.server
import socketserver
import json
from urllib.parse import urlparse, parse_qs
import threading
import time

class TestHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urlparse(self.path)
        
        # Add CORS headers
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()
        
        if parsed_path.path == '/health':
            response = {
                "status": "healthy",
                "model_loaded": True,
                "message": "Simple test server is running",
                "timestamp": time.time()
            }
            self.wfile.write(json.dumps(response).encode())
        else:
            response = {"error": "Not found"}
            self.wfile.write(json.dumps(response).encode())
    
    def do_POST(self):
        # Add CORS headers
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()
        
        if self.path == '/predict':
            # Mock prediction response
            response = {
                "prediction": "Holstein Friesian",
                "confidence": 0.85,
                "message": "Mock prediction from simple test server"
            }
            self.wfile.write(json.dumps(response).encode())
    
    def do_OPTIONS(self):
        # Handle preflight requests
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

if __name__ == "__main__":
    PORT = 8001
    
    # Get local IP address
    import socket
    hostname = socket.gethostname()
    local_ip = socket.gethostbyname(hostname)
    
    print(f"Starting simple test server...")
    print(f"Server will be available at:")
    print(f"  - http://localhost:{PORT}")
    print(f"  - http://127.0.0.1:{PORT}")
    print(f"  - http://{local_ip}:{PORT}")
    print(f"Health endpoint: http://{local_ip}:{PORT}/health")
    print(f"Press Ctrl+C to stop the server")
    
    with socketserver.TCPServer(("", PORT), TestHandler) as httpd:
        print(f"Server started on port {PORT}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("Server stopped")
            httpd.shutdown()