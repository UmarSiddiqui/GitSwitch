#!/usr/bin/env python3
"""Generate GitSwitch README assets."""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
import os

# Paths (repo-relative)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
ASSETS_DIR = SCRIPT_DIR
ICON_PATH = os.path.join(
    REPO_ROOT,
    "src",
    "Assets.xcassets",
    "AppIcon.appiconset",
    "icon_512x512@2x.png",
)
BRAND = (56, 82, 214)

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


def draw_brand_tile(draw, x, y, size):
    """Rounded tile matching `GitSwitchBrandTile` (indigo + arrows)."""
    r = max(4, int(size * 0.23))
    rounded_rectangle(draw, [x, y, x + size, y + size], r, fill=BRAND)
    f = load_font(HELVETICA_NEUE, int(size * 0.44), index=1)
    sym = "\u21c4"  # ⇄
    bbox = draw.textbbox((0, 0), sym, font=f)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text((x + (size - tw) / 2, y + (size - th) / 2 - 1), sym, fill=(255, 255, 255), font=f)


def draw_sf_menu_icon(img, cx, cy, diameter):
    """Approximate `arrow.left.arrow.right.circle` used in MenuBarExtra."""
    draw = ImageDraw.Draw(img)
    r = diameter // 2
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(180, 185, 195), width=2)
    f = load_font(HELVETICA_NEUE, int(diameter * 0.42), index=1)
    sym = "\u21c4"
    bbox = draw.textbbox((0, 0), sym, font=f)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text((cx - tw / 2, cy - th / 2 - 1), sym, fill=(230, 232, 235), font=f)


def draw_active_radio(draw, cx, cy, outer=10):
    """Approximate `largecircle.fill.circle` (indigo / gray)."""
    draw.ellipse([cx - outer, cy - outer, cx + outer, cy + outer], outline=BRAND, width=2)
    draw.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=BRAND)


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
# 2. SCREENSHOT-MENUBAR  (MenuBarExtra `.window` popover — see MenuBarView.swift)
# =============================================================================
def generate_screenshot_menubar():
    W, H = 920, 560
    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img)

    draw_gradient_bg(img, hex_to_rgb("#1A202C"), hex_to_rgb("#2D3748"))

    menu_h = 28
    draw.rectangle([0, 0, W, menu_h], fill=(30, 30, 30))
    font_small = load_font(HELVETICA_NEUE, 13, index=0)
    draw.text((100, 5), "File", fill=(200, 200, 200), font=font_small)
    draw.text((145, 5), "Edit", fill=(200, 200, 200), font=font_small)
    draw.text((190, 5), "View", fill=(200, 200, 200), font=font_small)
    draw.text((240, 5), "Window", fill=(200, 200, 200), font=font_small)
    draw.text((300, 5), "Help", fill=(200, 200, 200), font=font_small)
    draw.text((W - 168, 5), "Tue 10:09 AM", fill=(200, 200, 200), font=font_small)

    icon_cx = W - 214
    icon_cy = menu_h // 2
    draw_sf_menu_icon(img, icon_cx, icon_cy, 22)

    pop_w, pop_h = 328, 418
    pop_x = icon_cx - pop_w // 2 + 4
    pop_y = menu_h + 10

    shadow = Image.new("RGBA", (pop_w + 36, pop_h + 36), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    rounded_rectangle(sdraw, [8, 8, pop_w + 24, pop_h + 24], 16, (0, 0, 0, 110))
    shadow = shadow.filter(ImageFilter.GaussianBlur(14))
    img.paste(shadow, (pop_x - 18, pop_y - 18), shadow)

    panel = (52, 52, 55)
    rounded_rectangle(draw, [pop_x, pop_y, pop_x + pop_w, pop_y + pop_h], 14, panel)
    rounded_rectangle(draw, [pop_x, pop_y, pop_x + pop_w, pop_y + pop_h], 14, outline=(82, 84, 90), width=1)

    ix = pop_x + 14
    iy = pop_y + 12
    draw_brand_tile(draw, ix, iy, 26)
    font_brand = load_font(HELVETICA_NEUE, 14, index=1)
    font_tag = load_font(HELVETICA_NEUE, 10, index=0)
    draw.text((ix + 34, iy + 1), "GitSwitch", fill=(245, 245, 247), font=font_brand)
    draw.text((ix + 34, iy + 17), "Git & GitHub identity", fill=(152, 156, 165), font=font_tag)

    card_x = pop_x + 10
    card_y = iy + 42
    card_w = pop_w - 20
    card_h = 102
    rounded_rectangle(draw, [card_x, card_y, card_x + card_w, card_y + card_h], 12, (38, 40, 46))
    rounded_rectangle(
        draw,
        [card_x, card_y, card_x + card_w, card_y + card_h],
        12,
        outline=(BRAND[0], BRAND[1], BRAND[2]),
        width=1,
    )
    draw.rectangle([card_x + 4, card_y + 12, card_x + 8, card_y + card_h - 12], fill=BRAND)

    font_caps = load_font(HELVETICA_NEUE, 9, index=1)
    draw.text((card_x + 18, card_y + 12), "ACTIVE", fill=BRAND, font=font_caps)
    font_active_title = load_font(HELVETICA_NEUE, 16, index=1)
    font_mono = load_font(HELVETICA_NEUE, 11, index=0)
    font_status = load_font(HELVETICA_NEUE, 11, index=0)
    draw.text((card_x + 18, card_y + 30), "Personal", fill=(250, 250, 252), font=font_active_title)
    draw.text((card_x + 18, card_y + 54), "@umarsiddiqui", fill=(168, 172, 182), font=font_mono)
    draw.text((card_x + 18, card_y + 74), "✓  Matches this Mac", fill=(168, 172, 182), font=font_status)

    av_x = card_x + card_w - 52
    av_y = card_y + 22
    draw.ellipse([av_x - 2, av_y - 2, av_x + 46, av_y + 46], outline=BRAND, width=2)
    create_avatar(draw, av_x, av_y, 40, "US", hex_to_rgb("#3182CE"))

    sec_y = card_y + card_h + 14
    font_sec = load_font(HELVETICA_NEUE, 10, index=1)
    draw.text((pop_x + 14, sec_y), "IDENTITIES", fill=(125, 130, 142), font=font_sec)

    font_row_title = load_font(HELVETICA_NEUE, 13, index=1)
    font_row_sub = load_font(HELVETICA_NEUE, 10, index=0)
    row_y = sec_y + 22

    def profile_row(rx, ry, initials, color, title, user_part, git_part, active):
        create_avatar(draw, rx, ry, 34, initials, color)
        draw.text((rx + 44, ry + 2), title, fill=(245, 245, 247), font=font_row_title)
        draw.text((rx + 44, ry + 22), user_part, fill=(152, 156, 165), font=font_row_sub)
        draw.text((rx + 120, ry + 22), git_part, fill=(110, 115, 128), font=font_row_sub)
        cx = pop_x + pop_w - 28
        cy = ry + 17
        if active:
            draw_active_radio(draw, cx, cy)
        else:
            draw.text((cx - 5, ry + 10), "›", fill=(95, 98, 108), font=load_font(HELVETICA_NEUE, 14, index=1))

    profile_row(
        pop_x + 12,
        row_y,
        "US",
        hex_to_rgb("#3182CE"),
        "Personal",
        "@umarsiddiqui",
        "Umar Siddiqui",
        True,
    )
    profile_row(
        pop_x + 12,
        row_y + 48,
        "UA",
        hex_to_rgb("#DD6B20"),
        "Work",
        "@umar-abweb",
        "Umar ABWeb",
        False,
    )

    div_y = row_y + 48 + 44
    draw.line([(pop_x + 12, div_y), (pop_x + pop_w - 12, div_y)], fill=(68, 70, 76), width=1)

    font_foot = load_font(HELVETICA_NEUE, 13, index=0)
    font_short = load_font(HELVETICA_NEUE, 11, index=0)
    fy = div_y + 10
    draw.text((pop_x + 28, fy), "⚙", fill=BRAND, font=load_font(HELVETICA_NEUE, 13, index=0))
    draw.text((pop_x + 48, fy), "Settings…", fill=(235, 236, 240), font=font_foot)
    sc = "⌘,"
    bbox = draw.textbbox((0, 0), sc, font=font_short)
    draw.text((pop_x + pop_w - 14 - (bbox[2] - bbox[0]), fy + 1), sc, fill=(120, 124, 132), font=font_short)

    fy2 = fy + 36
    draw.text((pop_x + 28, fy2), "⏻", fill=(152, 156, 165), font=load_font(HELVETICA_NEUE, 12, index=0))
    draw.text((pop_x + 48, fy2), "Quit GitSwitch", fill=(152, 156, 165), font=font_foot)

    img.save(os.path.join(ASSETS_DIR, "screenshot-menubar.png"), "PNG")
    print("✓ screenshot-menubar.png created")

# =============================================================================
# 3. SCREENSHOT-SETTINGS  (WindowGroup settings — ContentView / ProfileCardView)
# =============================================================================
def generate_screenshot_settings():
    W, H = 900, 620
    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img)

    draw_gradient_bg(img, hex_to_rgb("#1A202C"), hex_to_rgb("#2D3748"))

    win_x, win_y = 120, 48
    win_w, win_h = 660, 524

    shadow = Image.new("RGBA", (win_w + 48, win_h + 48), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    rounded_rectangle(sdraw, [12, 12, win_w + 36, win_h + 36], 20, (0, 0, 0, 130))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    img.paste(shadow, (win_x - 24, win_y - 24), shadow)

    bg_top = (34, 34, 38)
    rounded_rectangle(draw, [win_x, win_y, win_x + win_w, win_y + win_h], 14, bg_top)
    rounded_rectangle(draw, [win_x, win_y, win_x + win_w, win_y + win_h], 14, outline=(70, 73, 82), width=1)

    inner_grad_top = Image.new("RGBA", (win_w, win_h), (0, 0, 0, 0))
    ig = ImageDraw.Draw(inner_grad_top)
    indigo_a = (BRAND[0], BRAND[1], BRAND[2], 38)
    for row in range(140):
        a = int(38 * (1 - row / 140))
        ig.line([(0, row), (win_w, row)], fill=(BRAND[0], BRAND[1], BRAND[2], min(a, 38)))
    img.paste(inner_grad_top, (win_x, win_y), inner_grad_top)

    hx = win_x + 28
    hy = win_y + 28
    draw_brand_tile(draw, hx, hy, 36)
    font_head = load_font(HELVETICA_NEUE, 22, index=1)
    font_sub = load_font(HELVETICA_NEUE, 12, index=0)
    draw.text((hx + 46, hy + 2), "Settings", fill=(245, 246, 248), font=font_head)
    draw.text((hx + 46, hy + 32), "GitSwitch · profiles on this Mac", fill=(152, 156, 165), font=font_sub)

    font_sec = load_font(HELVETICA_NEUE, 10, index=1)
    sy = hy + 72
    draw.text((hx, sy), "PROFILES", fill=(125, 130, 142), font=font_sec)

    def draw_profile_card(cx, cy, cw, ch, active, name, git_line, gh_user, ssh_path):
        mat = (42, 44, 50)
        rounded_rectangle(draw, [cx, cy, cx + cw, cy + ch], 12, mat)
        stroke = BRAND if active else (95, 98, 108)
        lw = 2 if active else 1
        rounded_rectangle(draw, [cx, cy, cx + cw, cy + ch], 12, outline=stroke, width=lw)
        if active:
            draw.rectangle([cx + 4, cy + 14, cx + 8, cy + ch - 14], fill=BRAND)

        av = 56
        ax, ay = cx + 18, cy + 18
        draw.ellipse([ax - 2, ay - 2, ax + av + 2, ay + av + 2], outline=BRAND if active else (120, 124, 132), width=2)
        initials = name[:2].upper()
        create_avatar(draw, ax, ay, av, initials, hex_to_rgb("#3182CE") if name == "Personal" else hex_to_rgb("#DD6B20"))

        font_name = load_font(HELVETICA_NEUE, 16, index=1)
        font_git = load_font(HELVETICA_NEUE, 12, index=0)
        font_link = load_font(HELVETICA_NEUE, 12, index=0)
        font_ssh = load_font(HELVETICA_NEUE, 11, index=0)
        tx = ax + av + 18
        draw.text((tx, cy + 18), name, fill=(248, 248, 250), font=font_name)
        draw.text((tx, cy + 42), git_line, fill=(168, 172, 182), font=font_git)
        draw.text((tx, cy + 62), f"@{gh_user}", fill=BRAND, font=font_link)
        draw.text((tx, cy + 82), ssh_path, fill=(110, 115, 128), font=font_ssh)

        rcx = cx + cw - 36
        rcy = cy + ch // 2
        if active:
            draw_active_radio(draw, rcx, rcy, outer=11)

    card_w = win_w - 56
    card_y = sy + 26
    card_h = 134
    draw_profile_card(
        hx,
        card_y,
        card_w,
        card_h,
        True,
        "Personal",
        "Umar Siddiqui <umar@example.com>",
        "umarsiddiqui",
        "~/.ssh/id_rsa_personal",
    )
    draw_profile_card(
        hx,
        card_y + card_h + 14,
        card_w,
        card_h,
        False,
        "Work",
        "Umar ABWeb <umar@abweb.dev>",
        "umar-abweb",
        "~/.ssh/id_rsa_work",
    )

    btn_y = win_y + win_h - 62
    fw = 120
    fh = 38
    bx1 = win_x + win_w // 2 - fw - 8
    bx2 = win_x + win_w // 2 + 8
    rounded_rectangle(draw, [bx1, btn_y, bx1 + fw, btn_y + fh], 10, (58, 60, 68))
    rounded_rectangle(draw, [bx1, btn_y, bx1 + fw, btn_y + fh], 10, outline=(95, 98, 108), width=1)
    rounded_rectangle(draw, [bx2, btn_y, bx2 + fw, btn_y + fh], 10, BRAND)
    font_btn = load_font(HELVETICA_NEUE, 13, index=1)
    bbox = draw.textbbox((0, 0), "Scan", font=font_btn)
    tw = bbox[2] - bbox[0]
    draw.text((bx1 + fw // 2 - tw // 2, btn_y + 10), "Scan", fill=(235, 236, 240), font=font_btn)
    bbox = draw.textbbox((0, 0), "Add profile", font=font_btn)
    tw = bbox[2] - bbox[0]
    draw.text((bx2 + fw // 2 - tw // 2, btn_y + 10), "Add profile", fill=(255, 255, 255), font=font_btn)

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
