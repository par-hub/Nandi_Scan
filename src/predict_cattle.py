"""
🐄 Cattle Breed Predictor
Simple script to predict top 3 cattle breeds from an input image
"""

import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import os
import sys

class CattlePredictor:
    def __init__(self, model_path='../models/stable_cattle_model.pth'):
        """Initialize the cattle breed predictor"""
        print("🐄 Loading Cattle Breed Predictor...")
        
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        print(f"🖥️ Using device: {self.device}")
        
        # Load model checkpoint
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"❌ Model not found at {model_path}")
            
        checkpoint = torch.load(model_path, map_location=self.device, weights_only=False)
        self.classes = checkpoint['classes']
        
        print(f"✅ Model loaded successfully!")
        print(f"🧠 Trained to recognize {len(self.classes)} cattle breeds")
        print(f"🏆 Best validation accuracy: {checkpoint.get('val_acc', 'Unknown'):.2f}%")
        
        # Setup model
        self.model = models.resnet18(weights=None)
        self.model.fc = nn.Linear(self.model.fc.in_features, len(self.classes))
        self.model.load_state_dict(checkpoint['model_state_dict'])
        self.model = self.model.to(self.device)
        self.model.eval()
        
        # Image preprocessing
        self.transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
        
        print("🎯 Predictor ready!")
        
    def predict_top3(self, image_path):
        """
        Predict top 3 cattle breeds from an image
        
        Args:
            image_path (str): Path to the image file
            
        Returns:
            list: Top 3 predictions with breed names and confidence scores
        """
        try:
            # Check if image exists
            if not os.path.exists(image_path):
                raise FileNotFoundError(f"❌ Image not found: {image_path}")
            
            # Load and preprocess image
            image = Image.open(image_path).convert('RGB')
            input_tensor = self.transform(image).unsqueeze(0).to(self.device)
            
            # Predict
            with torch.no_grad():
                outputs = self.model(input_tensor)
                probabilities = torch.softmax(outputs, 1)
                
                # Get top 3 predictions
                top_probs, top_indices = torch.topk(probabilities, k=3)
                
                # Format results
                predictions = []
                for i in range(3):
                    breed = self.classes[top_indices[0][i].item()]
                    confidence = top_probs[0][i].item()
                    predictions.append({
                        'breed': breed,
                        'confidence': confidence,
                        'percentage': f"{confidence * 100:.1f}%"
                    })
                
                return predictions
                
        except Exception as e:
            print(f"❌ Error processing {image_path}: {e}")
            return None
    
    def predict_and_display(self, image_path):
        """Predict and display results in a nice format"""
        print(f"\n🖼️ Analyzing image: {image_path}")
        print("=" * 50)
        
        predictions = self.predict_top3(image_path)
        
        if predictions:
            print("🏆 Top 3 Cattle Breed Predictions:")
            print("-" * 30)
            for i, pred in enumerate(predictions, 1):
                medal = "🥇" if i == 1 else "🥈" if i == 2 else "🥉"
                print(f"{medal} {i}. {pred['breed']}")
                print(f"   Confidence: {pred['percentage']}")
                if i < 3:
                    print()
            
            return predictions
        else:
            print("❌ Failed to analyze image")
            return None

def main():
    """Main function for command line usage"""
    if len(sys.argv) != 2:
        print("Usage: python predict_cattle.py <image_path>")
        print("Example: python predict_cattle.py your_cattle_image.jpg")
        print("Note: Provide path to any cattle image for breed prediction")
        return
    
    image_path = sys.argv[1]
    
    try:
        predictor = CattlePredictor()
        result = predictor.predict_and_display(image_path)
        
        if result:
            print(f"\n✅ Analysis complete!")
        else:
            print(f"\n❌ Analysis failed!")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()