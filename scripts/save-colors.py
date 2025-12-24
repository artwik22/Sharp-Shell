#!/usr/bin/env python3
import json
import sys

colors = {
    "background": sys.argv[1],
    "primary": sys.argv[2],
    "secondary": sys.argv[3],
    "text": sys.argv[4],
    "accent": sys.argv[5]
}

with open(sys.argv[6], 'w') as f:
    json.dump(colors, f, indent=2)

