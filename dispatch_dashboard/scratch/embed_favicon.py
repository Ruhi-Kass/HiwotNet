import base64
import os
import shutil

favicon_path = r"dispatch_dashboard\web\favicon-64.png"
index_path = r"dispatch_dashboard\web\index.html"
assets_img_dir = r"dispatch_dashboard\assets\images"

# Copy logo to assets
shutil.copy(r"dispatch_dashboard\web\favicon.png", os.path.join(assets_img_dir, "app_logo.png"))
shutil.copy(r"dispatch_dashboard\web\user_logo_raw.png", os.path.join(assets_img_dir, "uploaded_logo.png"))

with open(favicon_path, "rb") as f:
    b64 = base64.b64encode(f.read()).decode("utf-8")

with open(index_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if 'sizes="32x32"' in line or 'sizes="128x128"' in line:
        continue
    if '<title>' in line:
        new_lines.append(f'  <link rel="icon" type="image/png" href="data:image/png;base64,{b64}"/>\n')
        new_lines.append(f'  <link rel="shortcut icon" href="data:image/png;base64,{b64}"/>\n')
    new_lines.append(line)

with open(index_path, "w", encoding="utf-8") as f:
    f.writelines(new_lines)

print("Base64 favicon embedded successfully!")
