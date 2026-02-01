#!/usr/bin/env python3
"""
OverPass App Icon Generator
Creates a simple app icon with bridge and keyboard keys design
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Color palette (Sapphire Nightfall Whisper)
SAPPHIRE_DARK = (38, 43, 64)      # #262B40
SAPPHIRE_SLATE = (44, 68, 77)     # #2C444D
SAPPHIRE_NAVY = (6, 69, 127)      # #06457F
SAPPHIRE_ROYAL = (4, 116, 196)   # #0474C4
SAPPHIRE_DUSTY = (83, 121, 174)  # #5379AE
SAPPHIRE_LIGHT = (168, 196, 236) # #A8C4EC
WHITE = (255, 255, 255)

def create_icon(size=1024):
    """Create app icon at specified size"""
    # Create image with gradient background
    img = Image.new('RGB', (size, size), SAPPHIRE_DARK)
    draw = ImageDraw.Draw(img)
    
    # Draw gradient background (simplified - solid with some variation)
    for y in range(size):
        ratio = y / size
        r = int(SAPPHIRE_DARK[0] * (1 - ratio) + SAPPHIRE_SLATE[0] * ratio)
        g = int(SAPPHIRE_DARK[1] * (1 - ratio) + SAPPHIRE_SLATE[1] * ratio)
        b = int(SAPPHIRE_DARK[2] * (1 - ratio) + SAPPHIRE_SLATE[2] * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b))
    
    # Scale factor for elements
    scale = size / 512
    
    # Draw bridge supports (vertical pillars)
    pillar_width = int(16 * scale)
    pillar_height = int(120 * scale)
    pillar_x1 = int(size * 0.3)
    pillar_x2 = int(size * 0.7)
    pillar_y = int(size * 0.7)
    
    # Left pillar
    draw.rounded_rectangle(
        [pillar_x1 - pillar_width//2, pillar_y - pillar_height,
         pillar_x1 + pillar_width//2, pillar_y],
        radius=int(4 * scale),
        fill=SAPPHIRE_NAVY,
        outline=SAPPHIRE_ROYAL,
        width=int(2 * scale)
    )
    
    # Right pillar
    draw.rounded_rectangle(
        [pillar_x2 - pillar_width//2, pillar_y - pillar_height,
         pillar_x2 + pillar_width//2, pillar_y],
        radius=int(4 * scale),
        fill=SAPPHIRE_NAVY,
        outline=SAPPHIRE_ROYAL,
        width=int(2 * scale)
    )
    
    # Draw bridge deck (horizontal)
    deck_width = int(280 * scale)
    deck_height = int(24 * scale)
    deck_x = (size - deck_width) // 2
    deck_y = pillar_y - pillar_height
    
    draw.rounded_rectangle(
        [deck_x, deck_y - deck_height//2,
         deck_x + deck_width, deck_y + deck_height//2],
        radius=int(8 * scale),
        fill=SAPPHIRE_NAVY,
        outline=SAPPHIRE_ROYAL,
        width=int(2 * scale)
    )
    
    # Draw "OP" letters on bridge
    try:
        # Try to use system font
        font_size = int(80 * scale)
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("/Library/Fonts/Arial Bold.ttf", font_size)
        except:
            font = ImageFont.load_default()
    
    op_text = "OP"
    bbox = draw.textbbox((0, 0), op_text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    text_x = (size - text_width) // 2
    text_y = deck_y - text_height // 2
    
    # Draw text with shadow
    draw.text((text_x + int(2*scale), text_y + int(2*scale)), op_text, 
              fill=(0, 0, 0, 128), font=font)
    draw.text((text_x, text_y), op_text, fill=SAPPHIRE_LIGHT, font=font)
    
    # Draw keyboard keys
    key_size = int(28 * scale)
    key_radius = int(6 * scale)
    
    # Keys approaching (top left)
    keys_top = [("W", SAPPHIRE_ROYAL), ("A", SAPPHIRE_DUSTY), 
                ("S", SAPPHIRE_ROYAL), ("D", SAPPHIRE_DUSTY)]
    start_x = int(size * 0.15)
    start_y = int(size * 0.25)
    for i, (letter, color) in enumerate(keys_top):
        x = start_x + i * int(40 * scale)
        y = start_y
        draw_rounded_key(draw, x, y, key_size, key_radius, letter, color, font, scale)
    
    # Keys flowing away (bottom right)
    keys_bottom = [("↑", SAPPHIRE_DUSTY), ("↓", SAPPHIRE_ROYAL),
                   ("←", SAPPHIRE_DUSTY), ("→", SAPPHIRE_ROYAL)]
    start_x = int(size * 0.55)
    start_y = int(size * 0.75)
    for i, (letter, color) in enumerate(keys_bottom):
        x = start_x + i * int(40 * scale)
        y = start_y
        draw_rounded_key(draw, x, y, key_size, key_radius, letter, color, font, scale)
    
    return img

def draw_rounded_key(draw, x, y, size, radius, letter, color, font, scale):
    """Draw a rounded rectangle key with letter"""
    # Key shadow
    shadow_offset = int(2 * scale)
    draw.rounded_rectangle(
        [x - size//2 + shadow_offset, y - size//2 + shadow_offset,
         x + size//2 + shadow_offset, y + size//2 + shadow_offset],
        radius=radius,
        fill=(0, 0, 0, 100)
    )
    
    # Key background
    draw.rounded_rectangle(
        [x - size//2, y - size//2,
         x + size//2, y + size//2],
        radius=radius,
        fill=color,
        outline=tuple(min(255, c + 40) for c in color),
        width=int(2 * scale)
    )
    
    # Key letter
    try:
        letter_font_size = int(size * 0.5)
        letter_font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", letter_font_size)
    except:
        letter_font = font
    bbox = draw.textbbox((0, 0), letter, font=letter_font)
    letter_width = bbox[2] - bbox[0]
    letter_height = bbox[3] - bbox[1]
    letter_x = x - letter_width // 2
    letter_y = y - letter_height // 2
    draw.text((letter_x, letter_y), letter, fill=WHITE, font=letter_font)

def main():
    """Generate all required icon sizes"""
    icon_dir = "OverPass/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(icon_dir, exist_ok=True)
    
    # Required sizes for macOS
    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]
    
    print("Generating OverPass app icons...")
    for size, filename in sizes:
        print(f"  Creating {filename} ({size}x{size})...")
        icon = create_icon(size)
        icon_path = os.path.join(icon_dir, filename)
        icon.save(icon_path, "PNG")
        print(f"    ✓ Saved to {icon_path}")
    
    print("\n✓ All icon sizes generated!")
    print(f"Icons saved to: {icon_dir}")
    print("\nNext step: Update Contents.json to reference these files.")

if __name__ == "__main__":
    main()
