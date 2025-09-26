#!/usr/bin/env python3
"""
Test image prediction with cow1.png
"""

import requests
from pathlib import Path

def test_prediction():
    url = "http://127.0.0.1:8001/predict"
    image_path = Path("../assets/cow1.png")
    
    if not image_path.exists():
        print(f"❌ Image not found: {image_path}")
        return
    
    print(f"📷 Testing prediction with image: {image_path}")
    
    try:
        with open(image_path, 'rb') as img_file:
            files = {'file': ('cow1.png', img_file, 'image/png')}
            response = requests.post(url, files=files, timeout=30)
        
        print(f"📊 Response Status: {response.status_code}")
        print(f"📊 Response Content: {response.text}")
        
        if response.status_code == 200:
            prediction = response.json()
            print(f"✅ Prediction successful!")
            for key, value in prediction.items():
                print(f"   {key}: {value}")
        else:
            print(f"❌ Prediction failed")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_prediction()