"""Copy images into frontend/assets/images structure."""
import json
import os
import shutil

SRC = r"x:\roozbeh\images"
DEST = r"x:\roozbeh\frontend\assets\images"

CAR_FILES = {"206.png", "206sd.png", "405.png"}
EQUIPMENT_FILES = {
    "2-fan-turbo-2.jpg",
    "brake-pad.jpg",
    "clutch-kit.jpg",
    "Engine-spark-plug-wire.jpg",
    "kds-.jpg",
    "spark-plug.jpg",
    "Time-belt-frame.jpg",
    "Timing-belt-bearing.jpg",
    "Timing-belt.jpg",
    "wheel-disc.jpg",
}

# Persian filenames (cars + slideshow)
CAR_PERSIAN = {"پارس.png", "سمند.png", "سورن.png"}
SLIDESHOW_KEYWORDS = ("اسنپ", "قطعات مصرفی", "انواع")


def is_slideshow(name: str) -> bool:
    return any(k in name for k in SLIDESHOW_KEYWORDS)


def safe_name(name: str) -> str:
    """ASCII-safe copy name while preserving extension."""
    base, ext = os.path.splitext(name)
    if name in CAR_FILES or name in EQUIPMENT_FILES or name in CAR_PERSIAN:
        return name
    if is_slideshow(name):
        idx = hash(name) % 10000
        return f"slide-{idx}{ext}"
    if name.endswith(".png") and name not in CAR_FILES:
        return name  # keep persian png car names
    return name


def main():
    folders = ["cars", "equipments", "slideshow", "about us"]
    for folder in folders:
        os.makedirs(os.path.join(DEST, folder), exist_ok=True)

    manifest = {"cars": [], "equipments": [], "slideshow": [], "about_us": []}

    for root, _, files in os.walk(SRC):
        rel_root = os.path.relpath(root, SRC)
        for fname in files:
            src_path = os.path.join(root, fname)
            if rel_root == "about us" or fname.startswith("."):
                dest_name = fname
                dest_folder = "about us"
            elif fname in CAR_FILES or fname in CAR_PERSIAN:
                dest_folder = "cars"
                dest_name = fname
            elif fname in EQUIPMENT_FILES:
                dest_folder = "equipments"
                dest_name = fname
            elif fname.endswith(".jpg") and is_slideshow(fname):
                dest_folder = "slideshow"
                dest_name = safe_name(fname)
            elif fname.endswith(".png") and rel_root == ".":
                dest_folder = "cars"
                dest_name = fname
            elif fname.endswith(".jpg"):
                dest_folder = "equipments"
                dest_name = fname
            else:
                continue

            dest_path = os.path.join(DEST, dest_folder, dest_name)
            shutil.copy2(src_path, dest_path)
            key = "about_us" if dest_folder == "about us" else dest_folder
            asset_path = f"assets/images/{dest_folder}/{dest_name}"
            manifest[key].append({"file": dest_name, "asset": asset_path})

    manifest_path = os.path.join(DEST, "manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    print(json.dumps({k: len(v) for k, v in manifest.items()}))


if __name__ == "__main__":
    main()
