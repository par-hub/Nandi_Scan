# Nandi Scan — Cattle Breed Prediction Prototype

Nandi Scan is a cattle-breed identification prototype combining a PyTorch image-classification script with Flutter/API integration resources and database setup materials.

## What's included
- `src/predict_cattle.py`: loads a ResNet-18 classifier checkpoint and returns the top three predicted cattle breeds with confidence scores.
- `config/cattle_dataset.yaml`: dataset configuration.
- `docs/`: guides for starting the application and connecting Flutter with the API.
- Root SQL files and database troubleshooting notes for the application's database setup.
- Prediction and API integration test scripts.

## Cattle predictor

The predictor expects a trained checkpoint containing the class list and model state dictionary. The default path in the script is `../models/stable_cattle_model.pth`; the checkpoint is not currently present in the repository root listing, so provide the model file according to your project's data/model distribution policy.

From the `src` directory, run:

~~~bash
python predict_cattle.py path/to/cattle-image.jpg
~~~

The script prints the top three breed predictions and confidence percentages. It uses CUDA when available and otherwise falls back to CPU.

## Setup and API integration

Start with the documentation in this order:
1. [How to start the project](docs/HOW_TO_START.md)
2. [FastAPI and Flutter guide](docs/README_FASTAPI_FLUTTER.md)
3. [Flutter integration guide](docs/FLUTTER_INTEGRATION_GUIDE.md)

Python environment and API requirements are described in those guides and the repository scripts. Review the database setup docs before applying SQL; back up any existing project data first.

## Tech
Python · PyTorch · Torchvision · Pillow · Flutter/Dart · FastAPI integration

## Important
Predictions are model outputs, not veterinary advice. Check the model checkpoint, dataset labels, and validation metrics before relying on results.
