import shutil
import os

def overwrite_icons():
    source = "assets/images/logo.png"
    
    # List of mipmap folders
    folders = [
        "mipmap-hdpi",
        "mipmap-mdpi",
        "mipmap-xhdpi",
        "mipmap-xxhdpi",
        "mipmap-xxxhdpi"
    ]
    
    base_path = "android/app/src/main/res"
    
    if not os.path.exists(source):
        print("Source logo not found!")
        return

    for folder in folders:
        dest_dir = os.path.join(base_path, folder)
        if os.path.exists(dest_dir):
            dest_file = os.path.join(dest_dir, "ic_launcher.png")
            shutil.copy(source, dest_file)
            print(f"Overwrote {dest_file}")
            
    print("All icons overwritten manually.")

if __name__ == "__main__":
    overwrite_icons()
