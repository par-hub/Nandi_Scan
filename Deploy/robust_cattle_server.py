#!/usr/bin/env python3
"""
Cattle Breed AI Prediction Server - Robust Version
A stable standalone server that runs continuously to provide cattle breed predictions.
"""

import os
import sys
import json
import socket
import threading
import time
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any
import base64
import io
import traceback

# HTTP Server imports
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse
from socketserver import ThreadingMixIn

# AI/ML imports
try:
    import torch
    import torch.nn as nn
    import torchvision.transforms as transforms
    from torchvision import models
    TORCH_AVAILABLE = True
    print("✅ PyTorch successfully imported")
except ImportError as e:
    print(f"⚠️ PyTorch import error: {e}")
    print("   Server will continue with mock predictions")
    TORCH_AVAILABLE = False
    # Mock classes for when torch is not available
    class MockTensor:
        pass
    
    torch = None
    nn = None
    transforms = None
    models = None
except Exception as e:
    print(f"⚠️ PyTorch loading error (DLL/dependency issue): {e}")
    print("   This might be due to missing Visual C++ Redistributable or CUDA issues")
    print("   Server will continue with mock predictions")
    TORCH_AVAILABLE = False
    # Mock classes for when torch has loading issues
    class MockTensor:
        pass
    
    torch = None
    nn = None  
    transforms = None
    models = None

# Image processing (separate from PyTorch)
try:
    from PIL import Image
    PIL_AVAILABLE = True
    print("✅ PIL successfully imported")
except ImportError as e:
    print(f"⚠️ PIL not available: {e}")
    PIL_AVAILABLE = False
    Image = None

# Configuration
SERVER_PORT = 8001
MODEL_PATH = "models/stable_cattle_model.pth"
BREEDS_FILE = "models/breeds.json"

# Global server instance
server_instance = None
model_instance = None

class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    """Handle requests in a separate thread."""
    daemon_threads = True
    allow_reuse_address = True

class CattleBreedModel:
    """Handles the cattle breed prediction model"""
    
    def __init__(self, model_path: str, breeds_file: str):
        self.model_path = model_path
        self.breeds_file = breeds_file
        self.model = None
        self.breeds = []
        self.transform = None
        self.is_loaded = False
        
        # Only initialize PyTorch components if available
        if TORCH_AVAILABLE:
            self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
            print(f"🔧 Using device: {self.device}")
        else:
            self.device = None
            print("⚠️ PyTorch not available - device set to None")
        
    def load_model(self):
        """Load the PyTorch model and breed labels"""
        try:
            if not TORCH_AVAILABLE:
                print("⚠️ PyTorch not available, using mock predictions")
                self.breeds = ["Holstein Friesian", "Jersey", "Angus", "Brahman", "Hereford", "Gyr", "Sahiwal"]
                return True
                
            print("🔄 Loading cattle breed prediction model...")
            
            # Load breed labels
            if os.path.exists(self.breeds_file):
                with open(self.breeds_file, 'r') as f:
                    data = json.load(f)
                    self.breeds = data.get('breeds', [])
                print(f"✅ Loaded {len(self.breeds)} breed labels")
            else:
                print("⚠️ Breeds file not found, using default labels")
                self.breeds = [f"Breed_{i}" for i in range(124)]
            
            # Create model architecture
            self.model = models.resnet18(weights=None)  # Updated parameter name
            num_classes = len(self.breeds)
            self.model.fc = nn.Linear(self.model.fc.in_features, num_classes)
            
            # Load trained weights
            if os.path.exists(self.model_path):
                checkpoint = torch.load(self.model_path, map_location=self.device)
                
                # Handle different checkpoint formats
                if 'model_state_dict' in checkpoint:
                    state_dict = checkpoint['model_state_dict']
                    if 'classes' in checkpoint:
                        self.breeds = checkpoint['classes']
                    print(f"✅ Loaded checkpoint from epoch {checkpoint.get('epoch', 'unknown')}")
                else:
                    state_dict = checkpoint
                
                self.model.load_state_dict(state_dict)
                print("✅ Model weights loaded successfully")
            else:
                print("⚠️ Model file not found, using untrained model")
            
            self.model.to(self.device)
            self.model.eval()
            
            # Define image preprocessing
            self.transform = transforms.Compose([
                transforms.Resize((224, 224)),
                transforms.ToTensor(),
                transforms.Normalize(mean=[0.485, 0.456, 0.406], 
                                   std=[0.229, 0.224, 0.225])
            ])
            
            self.is_loaded = True
            print("🎉 Cattle breed model loaded successfully!")
            return True
            
        except Exception as e:
            print(f"❌ Error loading model: {e}")
            print("⚠️ Continuing with mock predictions...")
            self.breeds = ["Holstein Friesian", "Jersey", "Angus", "Brahman", "Hereford", "Gyr", "Sahiwal"]
            return True  # Continue with mock predictions
    
    def predict(self, image_data: bytes) -> Dict[str, Any]:
        """Make a breed prediction from image data"""
        try:
            if not TORCH_AVAILABLE or not PIL_AVAILABLE or not self.is_loaded or not self.model:
                # Return mock prediction
                import random
                selected_breed = random.choice(self.breeds)
                confidence = round(random.uniform(0.75, 0.95), 2)
                
                mock_reason = []
                if not TORCH_AVAILABLE:
                    mock_reason.append("PyTorch not available")
                if not PIL_AVAILABLE:
                    mock_reason.append("PIL not available")
                if not self.is_loaded:
                    mock_reason.append("Model not loaded")
                
                return {
                    "prediction": selected_breed,
                    "confidence": confidence,
                    "top_predictions": [
                        {"breed": selected_breed, "confidence": confidence},
                        {"breed": random.choice(self.breeds), "confidence": round(confidence - 0.1, 2)},
                        {"breed": random.choice(self.breeds), "confidence": round(confidence - 0.2, 2)}
                    ],
                    "status": "success",
                    "note": f"Mock prediction - {', '.join(mock_reason)}"
                }
            
            # Convert bytes to PIL Image
            image = Image.open(io.BytesIO(image_data))
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            # Preprocess image
            input_tensor = self.transform(image).unsqueeze(0).to(self.device)
            
            # Make prediction
            with torch.no_grad():
                outputs = self.model(input_tensor)
                probabilities = torch.nn.functional.softmax(outputs[0], dim=0)
                confidence, predicted = torch.max(probabilities, 0)
                
                breed_name = self.breeds[predicted.item()]
                confidence_score = confidence.item()
                
                # Get top 3 predictions
                top_probs, top_indices = torch.topk(probabilities, 3)
                top_predictions = [
                    {
                        "breed": self.breeds[idx.item()],
                        "confidence": prob.item()
                    }
                    for prob, idx in zip(top_probs, top_indices)
                ]
                
                return {
                    "prediction": breed_name,
                    "confidence": confidence_score,
                    "top_predictions": top_predictions,
                    "status": "success"
                }
                
        except Exception as e:
            print(f"❌ Prediction error: {e}")
            traceback.print_exc()
            return {"error": f"Prediction failed: {str(e)}"}

class CattleAIHandler(BaseHTTPRequestHandler):
    """HTTP request handler for the cattle AI server"""
    
    def __init__(self, *args, **kwargs):
        self.timeout = 30
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        """Handle GET requests"""
        try:
            parsed_path = urlparse(self.path)
            path = parsed_path.path
            
            print(f"📨 GET {path} from {self.client_address[0]}")
            
            # CORS headers
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
            self.send_header('Connection', 'close')
            self.end_headers()
            
            response = {}
            
            if path == '/health':
                response = {
                    "status": "healthy",
                    "model_loaded": model_instance.is_loaded if model_instance else False,
                    "server": "Cattle AI Server",
                    "version": "1.0",
                    "timestamp": datetime.now().isoformat(),
                    "breeds_count": len(model_instance.breeds) if model_instance else 0,
                    "device": str(model_instance.device) if model_instance and hasattr(model_instance, 'device') else "none"
                }
            elif path == '/breeds':
                if model_instance:
                    response = {
                        "breeds": model_instance.breeds,
                        "count": len(model_instance.breeds)
                    }
                else:
                    response = {"error": "Model not available"}
            elif path == '/status':
                response = {
                    "server_running": True,
                    "model_status": "loaded" if model_instance and model_instance.is_loaded else "not_loaded",
                    "requests_served": getattr(self.server, 'request_count', 0)
                }
            else:
                response = {"error": "Endpoint not found"}
            
            response_json = json.dumps(response, indent=2)
            self.wfile.write(response_json.encode('utf-8'))
            
        except Exception as e:
            print(f"❌ GET error: {e}")
            try:
                self.send_error(500, f"Server error: {str(e)}")
            except:
                pass
    
    def do_POST(self):
        """Handle POST requests"""
        try:
            parsed_path = urlparse(self.path)
            path = parsed_path.path
            
            print(f"📤 POST {path} from {self.client_address[0]}")
            
            # CORS headers
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
            self.send_header('Connection', 'close')
            self.end_headers()
            
            response = {}
            
            if path == '/predict':
                try:
                    # Read request data
                    content_length = int(self.headers.get('Content-Length', 0))
                    content_type = self.headers.get('Content-Type', '')
                    
                    print(f"📋 Content-Type: {content_type}")
                    print(f"📋 Content-Length: {content_length}")
                    
                    if content_length > 0:
                        post_data = self.rfile.read(content_length)
                        
                        if not model_instance:
                            response = {"error": "Model not available"}
                        else:
                            # Handle multipart form data (from Flutter)
                            if content_type.startswith('multipart/form-data'):
                                try:
                                    # Use Python's built-in email parser for multipart data
                                    import email
                                    import re
                                    from email.message import EmailMessage
                                    from io import BytesIO
                                    
                                    # Find boundary from Content-Type header
                                    print(f"📋 Full Content-Type header: '{content_type}'")
                                    boundary_match = re.search(r'boundary=([^;\r\n]+)', content_type)
                                    if boundary_match:
                                        boundary_raw = boundary_match.group(1).strip()
                                        print(f"📋 Raw boundary string: '{boundary_raw}'")
                                        
                                        # Create a proper MIME message for parsing
                                        mime_header = f"Content-Type: multipart/form-data; boundary={boundary_raw}\r\n\r\n".encode()
                                        full_message = mime_header + post_data
                                        
                                        # Parse using email library
                                        msg = email.message_from_bytes(full_message)
                                        
                                        if msg.is_multipart():
                                            print(f"📋 Successfully parsed multipart message with {len(msg.get_payload())} parts")
                                            
                                            for i, part in enumerate(msg.get_payload()):
                                                print(f"📋 Processing part {i}")
                                                
                                                # Get content disposition
                                                content_disp = part.get('Content-Disposition', '')
                                                print(f"📋 Content-Disposition: {content_disp}")
                                                
                                                # Check if this is the file upload
                                                if 'form-data' in content_disp and 'name="file"' in content_disp:
                                                    print(f"📋 Found file upload part!")
                                                    
                                                    # Get the file data
                                                    file_data = part.get_payload(decode=True)
                                                    if file_data:
                                                        print(f"📋 Extracted file data: {len(file_data)} bytes")
                                                        print(f"📋 First 20 bytes: {file_data[:20]}")
                                                        
                                                        # Verify this looks like image data
                                                        if len(file_data) > 100:
                                                            # Check for common image file signatures
                                                            if (file_data.startswith(b'\xff\xd8\xff') or  # JPEG
                                                                file_data.startswith(b'\x89PNG') or      # PNG
                                                                file_data.startswith(b'GIF8') or        # GIF
                                                                file_data.startswith(b'RIFF')):         # WebP/other
                                                                
                                                                print(f"📋 Valid image signature detected")
                                                                response = model_instance.predict(file_data)
                                                                print(f"📊 Prediction result: {response}")
                                                                break
                                                            else:
                                                                print(f"❌ No valid image signature found")
                                                                print(f"❌ File starts with: {file_data[:10]}")
                                                        else:
                                                            print(f"❌ File data too small: {len(file_data)} bytes")
                                                    else:
                                                        print(f"❌ No file data in part {i}")
                                        else:
                                            print(f"❌ Message is not multipart")
                                            # Fallback to manual parsing
                                            response = {"error": "Failed to parse multipart data"}
                                    else:
                                        response = {"error": "No boundary found in multipart data"}
                                        
                                except Exception as e:
                                    print(f"❌ Multipart parsing error: {e}")
                                    response = {"error": f"Multipart parsing failed: {str(e)}"}
                                    
                            elif content_type == 'application/json':
                                # Handle base64 encoded image
                                try:
                                    data = json.loads(post_data.decode('utf-8'))
                                    if 'image' in data:
                                        # Decode base64 image
                                        image_data = base64.b64decode(data['image'])
                                        response = model_instance.predict(image_data)
                                    else:
                                        response = {"error": "No image data provided"}
                                except json.JSONDecodeError:
                                    response = {"error": "Invalid JSON"}
                            else:
                                # Assume raw image data
                                print(f"📋 Treating as raw image data: {len(post_data)} bytes")
                                response = model_instance.predict(post_data)
                    else:
                        response = {"error": "No data provided"}
                
                except Exception as e:
                    print(f"❌ POST predict error: {e}")
                    traceback.print_exc()
                    response = {"error": f"Request processing failed: {str(e)}"}
            else:
                response = {"error": "Endpoint not found"}
            
            response_json = json.dumps(response, indent=2)
            self.wfile.write(response_json.encode('utf-8'))
            
        except Exception as e:
            print(f"❌ POST error: {e}")
            try:
                self.send_error(500, f"Server error: {str(e)}")
            except:
                pass
    
    def do_OPTIONS(self):
        """Handle preflight OPTIONS requests"""
        try:
            self.send_response(200)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
            self.send_header('Connection', 'close')
            self.end_headers()
        except Exception as e:
            print(f"❌ OPTIONS error: {e}")
    
    def log_message(self, format, *args):
        """Override to customize logging"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] {format % args}")

def get_local_ip():
    """Get the local IP address of this machine"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

def main():
    """Main server function"""
    global server_instance, model_instance
    
    print("🐄 Cattle Breed AI Prediction Server - Robust Edition")
    print("=" * 60)
    
    # Initialize model
    model_instance = CattleBreedModel(MODEL_PATH, BREEDS_FILE)
    success = model_instance.load_model()
    
    # Get network information
    local_ip = get_local_ip()
    
    print(f"\n🌐 Server Configuration:")
    print(f"   Port: {SERVER_PORT}")
    print(f"   Local IP: {local_ip}")
    print(f"   Model Status: {'Loaded' if success else 'Mock Mode'}")
    
    print(f"\n📱 Mobile Access URLs:")
    print(f"   Health Check: http://{local_ip}:{SERVER_PORT}/health")
    print(f"   Breed List: http://{local_ip}:{SERVER_PORT}/breeds")
    print(f"   Prediction: http://{local_ip}:{SERVER_PORT}/predict")
    
    print(f"\n💻 Local Access URLs:")
    print(f"   http://localhost:{SERVER_PORT}/health")
    print(f"   http://127.0.0.1:{SERVER_PORT}/health")
    
    # Start server
    try:
        server_instance = ThreadedHTTPServer(('', SERVER_PORT), CattleAIHandler)
        server_instance.timeout = 1.0
        
        print(f"\n🚀 Server starting on port {SERVER_PORT}...")
        print("   This server will run continuously.")
        print("   Press Ctrl+C to stop the server\n")
        
        # Keep server running
        server_instance.serve_forever()
        
    except KeyboardInterrupt:
        print("\n🛑 Server stopping...")
        if server_instance:
            server_instance.shutdown()
            server_instance.server_close()
        print("✅ Server stopped successfully")
    except Exception as e:
        print(f"❌ Server error: {e}")
        traceback.print_exc()
    finally:
        if server_instance:
            server_instance.server_close()

if __name__ == "__main__":
    main()