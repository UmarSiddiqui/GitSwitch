#!/usr/bin/env python3
"""Generate GitSwitch README assets."""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
import os

# Paths
ASSETS_DIR = "/Users/umarsiddiqui/Desktop/GitSwitch-Repo/assets"
ICON_PATH = "/Users/umarsiddiqui/Desktop/GitSwitch/GitSwitch/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png"

# Fonts (macOS system fonts)
HELVETICA = "/System/Library/Fonts/Helvetica.ttc"
HELVETICA_NEUE = "/System/Library/Fonts/HelveticaNeue.ttc"
SF_PRO = "/System/Library/Fonts/SFNS.ttf"

def load_font(path, size, index=0):
    try:
        return ImageFont.truetype(path, size, index=index)
    except Exception:
        try:
            return ImageFont.truetype(path, size, index=1)
        except Exception:
            return ImageFont.load_default()

def rounded_rectangle(draw, xy, radius, fill=None, outline=None, width=1):
    """Draw a rounded rectangle."""
    x1, y1, x2, y2 = xy
    r = radius
    # Draw main body
    if fill is not None:
        draw.rectangle([x1 + r, y1, x2 - r, y2], fill=fill)
        draw.rectangle([x1, y1 + r, x2, y2 - r], fill=fill)
        # Draw four corners
        draw.ellipse([x1, y1, x1 + 2*r, y1 + 2*r], fill=fill)
        draw.ellipse([x2 - 2*r, y1, x2, y1 + 2*r], fill=fill)
        draw.ellipse([x1, y2 - 2*r, x1 + 2*r, y2], fill=fill)
        draw.ellipse([x2 - 2*r, y2 - 2*r, x2, y2], fill=fill)
    if outline:
        draw.arc([x1, y1, x1 + 2*r, y1 + 2*r], 180, 270, fill=outline, width=width)
        draw.arc([x2 - 2*r, y1, x2, y1 + 2*r], 270, 360, fill=outline, width=width)
        draw.arc([x1, y2 - 2*r, x1 + 2*r, y2], 90, 180, fill=outline, width=width)
        draw.arc([x2 - 2*r, y2 - 2*r, x2, y2], 0, 90, fill=outline, width=width)
        draw.line([(x1 + r, y1), (x2 - r, y1)], fill=outline, width=width)
        draw.line([(x1 + r, y2), (x2 - r, y2)], fill=outline, width=width)
        draw.line([(x1, y1 + r), (x1, y2 - r)], fill=outline, width=width)
        draw.line([(x2, y1 + r), (x2, y2 - r)], fill=outline, width=width)

def draw_gradient_bg(img, color1, color2, direction="vertical"):
    """Draw a gradient background on the image."""
    draw = ImageDraw.Draw(img)
    w, h = img.size
    for i in range(h if direction == "vertical" else w):
        ratio = i / (h if direction == "vertical" else w)
        r = int(color1[0] * (1 - ratio) + color2[0] * ratio)
        g = int(color1[1] * (1 - ratio) + color2[1] * ratio)
        b = int(color1[2] * (1 - ratio) + color2[2] * ratio)
        if direction == "vertical":
            draw.line([(0, i), (w, i)], fill=(r, g, b))
        else:
            draw.line([(i, 0), (i, h)], fill=(r, g, b))

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def create_avatar(draw, x, y, size, initials, bg_color, text_color=(255, 255, 255)):
    """Draw a circular avatar with initials."""
    font = load_font(HELVETICA_NEUE, int(size * 0.45), index=1)
    draw.ellipse([x, y, x + size, y + size], fill=bg_color)
    bbox = draw.textbbox((0, 0), initials, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text((x + (size - tw) / 2, y + (size - th) / 2 - 2), initials, fill=text_color, font=font)

def create_checkmark(draw, x, y, size, color):
    """Draw a checkmark."""
    draw.line([(x, y + size * 0.5), (x + size * 0.35, y + size * 0.75), (x + size, y)], fill=color, width=max(2, int(size * 0.12)))

# =============================================================================
# 1. BANNER
# =============================================================================
def generate_banner():
    W, H = 1280, 640
    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img)

    # Dark gradient background: #4A5568 → #2D3748 → even darker at bottom
    c1 = hex_to_rgb("#4A5568")
    c2 = hex_to_rgb("#2D3748")
    c3 = hex_to_rgb("#1A202C")
    for i in range(H):
        ratio = i / H
        if ratio < 0.5:
            r = int(c1[0] * (1 - ratio * 2) + c2[0] * (ratio * 2))
            g = int(c1[1] * (1 - ratio * 2) + c2[1] * (ratio * 2))
            b = int(c1[2] * (1 - ratio * 2) + c2[2] * (ratio * 2))
        else:
            rr = (ratio - 0.5) * 2
            r = int(c2[0] * (1 - rr) + c3[0] * rr)
            g = int(c2[1] * (1 - rr) + c3[1] * rr)
            b = int(c2[2] * (1 - rr) + c3[2] * rr)
        draw.line([(0, i), (W, i)], fill=(r, g, b))

    # macOS window chrome at top
    bar_h = 36
    draw.rectangle([0, 0, W, bar_h], fill=(30, 30, 30, 200))
    # Traffic lights
    lights = [("#FF5F56", 18), ("#FFBD2E", 38), ("#27C93F", 58)]
    for color, lx in lights:
        draw.ellipse([lx, 12, lx + 12, 24], fill=hex_to_rgb(color))
    # Window title
    title_font = load_font(HELVETICA_NEUE, 13, index=0)
    draw.text((W // 2 - 30, 10), "GitSwitch", fill=(180, 180, 180), font=title_font)

    # Load app icon
    icon = Image.open(ICON_PATH).convert("RGBA")
    icon_size = 220
    icon = icon.resize((icon_size, icon_size), Image.LANCZOS)

    # Place icon on left-center
    icon_x = 280
    icon_y = (H - icon_size) // 2 + 10

    # Icon shadow/glow
    shadow = Image.new("RGBA", (icon_size + 40, icon_size + 40), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.ellipse([10, 10, icon_size + 30, icon_size + 30], fill=(0, 0, 0, 80))
    shadow = shadow.filter(ImageFilter.GaussianBlur(15))
    img.paste(shadow, (icon_x - 20, icon_y - 20), shadow)

    # Rounded mask for icon
    mask = Image.new("L", (icon_size, icon_size), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.ellipse([0, 0, icon_size, icon_size], fill=255)
    icon.putalpha(mask)
    img.paste(icon, (icon_x, icon_y), icon)

    # Text on right
    title_font = load_font(HELVETICA_NEUE, 72, index=1)
    subtitle_font = load_font(HELVETICA_NEUE, 26, index=0)
    tagline_font = load_font(HELVETICA_NEUE, 18, index=0)

    draw.text((icon_x + icon_size + 50, icon_y + 30), "GitSwitch", fill=(255, 255, 255), font=title_font)
    draw.text((icon_x + icon_size + 55, icon_y + 120), "Seamlessly switch between GitHub profiles on macOS", fill=(160, 174, 192), font=subtitle_font)
    draw.text((icon_x + icon_size + 55, icon_y + 165), "A minimalistic menu-bar app for developers", fill=(113, 128, 150), font=tagline_font)

    # Subtle decorative elements - small dots grid on right
    for rx in range(W - 200, W - 40, 30):
        for ry in range(120, H - 80, 30):
            draw.ellipse([rx, ry, rx + 3, ry + 3], fill=(255, 255, 255, 30))

    img.save(os.path.join(ASSETS_DIR, "banner.png"), "PNG")
    print("✓ banner.png created")

# =============================================================================
# 2. SCREENSHOT-MENUBAR
# =============================================================================
def generate_screenshot_menubar():
    W, H = 800, 400
    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img)

    # Background (desktop-like dark blur)
    draw_gradient_bg(img, hex_to_rgb("#1A202C"), hex_to_rgb("#2D3748"))

    # macOS menu bar
    menu_h = 28
    draw.rectangle([0, 0, W, menu_h], fill=(30, 30, 30))
    # Apple logo placeholder (simple apple shape as text or ignore)
    font_small = load_font(HELVETICA_NEUE, 13, index=0)
    draw.text((14, 5), "GitSwitch", fill=(240, 240, 240), font=font_small)

    # Menu items
    draw.text((100, 5), "File", fill=(200, 200, 200), font=font_small)
    draw.text((145, 5), "Edit", fill=(200, 200, 200), font=font_small)
    draw.text((190, 5), "View", fill=(200, 200, 200), font=font_small)
    draw.text((240, 5), "Window", fill=(200, 200, 200), font=font_small)
    draw.text((300, 5), "Help", fill=(200, 200, 200), font=font_small)

    # Right side status icons area
    draw.text((W - 160, 5), "Mon 9:41 AM", fill=(200, 200, 200), font=font_small)

    # App icon in menu bar (small, clearer)
    icon = Image.open(ICON_PATH).convert("RGBA")
    icon_mb = icon.resize((20, 20), Image.LANCZOS)
    # Place it near the right, before clock
    icon_x = W - 240
    img.paste(icon_mb, (icon_x, 4), icon_mb)

    # Dropdown menu
    menu_w = 230
    menu_x = icon_x - 10
    menu_y = menu_h + 4
    menu_h_total = 180

    # Menu shadow
    shadow = Image.new("RGBA", (menu_w + 20, menu_h_total + 20), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    rounded_rectangle(sdraw, [5, 5, menu_w + 15, menu_h_total + 15], 10, (0, 0, 0, 100))
    shadow = shadow.filter(ImageFilter.GaussianBlur(10))
    img.paste(shadow, (menu_x - 10, menu_y - 10), shadow)

    # Menu background
    rounded_rectangle(draw, [menu_x, menu_y, menu_x + menu_w, menu_y + menu_h_total], 8, (45, 45, 48))
    # Subtle border
    rounded_rectangle(draw, [menu_x, menu_y, menu_x + menu_w, menu_y + menu_h_total], 8, outline=(70, 70, 75), width=1)

    # Menu content
    row_h = 44
    font_name = load_font(HELVETICA_NEUE, 15, index=1)
    font_detail = load_font(HELVETICA_NEUE, 12, index=0)
    font_menu = load_font(HELVETICA_NEUE, 14, index=0)

    # Profile 1: Personal (active)
    y1 = menu_y + 10
    # Avatar
    create_avatar(draw, menu_x + 14, y1, 32, "US", hex_to_rgb("#3182CE"))
    # Name
    draw.text((menu_x + 56, y1 + 2), "Personal", fill=(255, 255, 255), font=font_name)
    draw.text((menu_x + 56, y1 + 22), "Umar Siddiqui", fill=(150, 150, 150), font=font_detail)
    # Green checkmark — draw a small green circle with white check
    check_cx = menu_x + menu_w - 32
    check_cy = y1 + 16
    draw.ellipse([check_cx - 10, check_cy - 10, check_cx + 10, check_cy + 10], fill=hex_to_rgb("#48BB78"))
    # White checkmark inside
    draw.line([(check_cx - 5, check_cy), (check_cx - 2, check_cy + 4), (check_cx + 5, check_cy - 4)], fill=(255, 255, 255), width=2)

    # Divider
    draw.line([(menu_x + 12, menu_y + 56), (menu_x + menu_w - 12, menu_y + 56)], fill=(70, 70, 75), width=1)

    # Profile 2: Work
    y2 = menu_y + 64
    create_avatar(draw, menu_x + 14, y2, 32, "UA", hex_to_rgb("#DD6B20"))
    draw.text((menu_x + 56, y2 + 2), "Work", fill=(255, 255, 255), font=font_name)
    draw.text((menu_x + 56, y2 + 22), "Umar ABWeb", fill=(150, 150, 150), font=font_detail)

    # Divider
    draw.line([(menu_x + 12, menu_y + 110), (menu_x + menu_w - 12, menu_y + 110)], fill=(70, 70, 75), width=1)

    # Settings…
    y3 = menu_y + 120
    draw.text((menu_x + 16, y3 + 4), "Settings…", fill=(220, 220, 220), font=font_menu)
    # Shortcut hint — right aligned using textbbox
    shortcut1 = "Cmd + ,"
    bbox = draw.textbbox((0, 0), shortcut1, font=font_detail)
    sw = bbox[2] - bbox[0]
    draw.text((menu_x + menu_w - 16 - sw, y3 + 6), shortcut1, fill=(120, 120, 120), font=font_detail)

    # Quit
    y4 = menu_y + 154
    draw.text((menu_x + 16, y4 + 4), "Quit GitSwitch", fill=(220, 220, 220), font=font_menu)
    shortcut2 = "Cmd + Q"
    bbox = draw.textbbox((0, 0), shortcut2, font=font_detail)
    sw = bbox[2] - bbox[0]
    draw.text((menu_x + menu_w - 16 - sw, y4 + 6), shortcut2, fill=(120, 120, 120), font=font_detail)

    img.save(os.path.join(ASSETS_DIR, "screenshot-menubar.png"), "PNG")
    print("✓ screenshot-menubar.png created")

# =============================================================================
# 3. SCREENSHOT-SETTINGS
# =============================================================================
def generate_screenshot_settings():
    W, H = 800, 500
    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img)

    # Desktop blur background
    draw_gradient_bg(img, hex_to_rgb("#1A202C"), hex_to_rgb("#2D3748"))

    # Window
    win_x, win_y = 80, 40
    win_w, win_h = W - 160, H - 80

    # Window shadow
    shadow = Image.new("RGBA", (win_w + 40, win_h + 40), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    rounded_rectangle(sdraw, [10, 10, win_w + 30, win_h + 30], 16, (0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(15))
    img.paste(shadow, (win_x - 20, win_y - 20), shadow)

    # Window body (dark translucent)
    rounded_rectangle(draw, [win_x, win_y, win_x + win_w, win_y + win_h], 12, (35, 39, 47))
    rounded_rectangle(draw, [win_x, win_y, win_x + win_w, win_y + win_h], 12, outline=(60, 65, 75), width=1)

    # Title bar
    title_bar_h = 36
    rounded_rectangle(draw, [win_x, win_y, win_x + win_w, win_y + title_bar_h], 12, (40, 44, 52))
    # Traffic lights
    for color, lx in [("#FF5F56", win_x + 14), ("#FFBD2E", win_x + 32), ("#27C93F", win_x + 50)]:
        draw.ellipse([lx, win_y + 12, lx + 12, win_y + 24], fill=hex_to_rgb(color))

    font_title = load_font(HELVETICA_NEUE, 14, index=1)
    bbox = draw.textbbox((0, 0), "Git Profiles", font=font_title)
    tw = bbox[2] - bbox[0]
    draw.text((win_x + win_w // 2 - tw // 2, win_y + 10), "Git Profiles", fill=(200, 200, 200), font=font_title)

    # Profile cards
    card_w = (win_w - 48) // 2
    card_h = 290
    card_y = win_y + 56
    font_card_title = load_font(HELVETICA_NEUE, 18, index=1)
    font_card_text = load_font(HELVETICA_NEUE, 13, index=0)
    font_card_label = load_font(HELVETICA_NEUE, 11, index=0)

    # Card 1: Personal (active)
    c1x = win_x + 20
    # Card background (ultraThinMaterial look)
    rounded_rectangle(draw, [c1x, card_y, c1x + card_w, card_y + card_h], 10, (50, 55, 65))
    rounded_rectangle(draw, [c1x, card_y, c1x + card_w, card_y + card_h], 10, outline=(72, 187, 120), width=2)

    # Avatar with green ring
    av_size = 64
    av_x = c1x + card_w // 2 - av_size // 2
    av_y = card_y + 20
    # Green ring
    draw.ellipse([av_x - 4, av_y - 4, av_x + av_size + 4, av_y + av_size + 4], fill=hex_to_rgb("#48BB78"))
    create_avatar(draw, av_x, av_y, av_size, "US", hex_to_rgb("#3182CE"))
    # Active dot
    draw.ellipse([av_x + av_size - 10, av_y + av_size - 10, av_x + av_size + 4, av_y + av_size + 4], fill=hex_to_rgb("#48BB78"))
    draw.ellipse([av_x + av_size - 8, av_y + av_size - 8, av_x + av_size + 2, av_y + av_size + 2], fill=(255, 255, 255))

    # Name
    draw.text((c1x + 16, card_y + 100), "Personal", fill=(255, 255, 255), font=font_card_title)
    # Details
    details = [
        ("Username", "umarsiddiqui"),
        ("Email", "umar@example.com"),
        ("SSH Key", "~/.ssh/id_rsa_personal"),
        ("Signing Key", "A1B2C3D4"),
    ]
    dy = card_y + 140
    for label, value in details:
        draw.text((c1x + 16, dy), label, fill=(130, 140, 155), font=font_card_label)
        draw.text((c1x + 16, dy + 14), value, fill=(200, 210, 220), font=font_card_text)
        dy += 34

    # Active badge
    badge_w = 56
    badge_h = 22
    badge_x = c1x + card_w - badge_w - 12
    badge_y = card_y + 12
    rounded_rectangle(draw, [badge_x, badge_y, badge_x + badge_w, badge_y + badge_h], 11, hex_to_rgb("#48BB78"))
    font_badge = load_font(HELVETICA_NEUE, 11, index=1)
    draw.text((badge_x + 10, badge_y + 4), "Active", fill=(255, 255, 255), font=font_badge)

    # Card 2: Work (inactive)
    c2x = win_x + 28 + card_w
    rounded_rectangle(draw, [c2x, card_y, c2x + card_w, card_y + card_h], 10, (50, 55, 65))
    rounded_rectangle(draw, [c2x, card_y, c2x + card_w, card_y + card_h], 10, outline=(80, 85, 95), width=2)

    av_x2 = c2x + card_w // 2 - av_size // 2
    draw.ellipse([av_x2 - 4, av_y - 4, av_x2 + av_size + 4, av_y + av_size + 4], fill=hex_to_rgb("#718096"))
    create_avatar(draw, av_x2, av_y, av_size, "UA", hex_to_rgb("#DD6B20"))

    draw.text((c2x + 16, card_y + 100), "Work", fill=(255, 255, 255), font=font_card_title)
    details2 = [
        ("Username", "umar-abweb"),
        ("Email", "umar@abweb.dev"),
        ("SSH Key", "~/.ssh/id_rsa_work"),
        ("Signing Key", "E5F6G7H8"),
    ]
    dy = card_y + 140
    for label, value in details2:
        draw.text((c2x + 16, dy), label, fill=(130, 140, 155), font=font_card_label)
        draw.text((c2x + 16, dy + 14), value, fill=(200, 210, 220), font=font_card_text)
        dy += 34

    # Add Profile button
    btn_w = 160
    btn_h = 36
    btn_x = win_x + win_w // 2 - btn_w // 2
    btn_y = win_y + win_h - 56
    rounded_rectangle(draw, [btn_x, btn_y, btn_x + btn_w, btn_y + btn_h], 18, hex_to_rgb("#4299E1"))
    font_btn = load_font(HELVETICA_NEUE, 14, index=1)
    bbox = draw.textbbox((0, 0), "+ Add Profile", font=font_btn)
    tw = bbox[2] - bbox[0]
    draw.text((btn_x + btn_w // 2 - tw // 2, btn_y + 9), "+ Add Profile", fill=(255, 255, 255), font=font_btn)

    img.save(os.path.join(ASSETS_DIR, "screenshot-settings.png"), "PNG")
    print("✓ screenshot-settings.png created")

# =============================================================================
# 4. STAR GRAPH DEMO
# =============================================================================
def generate_star_graph():
    W, H = 800, 400
    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img)

    # Background
    draw_gradient_bg(img, hex_to_rgb("#1A202C"), hex_to_rgb("#2D3748"))

    # Title
    font_title = load_font(HELVETICA_NEUE, 28, index=1)
    draw.text((60, 30), "Star History", fill=(255, 255, 255), font=font_title)

    font_sub = load_font(HELVETICA_NEUE, 14, index=0)
    draw.text((60, 68), "GitSwitch — github.com/umarsiddiqui/GitSwitch", fill=(150, 160, 180), font=font_sub)

    # Chart area
    chart_x1, chart_y1 = 60, 110
    chart_x2, chart_y2 = W - 60, H - 60

    # Grid dots
    for gx in range(chart_x1, chart_x2 + 1, 50):
        for gy in range(chart_y1, chart_y2 + 1, 40):
            draw.ellipse([gx - 1, gy - 1, gx + 1, gy + 1], fill=(80, 90, 110))

    # Axis lines
    draw.line([(chart_x1, chart_y1), (chart_x1, chart_y2)], fill=(120, 130, 150), width=1)
    draw.line([(chart_x1, chart_y2), (chart_x2, chart_y2)], fill=(120, 130, 150), width=1)

    # Data points: exponential growth curve
    import random
    random.seed(42)
    points = []
    n = 30
    for i in range(n):
        x = chart_x1 + (chart_x2 - chart_x1) * i / (n - 1)
        # S-curve: slow start, acceleration, then steady
        t = i / (n - 1)
        stars = 500 * (t ** 2.5) + random.uniform(-15, 15)
        stars = max(0, stars)
        y = chart_y2 - (stars / 500) * (chart_y2 - chart_y1)
        points.append((x, y, int(stars)))

    # Draw gradient area under curve
    for i in range(len(points) - 1):
        x1, y1, _ = points[i]
        x2, y2, _ = points[i + 1]
        # Fill area under segment
        for yy in range(int(min(y1, y2)), chart_y2 + 1):
            alpha = 1 - (yy - chart_y1) / (chart_y2 - chart_y1 + 1)
            r = int(72 * alpha * 0.3)
            g = int(187 * alpha * 0.3)
            b = int(120 * alpha * 0.3)
            # Simple scanline approximation
        # Actually let's draw a polygon for area fill

    # Draw area under curve as polygon with transparency
    area_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    area_draw = ImageDraw.Draw(area_img)
    poly = [(chart_x1, chart_y2)]
    for x, y, _ in points:
        poly.append((x, y))
    poly.append((chart_x2, chart_y2))
    area_draw.polygon(poly, fill=(72, 187, 120, 40))
    # Blend
    img = img.convert("RGBA")
    img = Image.alpha_composite(img, area_img)
    draw = ImageDraw.Draw(img)

    # Draw line with glow
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    for i in range(len(points) - 1):
        x1, y1, _ = points[i]
        x2, y2, _ = points[i + 1]
        gdraw.line([(x1, y1), (x2, y2)], fill=(72, 187, 120, 180), width=6)
    glow = glow.filter(ImageFilter.GaussianBlur(4))
    img = Image.alpha_composite(img, glow)
    draw = ImageDraw.Draw(img)

    # Main line
    for i in range(len(points) - 1):
        x1, y1, _ = points[i]
        x2, y2, _ = points[i + 1]
        draw.line([(x1, y1), (x2, y2)], fill=(72, 187, 120), width=3)

    # Data points
    font_axis = load_font(HELVETICA_NEUE, 12, index=0)
    for i, (x, y, stars) in enumerate(points):
        if i % 5 == 0 or i == len(points) - 1:
            r = 5
            draw.ellipse([x - r, y - r, x + r, y + r], fill=(72, 187, 120))
            draw.ellipse([x - r + 2, y - r + 2, x + r - 2, y + r - 2], fill=(255, 255, 255))

    # End label
    last_x, last_y, last_stars = points[-1]
    font_label = load_font(HELVETICA_NEUE, 14, index=1)
    label = f"{last_stars} ⭐"
    draw.text((last_x + 12, last_y - 10), label, fill=(72, 187, 120), font=font_label)

    # Y-axis labels
    for val in [0, 100, 200, 300, 400, 500]:
        y = chart_y2 - (val / 500) * (chart_y2 - chart_y1)
        draw.text((chart_x1 - 40, int(y) - 6), str(val), fill=(130, 140, 160), font=font_axis)
        draw.line([(chart_x1 - 4, int(y)), (chart_x1, int(y))], fill=(120, 130, 150), width=1)

    # X-axis labels (months)
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
    for i, month in enumerate(months):
        x = chart_x1 + (chart_x2 - chart_x1) * i / (len(months) - 1)
        bbox = draw.textbbox((0, 0), month, font=font_axis)
        tw = bbox[2] - bbox[0]
        draw.text((int(x - tw // 2), chart_y2 + 10), month, fill=(130, 140, 160), font=font_axis)

    img.convert("RGB").save(os.path.join(ASSETS_DIR, "star-graph-demo.png"), "PNG")
    print("✓ star-graph-demo.png created")

# =============================================================================
if __name__ == "__main__":
    os.makedirs(ASSETS_DIR, exist_ok=True)
    generate_banner()
    generate_screenshot_menubar()
    generate_screenshot_settings()
    generate_star_graph()
    print("\nAll assets generated successfully!")
