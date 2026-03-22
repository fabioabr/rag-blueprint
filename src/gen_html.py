import os

# Read logo files
with open('/tmp/logo_dark.txt', 'r') as f:
    logo_dark_line = f.read().strip()

with open('/tmp/logo_light.txt', 'r') as f:
    logo_light_line = f.read().strip()

print("Logos loaded OK")
print(f"  logo_dark: {len(logo_dark_line)} chars")
print(f"  logo_light: {len(logo_light_line)} chars")
