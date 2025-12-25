#!/usr/bin/env python3
import json
import sys
import os

# Load existing colors.json if it exists to preserve lastWallpaper
existing_data = {}
if len(sys.argv) > 6 and os.path.exists(sys.argv[6]):
    try:
        with open(sys.argv[6], 'r') as f:
            existing_data = json.load(f)
    except:
        pass

colors = {
    "background": sys.argv[1],
    "primary": sys.argv[2],
    "secondary": sys.argv[3],
    "text": sys.argv[4],
    "accent": sys.argv[5]
}

# Preserve lastWallpaper if it exists in existing data
if "lastWallpaper" in existing_data:
    colors["lastWallpaper"] = existing_data["lastWallpaper"]

# If lastWallpaper is provided as 7th argument, use it
if len(sys.argv) > 7 and sys.argv[7]:
    colors["lastWallpaper"] = sys.argv[7]

with open(sys.argv[6], 'w') as f:
    json.dump(colors, f, indent=2)

