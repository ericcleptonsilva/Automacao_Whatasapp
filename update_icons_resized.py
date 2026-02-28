from PIL import Image
import os

def resize_and_copy():
    source = "assets/images/logo.png"
    if not os.path.exists(source):
        print("Source logo.png not found!")
        return

    # Android icon sizes (pixels)
    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192
    }
    
    base_path = "android/app/src/main/res"
    img = Image.open(source)

    for folder, size in sizes.items():
        dest_dir = os.path.join(base_path, folder)
        if not os.path.exists(dest_dir):
            os.makedirs(dest_dir)
            
        dest_file = os.path.join(dest_dir, "ic_launcher.png")
        # Resize using Lanczos filter for high quality
        resized_img = img.resize((size, size), Image.Resampling.LANCZOS)
        resized_img.save(dest_file)
        
        # Also save as ic_launcher_round.png for modern Android
        dest_file_round = os.path.join(dest_dir, "ic_launcher_round.png")
        resized_img.save(dest_file_round)
        
        print(f"Generated icons for {folder} ({size}x{size})")

    print("Manual icon update completed successfully.")

if __name__ == "__main__":
    resize_and_copy()
