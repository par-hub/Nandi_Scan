import os
import random
import numpy as np
from PIL import Image, ImageEnhance, ImageFilter, ImageOps
import json
from datetime import datetime
import glob

class CattleBreedAugmentor:
    def __init__(self, base_path="datasets/CattleBreed"):
        self.base_path = base_path
        self.breeds = []
        self.progress = {}
        self.total_generated = 0
        
        # Initialize progress tracking
        self.progress_file = "augmentation_progress.json"
        self.load_progress()
        
        print("🐄 CATTLE BREED SYNTHETIC IMAGE GENERATOR 🐄")
        print("=" * 60)
        
    def load_progress(self):
        """Load existing progress if any"""
        if os.path.exists(self.progress_file):
            with open(self.progress_file, 'r') as f:
                self.progress = json.load(f)
        else:
            self.progress = {
                "start_time": datetime.now().isoformat(),
                "breeds_completed": [],
                "current_breed": None,
                "total_generated": 0,
                "breeds_status": {}
            }
    
    def save_progress(self):
        """Save current progress"""
        self.progress["last_update"] = datetime.now().isoformat()
        self.progress["total_generated"] = self.total_generated
        with open(self.progress_file, 'w') as f:
            json.dump(self.progress, f, indent=2)
    
    def scan_breeds(self):
        """Scan all breed folders and count existing images"""
        print("📂 Scanning breed folders...")
        
        for breed_folder in os.listdir(self.base_path):
            breed_path = os.path.join(self.base_path, breed_folder)
            
            if os.path.isdir(breed_path):
                # Count existing images
                image_files = glob.glob(os.path.join(breed_path, "*.jpg")) + \
                             glob.glob(os.path.join(breed_path, "*.jpeg")) + \
                             glob.glob(os.path.join(breed_path, "*.png"))
                
                if image_files:
                    self.breeds.append({
                        'name': breed_folder,
                        'path': breed_path,
                        'existing_images': len(image_files),
                        'source_files': image_files
                    })
                    
                    print(f"  ✅ {breed_folder}: {len(image_files)} existing images")
        
        print(f"\n📊 Found {len(self.breeds)} breed folders with images")
        return len(self.breeds)
    
    def apply_augmentation(self, image, augmentation_type):
        """Apply specific augmentation to image"""
        
        if augmentation_type == "rotate":
            angle = random.randint(-30, 30)
            return image.rotate(angle, expand=True, fillcolor=(255, 255, 255))
        
        elif augmentation_type == "flip_horizontal":
            return ImageOps.mirror(image)
        
        elif augmentation_type == "brightness":
            enhancer = ImageEnhance.Brightness(image)
            factor = random.uniform(0.7, 1.3)
            return enhancer.enhance(factor)
        
        elif augmentation_type == "contrast":
            enhancer = ImageEnhance.Contrast(image)
            factor = random.uniform(0.8, 1.2)
            return enhancer.enhance(factor)
        
        elif augmentation_type == "saturation":
            enhancer = ImageEnhance.Color(image)
            factor = random.uniform(0.8, 1.2)
            return enhancer.enhance(factor)
        
        elif augmentation_type == "blur":
            return image.filter(ImageFilter.GaussianBlur(radius=random.uniform(0.5, 1.5)))
        
        elif augmentation_type == "sharpen":
            return image.filter(ImageFilter.SHARPEN)
        
        elif augmentation_type == "crop_resize":
            width, height = image.size
            crop_factor = random.uniform(0.8, 0.95)
            new_width = int(width * crop_factor)
            new_height = int(height * crop_factor)
            
            left = random.randint(0, width - new_width)
            top = random.randint(0, height - new_height)
            
            cropped = image.crop((left, top, left + new_width, top + new_height))
            return cropped.resize((width, height), Image.Resampling.LANCZOS)
        
        elif augmentation_type == "color_shift":
            # Slight color channel shifts
            r, g, b = image.split()
            
            # Random shifts
            r_shift = random.randint(-20, 20)
            g_shift = random.randint(-20, 20)
            b_shift = random.randint(-20, 20)
            
            r = ImageEnhance.Brightness(r).enhance(1 + r_shift/100)
            g = ImageEnhance.Brightness(g).enhance(1 + g_shift/100)
            b = ImageEnhance.Brightness(b).enhance(1 + b_shift/100)
            
            return Image.merge('RGB', (r, g, b))
        
        else:
            return image
    
    def generate_synthetic_image(self, source_image_path):
        """Generate a synthetic image with multiple random augmentations"""
        
        try:
            # Load source image
            original = Image.open(source_image_path).convert('RGB')
            
            # Apply multiple random augmentations
            augmented = original.copy()
            
            # Randomly select 2-4 augmentations to apply
            augmentation_types = [
                "rotate", "flip_horizontal", "brightness", "contrast", 
                "saturation", "blur", "sharpen", "crop_resize", "color_shift"
            ]
            
            num_augmentations = random.randint(2, 4)
            selected_augmentations = random.sample(augmentation_types, num_augmentations)
            
            for aug_type in selected_augmentations:
                augmented = self.apply_augmentation(augmented, aug_type)
            
            return augmented
            
        except Exception as e:
            print(f"    ❌ Error processing {source_image_path}: {str(e)}")
            return None
    
    def generate_for_breed(self, breed_info, target_count=1000):
        """Generate synthetic images for a specific breed"""
        
        breed_name = breed_info['name']
        breed_path = breed_info['path']
        source_files = breed_info['source_files']
        existing_count = breed_info['existing_images']
        
        print(f"\n🔄 Processing: {breed_name}")
        print(f"   📁 Path: {breed_path}")
        print(f"   📸 Existing images: {existing_count}")
        print(f"   🎯 Target new images: {target_count}")
        
        # Update progress
        self.progress["current_breed"] = breed_name
        self.progress["breeds_status"][breed_name] = {
            "status": "in_progress",
            "existing_images": existing_count,
            "target_new": target_count,
            "generated": 0
        }
        
        generated_count = 0
        
        for i in range(target_count):
            # Select random source image
            source_image = random.choice(source_files)
            
            # Generate synthetic image
            synthetic_image = self.generate_synthetic_image(source_image)
            
            if synthetic_image is not None:
                # Create unique filename
                synthetic_filename = f"{breed_name}_synthetic_{i+1:04d}.jpg"
                synthetic_path = os.path.join(breed_path, synthetic_filename)
                
                # Save synthetic image
                synthetic_image.save(synthetic_path, "JPEG", quality=85)
                generated_count += 1
                self.total_generated += 1
                
                # Progress update every 100 images
                if (i + 1) % 100 == 0:
                    progress_percent = ((i + 1) / target_count) * 100
                    print(f"    📈 Progress: {i+1}/{target_count} ({progress_percent:.1f}%) - Total: {self.total_generated}")
                    
                    # Update and save progress
                    self.progress["breeds_status"][breed_name]["generated"] = generated_count
                    self.save_progress()
        
        # Mark breed as completed
        self.progress["breeds_status"][breed_name]["status"] = "completed"
        self.progress["breeds_status"][breed_name]["generated"] = generated_count
        self.progress["breeds_completed"].append(breed_name)
        
        print(f"    ✅ Completed {breed_name}: {generated_count} new images generated")
        print(f"    📊 Total images in folder: {existing_count + generated_count}")
        
        return generated_count
    
    def generate_all_breeds(self, target_per_breed=1000):
        """Generate synthetic images for all breeds"""
        
        print(f"\n🚀 Starting synthetic image generation...")
        print(f"   🎯 Target: {target_per_breed} new images per breed")
        print(f"   📁 Total breeds: {len(self.breeds)}")
        print(f"   🔢 Total images to generate: {len(self.breeds) * target_per_breed:,}")
        
        start_time = datetime.now()
        
        for i, breed_info in enumerate(self.breeds):
            breed_name = breed_info['name']
            
            # Skip if already completed
            if breed_name in self.progress.get("breeds_completed", []):
                print(f"\n⏭️  Skipping {breed_name} (already completed)")
                continue
            
            print(f"\n📋 Breed {i+1}/{len(self.breeds)}")
            
            try:
                generated = self.generate_for_breed(breed_info, target_per_breed)
                
                if generated > 0:
                    print(f"    🎉 Success: Generated {generated} images for {breed_name}")
                else:
                    print(f"    ⚠️  Warning: No images generated for {breed_name}")
                    
            except Exception as e:
                print(f"    ❌ Error processing {breed_name}: {str(e)}")
                continue
            
            # Save progress after each breed
            self.save_progress()
        
        # Final summary
        end_time = datetime.now()
        duration = end_time - start_time
        
        print(f"\n🎊 GENERATION COMPLETE! 🎊")
        print("=" * 60)
        print(f"⏱️  Duration: {duration}")
        print(f"📊 Total images generated: {self.total_generated:,}")
        print(f"📁 Breeds processed: {len(self.progress.get('breeds_completed', []))}")
        print(f"💾 Progress saved to: {self.progress_file}")
        
        return self.total_generated

def main():
    """Main function to run the augmentation"""
    
    # Initialize augmentor
    augmentor = CattleBreedAugmentor()
    
    # Scan breed folders
    num_breeds = augmentor.scan_breeds()
    
    if num_breeds == 0:
        print("❌ No breed folders found with images!")
        return
    
    # Ask for confirmation
    target_images = 1000
    total_to_generate = num_breeds * target_images
    
    print(f"\n✅ AUTO-STARTING GENERATION:")
    print(f"   📁 Breeds found: {num_breeds}")
    print(f"   🎯 Images per breed: {target_images}")
    print(f"   🔢 Total to generate: {total_to_generate:,}")
    print(f"   💾 All images will be saved to original breed folders")
    
    print(f"\n🚀 Starting generation process automatically...")
    total_generated = augmentor.generate_all_breeds(target_images)
    print(f"\n✨ All done! Generated {total_generated:,} synthetic images!")

if __name__ == "__main__":
    main()