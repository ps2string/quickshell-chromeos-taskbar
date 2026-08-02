#!/usr/bin/env python3
import gi
import subprocess
import os
import json
import glob
import threading

# Require GTK4, Libadwaita, and GdkPixbuf bindings
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
gi.require_version('Gdk', '4.0')
gi.require_version('GdkPixbuf', '2.0')

from gi.repository import Gtk, Adw, Gdk, Gio, GLib, GdkPixbuf

try:
    from PIL import Image
except ImportError:
    print("Please install python-pillow: sudo pacman -S python-pillow")
    exit(1)

class WallpaperManager(Adw.ApplicationWindow):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.set_title("Matugen Theme Manager")
        self.set_default_size(760, 580)

        self.images = []
        self.carousel_pages = []
        self.css_monitors = []
        self.debounce_id = None
        self.is_loading = True  
        self.cache_file = os.path.expanduser("~/.cache/matugen-theme-manager.txt")
        
        self.image_queue = []
        self.cancel_loading = False
        self.current_worker_thread = None

        self.apply_custom_styles()
        self.reload_app_theme()
        self.setup_css_file_watchers()

        key_controller = Gtk.EventControllerKey.new()
        key_controller.connect("key-pressed", self.on_key_pressed)
        self.add_controller(key_controller)

        # Main Layout using Adw.Clamp for responsive, centered design
        self.clamp = Adw.Clamp()
        self.clamp.set_maximum_size(800)
        self.clamp.set_tightening_threshold(600)
        self.set_content(self.clamp)

        self.box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)
        self.box.set_margin_top(32)
        self.box.set_margin_bottom(32)
        self.box.set_margin_start(24)
        self.box.set_margin_end(24)
        self.clamp.set_child(self.box)

        # Header Title
        self.label = Gtk.Label(label="Select Wallpaper")
        self.label.set_css_classes(["m3-header"])
        self.label.set_halign(Gtk.Align.START)
        self.box.append(self.label)

        # Animated Carousel
        self.carousel = Adw.Carousel()
        self.carousel.set_interactive(True)
        self.carousel.set_spacing(20)
        self.carousel.set_vexpand(True)
        self.carousel.connect("page-changed", self.on_carousel_page_changed)
        self.box.append(self.carousel)

        self.dots = Adw.CarouselIndicatorDots()
        self.dots.set_carousel(self.carousel)
        self.box.append(self.dots)

        # M3 Container Card
        m3_container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        m3_container.set_css_classes(["m3-container"])
        self.box.append(m3_container)

        # Filename Label
        self.filename_label = Gtk.Label(label="No image selected")
        self.filename_label.set_css_classes(["m3-dim-label"])
        self.filename_label.set_wrap(True)
        m3_container.append(self.filename_label)

        # Action Button
        self.btn_select = Gtk.Button(label="Open Folder")
        self.btn_select.set_css_classes(["m3-button"]) # Removed suggested-action
        self.btn_select.set_halign(Gtk.Align.CENTER)
        self.btn_select.connect("clicked", self.on_select_clicked)
        m3_container.append(self.btn_select)

        # Status Box (Spinner + Label)
        status_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        status_box.set_halign(Gtk.Align.CENTER)
        
        self.spinner = Gtk.Spinner()
        status_box.append(self.spinner)
        
        self.status_label = Gtk.Label(label="")
        self.status_label.set_wrap(True)
        self.status_label.set_css_classes(["m3-status"])
        status_box.append(self.status_label)
        
        m3_container.append(status_box)

        self.load_cache()

    def apply_custom_styles(self):
        provider = Gtk.CssProvider()
        css = """
        * {
            font-family: sans-serif;
            transition: all 400ms cubic-bezier(0.2, 0, 0, 1);
        }
        
        .m3-header {
            font-size: 26pt;
            font-weight: 900;
            letter-spacing: -0.8px;
        }

        .m3-container {
            background-color: alpha(@window_fg_color, 0.05);
            border-radius: 32px;
            padding: 28px;
        }

        /* Fixed Button Colors */
        button.m3-button {
            border-radius: 9999px;
            padding: 14px 40px;
            font-weight: 800;
            font-size: 13pt;
            background-color: @accent_bg_color;
            color: @accent_fg_color;
            box-shadow: 0 6px 16px alpha(@accent_bg_color, 0.25);
            border: none;
        }

        button.m3-button:hover {
            opacity: 0.85;
            box-shadow: 0 8px 20px alpha(@accent_bg_color, 0.35);
        }

        /* Image styling with fade-in prep */
        picture {
            border-radius: 36px;
            box-shadow: 0 12px 32px rgba(0,0,0,0.3);
            opacity: 0; 
        }
        
        picture.loaded {
            opacity: 1;
        }
        
        .m3-dim-label {
            font-weight: 700;
            font-size: 12pt;
            color: alpha(@window_fg_color, 0.6);
        }

        .m3-status {
            font-size: 11pt;
            font-weight: 600;
            color: @accent_bg_color;
        }
        """
        provider.load_from_data(css.encode())
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def setup_css_file_watchers(self):
        paths = [
            os.path.expanduser("~/.config/gtk-4.0/colors.css"),
            os.path.expanduser("~/.config/gtk-4.0/gtk.css")
        ]
        for path in paths:
            if os.path.exists(path):
                gfile = Gio.File.new_for_path(path)
                monitor = gfile.monitor_file(Gio.FileMonitorFlags.NONE, None)
                monitor.connect("changed", self.on_css_file_changed)
                self.css_monitors.append(monitor)

    def on_css_file_changed(self, monitor, file, other_file, event_type):
        if event_type in (Gio.FileMonitorEvent.CHANGES_DONE_HINT, Gio.FileMonitorEvent.CREATED):
            GLib.idle_add(self.reload_app_theme)

    def reload_app_theme(self):
        gtk_css = os.path.expanduser("~/.config/gtk-4.0/gtk.css")
        colors_css = os.path.expanduser("~/.config/gtk-4.0/colors.css")
        target_css = colors_css if os.path.exists(colors_css) else gtk_css
        
        if os.path.exists(target_css):
            if not hasattr(self, 'live_theme_provider'):
                self.live_theme_provider = Gtk.CssProvider()
                Gtk.StyleContext.add_provider_for_display(
                    Gdk.Display.get_default(), 
                    self.live_theme_provider, 
                    Gtk.STYLE_PROVIDER_PRIORITY_USER 
                )
            try:
                with open(target_css, 'r') as f:
                    css_data = f.read()
                self.live_theme_provider.load_from_data(css_data.encode('utf-8'))
            except Exception as e:
                print(f"Failed to live-reload CSS: {e}")

    def load_cache(self):
        if os.path.exists(self.cache_file):
            try:
                with open(self.cache_file, "r") as f:
                    last_path = f.read().strip()
                if os.path.exists(last_path):
                    self.load_directory_images(last_path)
            except Exception:
                pass

    def save_cache(self, path):
        try:
            with open(self.cache_file, "w") as f:
                f.write(path)
        except Exception:
            pass

    def on_key_pressed(self, controller, keyval, keycode, state):
        if not self.images:
            return False
        current_idx = int(self.carousel.get_position())
        if keyval == Gdk.KEY_Right and current_idx < len(self.images) - 1:
            self.carousel.scroll_to(self.carousel_pages[current_idx + 1], True)
            return True
        elif keyval == Gdk.KEY_Left and current_idx > 0:
            self.carousel.scroll_to(self.carousel_pages[current_idx - 1], True)
            return True
        return False

    def on_select_clicked(self, widget):
        dialog = Gtk.FileDialog(title="Select a Wallpaper")
        filters = Gio.ListStore.new(Gtk.FileFilter)
        filter_img = Gtk.FileFilter()
        filter_img.set_name("Images")
        for mime in ["image/png", "image/jpeg", "image/webp"]:
            filter_img.add_mime_type(mime)
        filters.append(filter_img)
        dialog.set_filters(filters)
        dialog.open(self, None, self.on_file_selected)

    def on_file_selected(self, dialog, result):
        try:
            file = dialog.open_finish(result)
            if file is not None:
                self.load_directory_images(file.get_path())
        except GLib.Error:
            pass

    def load_directory_images(self, target_path):
        self.is_loading = True  
        self.cancel_loading = True  
        
        directory = os.path.dirname(target_path)
        exts = ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        self.images = []
        for ext in exts:
            self.images.extend(glob.glob(os.path.join(directory, ext)))
            self.images.extend(glob.glob(os.path.join(directory, ext.upper())))
        
        self.images = sorted(list(set(self.images)))

        for page in self.carousel_pages:
            self.carousel.remove(page)
        self.carousel_pages.clear()
        self.image_queue.clear()

        for img_path in self.images:
            pic = Gtk.Picture()
            pic.set_size_request(420, 236)
            pic.set_content_fit(Gtk.ContentFit.COVER)
            self.carousel.append(pic)
            self.carousel_pages.append(pic)
            self.image_queue.append((img_path, 420, 236, pic))

        try:
            initial_idx = self.images.index(target_path)
            self.carousel.scroll_to(self.carousel_pages[initial_idx], False)
            self.filename_label.set_text(os.path.basename(target_path))
        except ValueError:
            pass

        self.cancel_loading = False
        threading.Thread(target=self._process_image_queue, daemon=True).start()
        GLib.idle_add(self._enable_page_changed_events)

    def _enable_page_changed_events(self):
        self.is_loading = False
        return False

    def _process_image_queue(self):
        for img_path, width, height, picture_widget in self.image_queue:
            if self.cancel_loading:
                break
            try:
                pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(img_path, width, height, True)
                texture = Gdk.Texture.new_for_pixbuf(pixbuf)
                GLib.idle_add(self._apply_texture_with_fade, picture_widget, texture)
            except Exception:
                pass

    def _apply_texture_with_fade(self, widget, texture):
        widget.set_paintable(texture)
        widget.add_css_class("loaded") # Triggers CSS opacity transition

    def on_carousel_page_changed(self, carousel, index):
        if self.is_loading or not self.images or index >= len(self.images):
            return

        path_center = self.images[index]
        self.filename_label.set_text(os.path.basename(path_center))
        self.save_cache(path_center)

        self.status_label.set_text("Waiting...")
        if self.debounce_id is not None:
            GLib.source_remove(self.debounce_id)
        self.debounce_id = GLib.timeout_add(500, self.trigger_background_worker, path_center)

    def trigger_background_worker(self, image_path):
        self.debounce_id = None
        self.spinner.start()
        self.status_label.set_text(f"Applying {os.path.basename(image_path)}...")
        
        if self.current_worker_thread and self.current_worker_thread.is_alive():
            pass # Prevent overlapping apply threads
            
        self.current_worker_thread = threading.Thread(target=self.background_theme_worker, args=(image_path,), daemon=True)
        self.current_worker_thread.start()
        return False

    def get_dominant_color(self, image_path):
        try:
            img = Image.open(image_path).convert("RGBA")
            bg = Image.new("RGBA", img.size, (255, 255, 255))
            img = Image.alpha_composite(bg, img).convert("RGB")
            
            # Crop slightly to avoid black letterbox borders skewing the color
            width, height = img.size
            crop_margin = int(min(width, height) * 0.1)
            img = img.crop((crop_margin, crop_margin, width - crop_margin, height - crop_margin))
            
            img.thumbnail((32, 32)) 
            paletted = img.convert('P', palette=Image.ADAPTIVE, colors=1)
            palette = paletted.getpalette()
            color_counts = sorted(paletted.getcolors(), reverse=True)
            
            _, index = color_counts[0]
            r, g, b = palette[index*3 : index*3+3]
            return f"#{r:02x}{g:02x}{b:02x}"
        except Exception:
            return "#9a8b7f"

    def background_theme_worker(self, image_path):
        try:
            hex_color = self.get_dominant_color(image_path)

            config_path = os.path.expanduser("~/.config/hypr/hyprpaper.conf")
            sed_command = f"s|^[[:space:]]*path = .*|    path = {image_path}|g"
            subprocess.run(["sed", "-i", sed_command, config_path], check=False)

            try:
                output = subprocess.check_output(["hyprctl", "monitors", "-j"], text=True)
                monitors = json.loads(output)
                for mon in monitors:
                    mon_name = mon.get("name")
                    if mon_name:
                        subprocess.run(["hyprctl", "hyprpaper", "wallpaper", f"{mon_name}, {image_path}"], check=False)
            except FileNotFoundError:
                pass # Fail silently if hyprland/hyprpaper isn't running

            subprocess.run(["matugen", "color", "hex", hex_color], check=True)

            sddm_bg_path = os.path.expanduser("~/chromeos-lock/background.jpg")
            if os.path.exists(os.path.dirname(sddm_bg_path)):
                subprocess.run(["sudo", "cp", image_path, sddm_bg_path], check=False)
                subprocess.run(["sudo", "chmod", "a+r", sddm_bg_path], check=False)

            GLib.idle_add(self.update_status_success, hex_color)
        except Exception as e:
            GLib.idle_add(self.update_status_error, str(e))

    def update_status_success(self, hex_color):
        self.spinner.stop()
        self.status_label.set_text(f"Success! Theme applied: {hex_color}")
        self.reload_app_theme()

    def update_status_error(self, error_msg):
        self.spinner.stop()
        self.status_label.set_text(f"Error: {error_msg}")


class ThemeApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id="com.github.matugen_wallpaper")

    def do_activate(self):
        win = WallpaperManager(application=self)
        win.present()

if __name__ == '__main__':
    import sys
    if len(sys.argv) >= 3 and sys.argv[1] == "--apply":
        target_path = sys.argv[2]
        if os.path.exists(target_path):
            wm = WallpaperManager()
            wm.background_theme_worker(target_path)
            print(f"Applied wallpaper & generated theme: {target_path}")
            sys.exit(0)

    app = ThemeApp()
    app.run(None)
