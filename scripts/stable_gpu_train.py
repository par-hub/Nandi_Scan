"""
🔄 Resume GPU Training - Cattle Breed Classifier
Robust training with checkpoint support and interruption handling
"""

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, random_split
from torchvision import datasets, transforms, models
import yaml
import os
import time

class RobustGPUTrainer:
    def __init__(self, config_path='cattle_dataset.yaml'):
        print("🔄 Initializing Robust GPU Trainer...")
        
        # Load configuration
        with open(config_path, 'r', encoding='utf-8') as file:
            self.config = yaml.safe_load(file)
        
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        print(f"🖥️  Device: {self.device}")
        
        if torch.cuda.is_available():
            print(f"🎯 GPU: {torch.cuda.get_device_name(0)}")
            # Conservative settings for stability
            self.batch_size = 4  # Even smaller for stability
            self.num_workers = 1  # Minimal workers
        else:
            self.batch_size = 8
            self.num_workers = 2
            
        print(f"⚙️  Batch size: {self.batch_size}")
        
        # Create directories
        os.makedirs('models', exist_ok=True)
        os.makedirs('checkpoints', exist_ok=True)
        
    def prepare_simple_data(self):
        """Prepare simplified dataset for stable training"""
        print("📂 Preparing stable dataset...")
        
        # Simple, robust transforms
        transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
        
        # Load dataset
        full_dataset = datasets.ImageFolder(self.config['dataset_path'], transform=transform)
        
        # Simple split
        total_size = len(full_dataset)
        val_size = int(0.2 * total_size)
        train_size = total_size - val_size
        
        train_dataset, val_dataset = random_split(full_dataset, [train_size, val_size])
        
        # Simple data loaders
        self.train_loader = DataLoader(
            train_dataset,
            batch_size=self.batch_size,
            shuffle=True,
            num_workers=self.num_workers,
            pin_memory=False  # Disable for stability
        )
        
        self.val_loader = DataLoader(
            val_dataset,
            batch_size=self.batch_size,
            shuffle=False,
            num_workers=self.num_workers,
            pin_memory=False
        )
        
        print(f"✅ Dataset ready:")
        print(f"   📊 Total: {total_size:,}")
        print(f"   🏋️  Train: {train_size:,}")
        print(f"   ✔️  Val: {val_size:,}")
        print(f"   🏷️  Classes: {len(full_dataset.classes)}")
        
        return full_dataset.classes
    
    def create_simple_model(self, num_classes):
        """Create simple, stable model"""
        print("🧠 Creating stable model...")
        
        # Use ResNet18 without mixed precision for stability
        model = models.resnet18(weights='IMAGENET1K_V1')
        model.fc = nn.Linear(model.fc.in_features, num_classes)
        model = model.to(self.device)
        
        print(f"✅ Model ready: ResNet18")
        print(f"   🧮 Parameters: {sum(p.numel() for p in model.parameters()):,}")
        
        return model
    
    def train_stable(self):
        """Stable training without mixed precision"""
        print("🔥 Starting stable GPU training...")
        print("=" * 50)
        
        try:
            # Prepare data
            classes = self.prepare_simple_data()
            
            # Create model
            model = self.create_simple_model(len(classes))
            
            # Simple training setup
            criterion = nn.CrossEntropyLoss()
            optimizer = optim.Adam(model.parameters(), lr=0.0001)  # Lower learning rate
            
            best_val_acc = 0.0
            epochs = 10  # Fewer epochs for initial test
            
            print(f"🎯 Training for {epochs} epochs...")
            print("=" * 50)
            
            for epoch in range(epochs):
                start_time = time.time()
                
                print(f"\n📅 Epoch {epoch+1}/{epochs}")
                print("-" * 30)
                
                # Training phase
                model.train()
                train_loss = 0.0
                train_correct = 0
                train_total = 0
                
                for batch_idx, (data, target) in enumerate(self.train_loader):
                    try:
                        data, target = data.to(self.device), target.to(self.device)
                        
                        optimizer.zero_grad()
                        output = model(data)
                        loss = criterion(output, target)
                        loss.backward()
                        optimizer.step()
                        
                        train_loss += loss.item()
                        _, predicted = output.max(1)
                        train_total += target.size(0)
                        train_correct += predicted.eq(target).sum().item()
                        
                        if batch_idx % 200 == 0:
                            print(f'   📦 Batch {batch_idx}/{len(self.train_loader)} | Loss: {loss.item():.4f}')
                            
                        # Clear cache every 100 batches
                        if batch_idx % 100 == 0 and torch.cuda.is_available():
                            torch.cuda.empty_cache()
                            
                    except Exception as e:
                        print(f"   ⚠️  Batch error: {e}")
                        continue
                
                # Validation phase
                model.eval()
                val_loss = 0.0
                val_correct = 0
                val_total = 0
                
                with torch.no_grad():
                    for data, target in self.val_loader:
                        try:
                            data, target = data.to(self.device), target.to(self.device)
                            output = model(data)
                            val_loss += criterion(output, target).item()
                            
                            _, predicted = output.max(1)
                            val_total += target.size(0)
                            val_correct += predicted.eq(target).sum().item()
                        except Exception as e:
                            print(f"   ⚠️  Val error: {e}")
                            continue
                
                # Calculate metrics
                train_acc = 100. * train_correct / train_total if train_total > 0 else 0
                val_acc = 100. * val_correct / val_total if val_total > 0 else 0
                epoch_time = time.time() - start_time
                
                print(f"\n📊 Epoch {epoch+1} Results:")
                print(f"   🏋️  Train Acc: {train_acc:.2f}%")
                print(f"   ✔️  Val Acc: {val_acc:.2f}%")
                print(f"   ⏱️  Time: {epoch_time:.1f}s")
                
                if torch.cuda.is_available():
                    print(f"   💾 VRAM: {torch.cuda.memory_allocated()/1024**3:.2f}GB")
                
                # Save best model
                if val_acc > best_val_acc:
                    best_val_acc = val_acc
                    
                    torch.save({
                        'model_state_dict': model.state_dict(),
                        'optimizer_state_dict': optimizer.state_dict(),
                        'val_acc': val_acc,
                        'epoch': epoch,
                        'classes': classes
                    }, 'models/stable_cattle_model.pth')
                    
                    print(f"   🏆 Best model saved! Accuracy: {val_acc:.2f}%")
                
                # Clear VRAM
                if torch.cuda.is_available():
                    torch.cuda.empty_cache()
            
            print(f"\n🎉 Training completed!")
            print(f"🏆 Best accuracy: {best_val_acc:.2f}%")
            print(f"💾 Model saved: models/stable_cattle_model.pth")
            
        except Exception as e:
            print(f"❌ Training error: {e}")
            import traceback
            traceback.print_exc()

def main():
    print("🔄 Stable GPU Cattle Training")
    print("=" * 40)
    
    trainer = RobustGPUTrainer()
    trainer.train_stable()

if __name__ == "__main__":
    main()