import os
from PIL import Image, ImageDraw

USER_IMG_PATH = r"C:\Users\Ruhama\.gemini\antigravity\brain\32f56c3d-e968-4b59-96e7-cd73ebe9f589\.user_uploaded\media_1794224667602_491cb59d.png"
WEB_DIR = r"C:\Users\Ruhama\Downloads\dispatch and admin dashboard (2)\dispatch_dashboard\web"
ICONS_DIR = os.path.join(WEB_DIR, "icons")

os.makedirs(ICONS_DIR, exist_ok=True)

# 1. Save raw user image to assets and web
raw_im = Image.open(USER_IMG_PATH)
raw_im.save(os.path.join(WEB_DIR, "user_logo_raw.png"))

# 2. Generate vector-precise clean high-definition icon of the exact emblem:
# The emblem consists of:
# - Rich red background (Brand red: #DC2626 or transparent for favicon)
# - White rounded rectangle / squircle container
# - Inner red rounded rectangle
# - Inner crisp white medical cross

def create_hiwonet_icon(size=512, with_red_bg=True):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    if with_red_bg:
        # Outer red background with smooth rounded corners
        corner_r = int(size * 0.18)
        draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=corner_r, fill=(220, 38, 38, 255))
        
        # White squircle inside
        margin = int(size * 0.14)
        white_r = int(size * 0.16)
        draw.rounded_rectangle([margin, margin, size - margin, size - margin], radius=white_r, fill=(255, 255, 255, 255))
        
        # Inner red square
        inner_m = int(size * 0.28)
        inner_r = int(size * 0.10)
        draw.rounded_rectangle([inner_m, inner_m, size - inner_m, size - inner_m], radius=inner_r, fill=(185, 28, 28, 255))
        
        # Inner white cross
        cx = size // 2
        cy = size // 2
        arm_w = int(size * 0.09)
        arm_h = int(size * 0.26)
        
        # Vertical bar
        draw.rounded_rectangle([cx - arm_w // 2, cy - arm_h // 2, cx + arm_w // 2, cy + arm_h // 2], radius=int(arm_w * 0.25), fill=(255, 255, 255, 255))
        # Horizontal bar
        draw.rounded_rectangle([cx - arm_h // 2, cy - arm_w // 2, cx + arm_h // 2, cy + arm_w // 2], radius=int(arm_w * 0.25), fill=(255, 255, 255, 255))
    else:
        # For favicon: white squircle on transparent background for crisp visibility on both dark and light browser tabs
        margin = int(size * 0.04)
        white_r = int(size * 0.24)
        draw.rounded_rectangle([margin, margin, size - margin, size - margin], radius=white_r, fill=(255, 255, 255, 255))
        
        # Inner red square
        inner_m = int(size * 0.20)
        inner_r = int(size * 0.14)
        draw.rounded_rectangle([inner_m, inner_m, size - inner_m, size - inner_m], radius=inner_r, fill=(185, 28, 28, 255))
        
        # Inner white cross
        cx = size // 2
        cy = size // 2
        arm_w = int(size * 0.11)
        arm_h = int(size * 0.34)
        
        draw.rounded_rectangle([cx - arm_w // 2, cy - arm_h // 2, cx + arm_w // 2, cy + arm_h // 2], radius=int(arm_w * 0.25), fill=(255, 255, 255, 255))
        draw.rounded_rectangle([cx - arm_h // 2, cy - arm_w // 2, cx + arm_h // 2, cy + arm_w // 2], radius=int(arm_w * 0.25), fill=(255, 255, 255, 255))

    return img

# Generate all required icon files
favicon = create_hiwonet_icon(128, with_red_bg=True)
favicon.save(os.path.join(WEB_DIR, "favicon.png"))
print("Saved favicon.png")

icon_192 = create_hiwonet_icon(192, with_red_bg=True)
icon_192.save(os.path.join(ICONS_DIR, "Icon-192.png"))
icon_192.save(os.path.join(ICONS_DIR, "Icon-maskable-192.png"))
print("Saved Icon-192.png & Icon-maskable-192.png")

icon_512 = create_hiwonet_icon(512, with_red_bg=True)
icon_512.save(os.path.join(ICONS_DIR, "Icon-512.png"))
icon_512.save(os.path.join(ICONS_DIR, "Icon-maskable-512.png"))
print("Saved Icon-512.png & Icon-maskable-512.png")

# Also save a 64x64 favicon
fav_32 = favicon.resize((64, 64), Image.Resampling.LANCZOS)
fav_32.save(os.path.join(WEB_DIR, "favicon-64.png"))

print("All browser icons successfully created!")
