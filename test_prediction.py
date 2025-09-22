import requests
import os

def test_prediction():
    url = "http://127.0.0.1:8001/predict"
    image_path = r"E:\NandiScan\Nandi_Scan\assets\cow1.png"
    
    if not os.path.exists(image_path):
        print(f"Image not found at {image_path}")
        return
    
    try:
        with open(image_path, 'rb') as f:
            files = {'file': ('cow1.png', f, 'image/png')}
            response = requests.post(url, files=files)
            
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            result = response.json()
            prediction = result.get('prediction', {})
            print(f"Predicted breed: {prediction.get('breed', 'Unknown')}")
            print(f"Confidence: {prediction.get('confidence', 'Unknown')}%")
        else:
            print("Prediction failed!")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_prediction()