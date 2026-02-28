from PIL import Image, ImageDraw, ImageFont
import os

def create_logo():
    # Create directory if it doesn't exist
    os.makedirs('assets/images', exist_ok=True)
    
    # Create a 512x512 image (standard icon size)
    # Background color: WhatsApp green-ish (#25D366)
    img = Image.new('RGB', (1024, 1024), color = (37, 211, 102))
    
    d = ImageDraw.Draw(img)
    
    # Draw a chat bubble shape (simplified as a rounded rectangle + triangle)
    # Actually just a circle/rounded rect with "AUTO" text
    
    # White circle in the middle
    d.ellipse((100, 100, 924, 924), fill=(255, 255, 255))
    
    # Draw "AUTO" text (simulated with basic shapes or default font if available, but to be safe lets just draw a gear-like shape)
    # Simple gear shape (circle with teeth)
    center = (512, 512)
    radius = 250
    d.ellipse((center[0]-radius, center[1]-radius, center[0]+radius, center[1]+radius), fill=(7, 94, 84)) # Teal color
    
    # Save
    img.save('assets/images/logo.png')
    print("Logo created at assets/images/logo.png")

if __name__ == "__main__":
    create_logo()
