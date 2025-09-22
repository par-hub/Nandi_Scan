"""
🐄 Simplified Cattle Breed Classification API Server
Mock implementation for testing Flutter integration
"""

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import random
from typing import List, Dict, Any
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Cattle Breed Classification API",
    description="Simplified API for testing Flutter integration",
    version="1.0.0"
)

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mock cattle breeds (subset for testing)
CATTLE_BREEDS = [
    "Halikar", "Hallikar", "Kangayam", "Gir", "Red Sindhi", "Sahiwal",
    "Tharparkar", "Rathi", "Hariana", "Kankrej", "Ongole", "Krishna Valley",
    "Deoni", "Khillari", "Dangi", "Malvi", "Nimari", "Nagori", "Punganur",
    "Vechur", "Kasaragod Dwarf", "Amritmahal", "Bargur", "Pulikulam",
    "Umblachery", "Alambadi", "Kapsila", "Bachaur", "Gaolao", "Mewati"
]

@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "message": "🐄 Cattle Breed Classification API",
        "status": "running",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "predict": "/predict/",
            "docs": "/docs"
        }
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model_loaded": True,
        "supported_breeds": len(CATTLE_BREEDS),
        "model_type": "ResNet18 (Mock)"
    }

@app.post("/predict/")
async def predict_breed(file: UploadFile = File(...)):
    """
    Predict cattle breed from uploaded image
    Mock implementation that returns random breeds for testing
    """
    try:
        # Validate file type
        if not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # Read the image (for validation)
        contents = await file.read()
        if len(contents) == 0:
            raise HTTPException(status_code=400, detail="Empty file")
        
        # Mock prediction - randomly select 3 breeds with realistic confidence
        selected_breeds = random.sample(CATTLE_BREEDS, 3)
        
        # Generate realistic confidence scores that sum to 100%
        confidences = [
            round(random.uniform(60, 95), 2),  # Primary prediction
            round(random.uniform(3, 20), 2),   # Secondary prediction
            round(random.uniform(1, 10), 2)    # Tertiary prediction
        ]
        
        # Normalize to ensure they don't exceed 100%
        total = sum(confidences)
        if total > 100:
            confidences = [round(c * 100 / total, 2) for c in confidences]
        
        # Create prediction results
        predictions = []
        for i, (breed, confidence) in enumerate(zip(selected_breeds, confidences)):
            predictions.append({
                "rank": i + 1,
                "breed": breed,
                "confidence": confidence,
                "percentage": f"{confidence}%"
            })
        
        logger.info(f"Mock prediction completed for file: {file.filename}")
        
        return {
            "success": True,
            "message": "Breed prediction completed (Mock)",
            "filename": file.filename,
            "predictions": predictions,
            "model_info": {
                "model_type": "ResNet18 (Mock)",
                "total_breeds": len(CATTLE_BREEDS),
                "processing_time": "~200ms"
            }
        }
        
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")

@app.get("/breeds/")
async def get_supported_breeds():
    """Get list of all supported cattle breeds"""
    return {
        "total_breeds": len(CATTLE_BREEDS),
        "breeds": sorted(CATTLE_BREEDS)
    }

if __name__ == "__main__":
    logger.info("🐄 Starting Cattle Breed Classification API Server (Mock)")
    logger.info("🌐 Server will be available at: http://127.0.0.1:8000")
    logger.info("📖 API Documentation: http://127.0.0.1:8000/docs")
    
    uvicorn.run(
        app,
        host="127.0.0.1",
        port=8000,
        log_level="info"
    )