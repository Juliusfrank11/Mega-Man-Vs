# Script by sysharm, taken from https://godotengine.org/qa/25504/pixel-perfect-scaling?show=26997#a26997
# Originally by chanon from https://github.com/godotengine/godot/issues/6506#issuecomment-373106160
# Black bars to prevent flickering from https://gist.github.com/atomius0/42b5605e9f4e5b171076cd0c4453d4bb
# Modified to be used for more than just pixel-perfect scaling.

extends Node

# Set project settings stretch mode to '2d' and stretch aspect to 'ignore'.

var fullscreen: bool = false setget set_fullscreen
var allow_half_int: bool = true

onready var _viewport: Viewport = get_viewport()
onready var _base_width: int = Global.base_size.x
onready var _base_height: int = Global.base_size.y
onready var _base_size := Vector2(_base_width, _base_height)

func _ready() -> void:
    get_tree().connect("screen_resized", self, "on_screen_resized")
    if not OS.is_debug_build():
        VisualServer.set_default_clear_color(Color("000000"))
        set_fullscreen(true)
    
    on_screen_resized()

func set_fullscreen(value: bool) -> void:
    if not fullscreen and value:
        fullscreen = value
        OS.window_fullscreen = true
    elif fullscreen and not value:
        fullscreen = value
        OS.window_fullscreen = false

func on_screen_resized() -> void:
    var window_size: Vector2 = OS.get_window_size()

    # See how big the window is compared to the viewport size.
    # Floor it, so we only get round numbers (0, 1, 2, 3 ...).
    var scale_x: float = floor(window_size.x / _base_width)
    var scale_y: float = floor(window_size.y / _base_height)

    if allow_half_int:
        # Recalculate scaling factors allowing half-integers.
        # Enables a fullscreen image on 1080p screens (4.5 * 240 vertical resolution).
        scale_x = round(window_size.x / _base_width * 2) / 2
        scale_y = round(window_size.y / _base_height * 2) / 2
    
    # Use the smaller scale with 1x minimum scale.
    var scale: float = max(1, min(scale_x, scale_y))
    Global.scale_factor = scale

    # Find the coordinate we will use to center the viewport inside the window.
    var diff: Vector2 = window_size - (_base_size * scale)
    var diffhalf: Vector2 = (diff * 0.5).floor()

    # Change the size of the viewport.
    _viewport.set_size(_base_size * scale)

    # Attach the viewport to the rect we calculated.
    _viewport.set_attach_to_screen_rect(Rect2(diffhalf, _base_size * scale))

    # Set up black bars to prevent flickering.
    var odd_offset = Vector2(int(window_size.x) % 2, int(window_size.y) % 2)

    # Prevent negative values with max(), they make the black bars go in the wrong direction.
    VisualServer.black_bars_set_margins(
            max(diffhalf.x, 0),
            max(diffhalf.y, 0),
            max(diffhalf.x, 0) + odd_offset.x,
            max(diffhalf.y, 0) + odd_offset.y
    )
