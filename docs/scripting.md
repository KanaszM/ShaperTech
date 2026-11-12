# Scripting

[Documentation home](../README.md)

ShaperTech classes register through `class_name`; no autoload is required.
Use the same node/data/material properties from GDScript as from the inspector.

## Build an existing subtree

Attach this script to a `Node` with an `STContainer` child named `Shapers`.
Set that container's `build_on_ready` to `false` in the inspector if this script
should be the only startup build:

```gdscript
extends Node

@onready var shapers: STContainer = $Shapers

func _ready() -> void:
	shapers.build()
```

Always add authoring nodes to the scene tree before calling `build()`. Origin,
ancestor offsets, editor ownership, and startup behavior depend on tree context.

## Create a platform at runtime

Attach this example to an otherwise empty `Node3D` scene. Add a camera and light
separately. The output destination has an identity transform so placement is easy
to reason about.

```gdscript
extends Node3D

func _ready() -> void:
	var geometry_root: Node3D = Node3D.new()
	geometry_root.name = "Geometry"
	add_child(geometry_root)

	var container: STContainer = STContainer.new()
	container.name = "Shapers"
	container.build_on_ready = false
	container.height_offset = 1.0
	add_child(container)

	var platform: STPolygon = STPolygon.new()
	platform.name = "Platform"
	platform.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(128, 0),
		Vector2(128, 64), Vector2(0, 64),
	])
	platform.data = STPolygonData.new()
	platform.data.geometry_height = 2.0
	platform.data.collision_enabled = true
	platform.materials = STPolygonMaterials.new()
	platform.materials.top_reverse_faces_mode = ShaperTech.MaterialReverseFacesMode.AUTOMATIC
	platform.materials.bottom_reverse_faces_mode = ShaperTech.MaterialReverseFacesMode.AUTOMATIC
	platform.materials.sides_reverse_faces_mode = ShaperTech.MaterialReverseFacesMode.AUTOMATIC
	platform.parent_custom_node = geometry_root
	platform.parent_sync_position = false
	container.add_child(platform)

	container.build()
```

The resulting footprint is 4 by 2 units, with a bottom at Y `1` and top at Y `3`.
The shaper's own startup build is suppressed by the container. Mesh-node addition
is deferred by default; the actual vertices are calculated during `build()`.

## Configure a ramp

This is a method you can add to a scene script. Pass an in-tree parent:

```gdscript
func add_corner_ramp(authoring_parent: Node, output_parent: Node3D) -> STSlope:
	var ramp: STSlope = STSlope.new()
	ramp.points = PackedVector2Array([Vector2(0, 0), Vector2(128, 0)])
	ramp.data = STSlopeData.new()
	ramp.data.geometry_width = 2.0
	ramp.data.geometry_height = 2.0
	ramp.data.geometry_corner_left = 0.75
	ramp.data.geometry_corner_right = 0.0
	ramp.data.geometry_curve_value = 0.5
	ramp.data.geometry_curve_segments = 16
	ramp.materials = STSlopeMaterials.new()
	ramp.materials.back_enabled = true
	ramp.materials.bottom_enabled = true
	ramp.parent_custom_node = output_parent
	ramp.parent_sync_position = false
	authoring_parent.add_child(ramp)
	ramp.build()
	return ramp
```

## Change values and rebuild

Data/material resources can be shared between nodes. Mutating a shared resource
changes what every referencing shaper will read on its next build. For an
independent edit, make the resource unique in the inspector or duplicate it:

```gdscript
func raise_platform(platform: STPolygon, new_height: float) -> void:
	platform.data = platform.data.duplicate() as STPolygonData
	platform.data.geometry_height = new_height
	platform.build()
```

This example assumes `data` has already been initialized. For a newly constructed
node, assign a new data resource first. Duplicating the outer resource does not
necessarily duplicate every nested material/texture; choose deep duplication
deliberately if those must be independent too.

Node-owned Build/Nodes/Parent settings remain independent even when resources
are shared. To turn on automatic rebuilding, set the mode and build once:

```gdscript
func enable_editor_updates(platform: STPolygon) -> void:
	platform.build_mode = ShaperTech.BuildMode.AUTOMATIC_EDITOR_ONLY
	platform.build_automatic_interval = 0.5
	platform.build()
```

The editor-only mode will not keep a timer at runtime.

## Read generated output

There is no public mesh getter. When necessary, inspect the output parent after
deferred additions have completed and match the mesh's `shaper` reference:

```gdscript
func find_platform_mesh(platform: STPolygon) -> STMesh:
	await get_tree().process_frame
	var output_parent: Node = platform.parent_custom_node

	if output_parent == null:
		output_parent = platform

	for child: Node in output_parent.get_children():
		if child is STMesh and (child as STMesh).shaper == platform:
			return child as STMesh

	return null
```

This method belongs on an in-tree `Node` script. Call it with `await`.
Waiting a frame allows ordinary deferred additions to complete; alternatively
set `build_nodes_deferred = false` before the initial build when immediate
tree access is required and safe in your caller's context.

## Public shaper API

| Class | Method | Coordinate/result contract |
| --- | --- | --- |
| All four shapers | `build() -> void` | Recreates current output; does not return a mesh |
| `STContainer` | `build() -> void` | Builds its descendants recursively |
| `STPolygon`, `STFloor` | `get_random_point() -> Vector2` | Local drawn point, sampled by polygon area; zero if unusable |
| `STSlope` | `get_polygon_points() -> PackedVector2Array` | Last-built local rectangular footprint, four points |
| `STSlope` | `get_polygon_border() -> PackedVector2Array` | Same footprint, closed with a fifth point |
| `STWall` | `get_calculated_points() -> PackedVector2Array` | Last-built rotated/offset points before scale division |
| All data classes | `get_top_position() -> float` | Distance plus nominal height, or distance alone for Floor |

The top-position getters exclude container offsets, geometry Y offset, output
transforms, wall skew, and curve overshoot. They are not world-height queries.

To convert a Polygon/Floor random point to the unskewed horizontal mesh space,
use the same origin calculation as the builder, then geometry rotation/offset
and scale division. Finally use the actual mesh transform for world placement.
Do not pass the raw point directly as a world X/Z position. See
[Coordinates and building](coordinates-and-building.md) for the formula.

## Materials resource getters

Each material resource supplies `get_<group>_material()`,
`get_<group>_reverse_faces_mode()`, `get_<group>_rotation()`,
`get_<group>_tile_horizontal()`, `get_<group>_tile_vertical()`, and
`get_<group>_texture_direction()` for its surface groups.
These getters resolve overrides; the material getter can return null.

## Global enums and defaults

Enums live on `ShaperTech`:

| Enum | Values, in declaration order |
| --- | --- |
| `BuildOnReadyType` | `DISABLED`, `EDITOR_ONLY`, `ALWAYS` |
| `BuildMode` | `MANUAL`, `AUTOMATIC_EDITOR_ONLY`, `AUTOMATIC_ALWAYS` |
| `PresetType` | `NONE`, `CIRCLE`, `RECTANGLE`, `TORUS` |
| `MaterialType` | `SOLID`, `TRANSPARENT`, `DISABLED` |
| `MaterialReverseFacesMode` | `DISABLED`, `ENABLED`, `AUTOMATIC` |

Common constants are `DEFAULT_GEOMETRY_SCALE = 32.0`,
`DEFAULT_BUILD_AUTOMATIC_INTERVAL = 0.5`, and collision layer/mask defaults of `1`.
Use enum names rather than saving assumptions about integer positions in scripts.
