"""
🐄 Cattle Breed Classification FastAPI Server
Enhanced for Flutter Integration
"""

import os
import torch
import torchvision.transforms as transforms
import torchvision.models as models
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from PIL import Image
import io
import logging
import uvicorn
from typing import List, Dict, Any
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Cattle Breed Classification API",
    description="API for classifying cattle breeds using a ResNet18 model - Flutter Ready",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Enhanced CORS configuration for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's domain
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# Cattle breed classes (124 breeds)
BREED_CLASSES = [
    'Abondance', 'Afrikaner', 'Alambadi', 'Albera', 'AmericanMilkingDevon',
    'Amritmahal', 'Angus', 'AnkoleWatusi', 'Aquitaine', 'Argentine',
    'Armorican', 'Arouquesa', 'Asturian', 'AustralianBraford', 'Ayrshire',
    'Banni', 'Bargur', 'Barzona', 'Bazadaise', 'Belgian',
    'Belmont', 'Bhadawari', 'BlackHereford', 'BlondeAquitaine', 'Boran',
    'Braford', 'Brahman', 'Brangus', 'Braunvieh', 'Brava',
    'Brown_Swiss', 'Burlina', 'Busa', 'Cachena', 'Camargue',
    'CanadianSpeckle', 'Canadienne', 'Canchim', 'Caracu', 'Casta',
    'Charolais', 'Chianina', 'Corriente', 'Corsican', 'Criollo',
    'Dangi', 'DanishRed', 'Deoni', 'Devon', 'Dexter',
    'Dhannir', 'Droughtmaster', 'DutchBelted', 'EnglishLonghorn', 'Evolene',
    'Fjall', 'Fleckvlehl', 'FloridaCracker', 'Galloway', 'Gangatiri',
    'Gaolao', 'Gascon', 'Gelbvieh', 'GermanAngus', 'Gir',
    'Glan', 'Gloucester', 'Guernsey', 'HackCattle', 'Halikar',
    'Hallikar', 'Hariana', 'Haryana', 'Hereford', 'Highland',
    'Hinterwald', 'HolandoArgentio', 'Holstein_Friesian', 'HungarianGrey', 'Icelandic',
    'Jaffrabadi', 'Jutland', 'Kangayam', 'Kankrej', 'Kasargod',
    'Kenkatha', 'Kerry', 'Kherigarh', 'Khillari', 'KrishnaValley',
    'Krishna_Valley', 'Kuri', 'LatvianBrowni', 'Lohani', 'Lowline',
    'Luing', 'Malnad_gidda', 'Malvi', 'Maronesa', 'Mehsana',
    'Mewati', 'MilkingShorthorn', 'Mirandesa', 'Montbéliarde', 'Murboden',
    'Murrah', 'Nagori', 'Nagpuri', 'Nili_Ravi', 'Nimari',
    'Ongole', 'Pulikulam', 'Rathi', 'Red_Dane', 'Red_Sindhi',
    'Sahiwal', 'Surti', 'Tharparkar', 'Toda', 'Umblachery',
    'Vechur', 'brownSwiss', 'herens', 'jersey'
]

# Global model variable
model = None

def get_transforms():
    """Get image preprocessing transforms"""
    return transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])

def load_model():
    """Load the cattle breed classification model"""
    global model
    try:
        # Use the correct model path
        model_path = r"E:\NandiScan\Deploy\models\stable_cattle_model.pth"
        
        logger.info(f"Loading model from {model_path}")
        
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file not found at {model_path}")
        
        # Load the model - ResNet18 architecture
        model = models.resnet18(weights=None)
        num_classes = len(BREED_CLASSES)
        model.fc = torch.nn.Linear(model.fc.in_features, num_classes)
        
        # Load the state dict
        checkpoint = torch.load(model_path, map_location=torch.device('cpu'))
        
        # Handle different checkpoint formats
        if 'model_state_dict' in checkpoint:
            model.load_state_dict(checkpoint['model_state_dict'])
        else:
            model.load_state_dict(checkpoint)
            
        model.eval()
        logger.info("Model loaded successfully")
        return True
    except Exception as e:
        logger.error(f"Failed to load model: {str(e)}")
        model = None
        return False

# Load model on startup
@app.on_event("startup")
async def startup_event():
    """Initialize model on startup"""
    logger.info("🚀 Starting Cattle Breed Classification API...")
    success = load_model()
    if success:
        logger.info("✅ Model loaded successfully on startup")
    else:
        logger.error("❌ Failed to load model on startup")

# API Endpoints

@app.get("/")
async def read_root():
    """Root endpoint - API status"""
    return {
        "message": "🐄 Cattle Breed Classification API", 
        "status": "active",
        "version": "2.0.0",
        "flutter_ready": True,
        "supported_breeds": len(BREED_CLASSES)
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    if model is None:
        return JSONResponse(
            status_code=503,
            content={
                "status": "error", 
                "message": "Model not loaded properly",
                "model_loaded": False
            }
        )
    return {
        "status": "healthy", 
        "model_loaded": True,
        "supported_breeds": len(BREED_CLASSES),
        "model_type": "ResNet18"
    }

@app.get("/breeds")
async def get_supported_breeds():
    """Get list of all supported cattle breeds"""
    return {
        "status": "success",
        "total_breeds": len(BREED_CLASSES),
        "breeds": sorted(BREED_CLASSES)
    }

@app.post("/predict")
async def predict_breed(file: UploadFile = File(...)):
    """
    Predict cattle breed from uploaded image
    Optimized for Flutter integration
    """
    if model is None:
        raise HTTPException(
            status_code=503, 
            detail="Model not loaded properly. Please check server logs."
        )
    
    # Validate file type - check both content type and file extension
    valid_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.gif', '.webp']
    valid_content_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/bmp', 'image/gif', 'image/webp']
    
    # Check file extension
    filename_lower = file.filename.lower() if file.filename else ""
    has_valid_extension = any(filename_lower.endswith(ext) for ext in valid_extensions)
    
    # Check content type (if available)
    has_valid_content_type = (
        file.content_type and 
        (file.content_type.startswith("image/") or file.content_type in valid_content_types)
    )
    
    # Accept if either extension or content type is valid
    if not (has_valid_extension or has_valid_content_type):
        logger.warning(f"Invalid file type. Filename: {file.filename}, Content-Type: {file.content_type}")
        return JSONResponse(
            status_code=400,
            content={
                "status": "error", 
                "message": "Invalid file type. Please upload an image file.",
                "accepted_types": ["image/jpeg", "image/jpg", "image/png", "image/bmp"],
                "received_filename": file.filename,
                "received_content_type": file.content_type
            }
        )
    
    try:
        # Read and process image
        image_bytes = await file.read()
        image = Image.open(io.BytesIO(image_bytes))
        
        # Convert to RGB if needed
        if image.mode != "RGB":
            image = image.convert("RGB")
        
        # Get image dimensions for Flutter
        original_width, original_height = image.size
        
        # Preprocess image
        transform = get_transforms()
        image_tensor = transform(image).unsqueeze(0)  # Add batch dimension
        
        # Make prediction
        with torch.no_grad():
            outputs = model(image_tensor)
            probabilities = torch.nn.functional.softmax(outputs[0], dim=0)
            predicted_idx = torch.argmax(probabilities).item()
            
            # Debug logging
            logger.info(f"Model outputs shape: {outputs.shape}")
            logger.info(f"Predicted index: {predicted_idx}")
            logger.info(f"Max probability: {probabilities[predicted_idx].item()}")
            logger.info(f"Total classes in model: {len(probabilities)}")
            logger.info(f"Total classes in BREED_CLASSES: {len(BREED_CLASSES)}")
            
            # Get top 5 predictions for better Flutter UX
            top_probs, top_indices = torch.topk(probabilities, min(5, len(BREED_CLASSES)))
            
            # Debug top predictions
            logger.info(f"Top 3 predictions: {[(BREED_CLASSES[idx], prob.item()) for idx, prob in zip(top_indices[:3], top_probs[:3])]}")
            
            # Format results for Flutter
            top_predictions = []
            for prob, idx in zip(top_probs.tolist(), top_indices.tolist()):
                confidence_percentage = round(float(prob) * 100, 2)
                if idx < len(BREED_CLASSES):  # Safety check
                    breed_name = BREED_CLASSES[idx]
                else:
                    breed_name = f"Unknown_Class_{idx}"
                    logger.warning(f"Index {idx} out of bounds for BREED_CLASSES")
                
                top_predictions.append({
                    "breed": breed_name,
                    "confidence": confidence_percentage,
                    "confidence_decimal": round(float(prob), 4)
                })
            
            # Main prediction
            main_confidence = round(float(probabilities[predicted_idx].item()) * 100, 2)
            
            return {
                "status": "success",
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "image_info": {
                    "filename": file.filename,
                    "size_bytes": len(image_bytes),
                    "dimensions": {
                        "width": original_width,
                        "height": original_height
                    },
                    "format": image.format or "Unknown"
                },
                "prediction": {
                    "breed": BREED_CLASSES[predicted_idx],
                    "confidence": main_confidence,
                    "confidence_decimal": round(float(probabilities[predicted_idx].item()), 4)
                },
                "top_predictions": top_predictions,
                "model_info": {
                    "architecture": "ResNet18",
                    "total_breeds": len(BREED_CLASSES)
                }
            }
    
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        return JSONResponse(
            status_code=500,
            content={
                "status": "error", 
                "message": f"Prediction failed: {str(e)}",
                "error_type": type(e).__name__
            }
        )

@app.post("/predict/batch")
async def predict_batch(files: List[UploadFile] = File(...)):
    """
    Batch prediction for multiple images
    Useful for Flutter gallery uploads
    """
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded properly")
    
    if len(files) > 10:  # Limit batch size
        return JSONResponse(
            status_code=400,
            content={
                "status": "error",
                "message": "Maximum 10 images allowed per batch"
            }
        )
    
    results = []
    
    for i, file in enumerate(files):
        try:
            # Validate file type
            if not file.content_type or not file.content_type.startswith("image/"):
                results.append({
                    "index": i,
                    "filename": file.filename,
                    "status": "error",
                    "message": "Invalid file type"
                })
                continue
            
            # Process image (similar to single prediction)
            image_bytes = await file.read()
            image = Image.open(io.BytesIO(image_bytes))
            
            if image.mode != "RGB":
                image = image.convert("RGB")
            
            transform = get_transforms()
            image_tensor = transform(image).unsqueeze(0)
            
            with torch.no_grad():
                outputs = model(image_tensor)
                probabilities = torch.nn.functional.softmax(outputs[0], dim=0)
                predicted_idx = torch.argmax(probabilities).item()
                confidence = round(float(probabilities[predicted_idx].item()) * 100, 2)
                
                results.append({
                    "index": i,
                    "filename": file.filename,
                    "status": "success",
                    "prediction": {
                        "breed": BREED_CLASSES[predicted_idx],
                        "confidence": confidence
                    }
                })
        
        except Exception as e:
            results.append({
                "index": i,
                "filename": file.filename,
                "status": "error",
                "message": str(e)
            })
    
    return {
        "status": "success",
        "batch_size": len(files),
        "results": results
    }

@app.get("/model/info")
async def get_model_info():
    """Get detailed model information"""
    return {
        "status": "success",
        "model": {
            "architecture": "ResNet18",
            "total_classes": len(BREED_CLASSES),
            "accuracy": "93.24%",
            "input_size": "224x224",
            "color_channels": "RGB",
            "framework": "PyTorch"
        },
        "api": {
            "version": "2.0.0",
            "flutter_optimized": True,
            "cors_enabled": True
        },
        "breeds": {
            "total": len(BREED_CLASSES),
            "sample": BREED_CLASSES[:10]  # First 10 breeds as sample
        }
    }

if __name__ == "__main__":
    print("🚀 Starting Cattle Breed Classification API Server...")
    print("📱 Flutter Integration Ready!")
    print("🌐 API Documentation: http://127.0.0.1:8001/docs")
    
    uvicorn.run(
        app, 
        host="127.0.0.1",  # Allow external connections for Flutter
        port=8001, 
        log_level="info"
    )
