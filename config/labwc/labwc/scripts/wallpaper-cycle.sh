#!/bin/bash

# Configuration
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"  # Change to your wallpaper directory
INTERVAL=300  # Change wallpaper every 300 seconds (5 minutes)

# Create a temporary Python script to extract dominant color
cat > /tmp/extract_color.py << 'EOL'
from PIL import Image
import sys
import colorsys

def get_dominant_color(image_path):
    img = Image.open(image_path).convert('RGBA')
    width, height = img.size
    
    # Resize for faster processing
    img = img.resize((100, int(100 * height / width)))
    
    # Get pixel data
    pixels = list(img.getdata())
    pixel_count = len(pixels)
    
    # Count non-transparent pixels
    r_total = g_total = b_total = count = 0
    for r, g, b, a in pixels:
        if a > 0:  # Skip transparent pixels
            r_total += r
            g_total += g
            b_total += b
            count += 1
            
    if count == 0:
        return "#000000"  # Default to black if no non-transparent pixels
        
    # Calculate average color
    r_avg = r_total // count
    g_avg = g_total // count
    b_avg = b_total // count
    
    # Convert to hex
    color_hex = "#{:02x}{:02x}{:02x}".format(r_avg, g_avg, b_avg)
    return color_hex

if __name__ == "__main__":
    print(get_dominant_color(sys.argv[1]))
EOL

# Make sure the script is executable
chmod +x /tmp/extract_color.py

# Keep track of current swaybg PID
CURRENT_PID=""

# Function to change wallpaper
change_wallpaper() {
    # Select a random wallpaper
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | shuf -n 1)
    
    if [ -z "$WALLPAPER" ]; then
        echo "No wallpapers found in $WALLPAPER_DIR"
        exit 1
    fi
    
    # Extract dominant color
    BGCOLOR=$(python3 /tmp/extract_color.py "$WALLPAPER")
    
    # Start new swaybg process
    swaybg -m center -i "$WALLPAPER" -c "$BGCOLOR" &
    NEW_PID=$!
    
    # Wait a moment for the new wallpaper to load
    sleep 0.5
    
    # Kill the previous swaybg process if it exists
    if [ ! -z "$CURRENT_PID" ]; then
        kill $CURRENT_PID 2>/dev/null || true
    fi
    
    # Update current PID
    CURRENT_PID=$NEW_PID
    
    echo "Set wallpaper: $WALLPAPER with background color: $BGCOLOR"
}

# Run in a loop
while true; do
    change_wallpaper
    sleep $INTERVAL
done
