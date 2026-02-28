import zlib
import struct

def make_png(width, height, rgb_color):
    def I1(value):
        return struct.pack("!B", value & (2**8-1))
    def I4(value):
        return struct.pack("!I", value & (2**32-1))
    
    # Header: 8 bytes
    png = b"\x89PNG\r\n\x1a\n"
    
    # IHDR: 13 bytes
    IHDR = I4(width) + I4(height) + b'\x08\x02\x00\x00\x00'
    png += I4(len(IHDR)) + b"IHDR" + IHDR + I4(zlib.crc32(b"IHDR" + IHDR))
    
    # IDAT: image data
    raw_data = b""
    for y in range(height):
        raw_data += b'\x00' # filter type 0 (None)
        # simplistic fill with color
        raw_data += bytes(rgb_color) * width
        
    compressed_data = zlib.compress(raw_data)
    png += I4(len(compressed_data)) + b"IDAT" + compressed_data + I4(zlib.crc32(b"IDAT" + compressed_data))
    
    # IEND: 0 bytes
    png += I4(0) + b"IEND" + I4(zlib.crc32(b"IEND"))
    
    return png

if __name__ == "__main__":
    # Green color: R=37, G=211, B=102 (#25D366)
    img_data = make_png(512, 512, (37, 211, 102))
    
    with open("assets/images/logo.png", "wb") as f:
        f.write(img_data)
        
    print("Logo created at assets/images/logo.png")
