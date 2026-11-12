# STPolygon

[Documentation home](../README.md)

`STPolygon` extends `Polygon2D`. Its `polygon` points define a closed footprint;
the builder triangulates the top and bottom and connects adjacent outline points
with side faces. Use it for platforms, blocks, and extruded level outlines.

## Inputs and resources

Use at least three points forming a valid triangulatable polygon. Concave simple
outlines can be triangulated; self-intersections and degenerate outlines should
be avoided. Closure is implicit: you do not need to repeat the first point.
There is no general multiple-contour/hole editor in this class.

| Resource | Purpose |
| --- | --- |
| `STPolygonData` | Geometry and collision |
| `STPolygonMaterials` | Top, Bottom, Sides, and per-group overrides |

Missing resources are created during initialization/building.
Build and output-parent settings belong to the node; see
[Coordinates and building](coordinates-and-building.md).

## Height and skew

`geometry_height` defaults to **0.0**. Set it above zero for an extrusion.
The bottom vertices are at local Y `0`; the top vertices are at local Y
`geometry_height`. The mesh's vertical placement is added afterward.

| Property in Data | Effect |
| --- | --- |
| `geometry_skew_top_x` | Shifts the entire top footprint along 3D X |
| `geometry_skew_top_y` | Shifts the entire top footprint along 3D Z |
| `geometry_skew_bottom_x` | Shifts the entire bottom footprint along 3D X |
| `geometry_skew_bottom_y` | Shifts the entire bottom footprint along 3D Z |

All skew defaults to `0.0` and is in 3D units, after drawing-scale conversion.
The `_y` suffix on polygon skew refers to the footprint's second axis, **3D Z**,
not vertical height. Different top and bottom shifts create leaning sides.

## Surface selection

Top, Bottom, and Sides independently select material type, winding, UV tiling,
texture direction, and rotation. Set a group's type to `DISABLED` to omit it.
Use automatic reverse-face handling when you need the builder to account for
polygon winding. Material overrides apply an entire set of surface settings to
selected groups, not just a replacement material.

See [Materials and UVs](materials-and-uvs.md) for the exact rules.

## Polygon tools

The same tools are available on [STFloor](floor.md):

| Button | Inputs | Result |
| --- | --- | --- |
| Expand | `tool_offset_delta`, `tool_offset_join_type` | Offsets outward by the absolute delta |
| Shrink | Same | Offsets inward by the absolute delta |
| Horizontally | None | Mirrors local X about the outline's bounding-box center |
| Vertically | None | Mirrors local Y about the outline's bounding-box center |

Offset distance is in drawing units. Join type is a Godot
`Geometry2D.PolyJoinType`, defaulting to `JOIN_SQUARE`. If offsetting produces
multiple polygons, only the first result is retained; an empty result clears
the polygon. Review the outline after shrinking a narrow or concave shape.

These tools modify `polygon`, not the generated mesh directly. Rebuild afterward
or let an active automatic timer do so. The buttons do not create explicit
editor undo/redo actions.

## Presets

Set `preset_type` (`ShaperTech.PresetType`), fill in its settings, then press
**Apply**. The resulting points replace the outline if there are at least three.
Preset dimensions and `preset_center_point` are in drawing units.

| Preset | Properties | Requirements and behavior |
| --- | --- | --- |
| `NONE` | None | Leaves the current outline unchanged |
| `CIRCLE` | `preset_circle_radius`, `preset_circle_angle_from`, `preset_circle_angle_to`, `preset_circle_detail` | Positive radius, detail at least 3; angles are radians, with `TAU` as default end; starts at the upward direction when the start angle is 0 |
| `RECTANGLE` | `preset_rectangle_size`, `preset_rectangle_corner_radius`, `preset_rectangle_corner_segments` | Both size components positive; radius is clamped to half the smaller size; positive radius enables rounded corners |
| `TORUS` | `preset_torus_radius`, `preset_torus_thickness`, `preset_torus_detail` | Positive radius/thickness, detail at least 3, and radius greater than thickness |

A new node's preset dimensions/detail values are zero unless an explicit default
is declared; fill them in before applying. For a full circle, leave
`preset_circle_angle_from = 0` and `preset_circle_angle_to = TAU`.
When the end angle differs from `TAU`, the circle helper also adds the center
point to form a sector.

The torus helper creates a **flat ring outline**, not a curved 3D donut.
Its outer radius is `radius + thickness`; inner radius is `radius - thickness`,
so the radial band width is twice `thickness`. It produces a connected point
sequence for triangulation. Inspect the result: this is not a general hole/CSG
operation.

## Public methods

| Method | Result |
| --- | --- |
| `build() -> void` | Rebuilds output and collision from current settings |
| `get_random_point() -> Vector2` | Samples the local drawn polygon by triangle area; returns zero if no positive area is available |

`get_random_point()` does not require a prior build. Its result has not been
rotated, divided by `geometry_scale`, skewed, or placed in 3D.
`STPolygonData.get_top_position()` returns only
`geometry_distance + geometry_height`, not a final world-space height.
