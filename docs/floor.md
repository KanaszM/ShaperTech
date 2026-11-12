# STFloor

[Documentation home](../README.md)

`STFloor` extends `Polygon2D`. It turns its `polygon` into a zero-thickness 3D
surface with independent top and bottom faces. Use it for ground planes, floor
panels, or ceilings when an extruded edge is unnecessary.

## Shape and placement

Supply at least three points forming a valid triangulatable outline. The builder
places both faces at local Y `0`, using opposite triangle order for top/bottom.
The mesh is then raised by:

```text
geometry_distance + geometry_position_offset.y + ancestor container offsets
```

The horizontal scale and placement rules match
[STPolygon](polygon.md). A 128-by-64 drawing at scale `32` gives a 4-by-2 surface.
Unlike STPolygon, STFloor has **no height, side faces, or skew properties**.

## Resources

| Resource | Contents |
| --- | --- |
| `STFloorData` | Distance, rotation, position offset, visibility, scale, collision |
| `STFloorMaterials` | Top, Bottom, and Override groups |

Defaults include distance `0`, rotation `0`, zero offset, scale `32`,
synchronized visibility enabled, and collision disabled.

Use the Top group for a floor viewed from above, and Bottom for a ceiling viewed
from below. Setting one group to `DISABLED` removes its triangles. The two
faces otherwise occupy the same plane; they are not separated by any thickness.
See [Materials and UVs](materials-and-uvs.md) for winding and texture controls.

## Tools and building

STFloor exposes the same Expand, Shrink, horizontal/vertical Flip, and preset
Apply tools as STPolygon. Refer to the
[polygon tools and presets](polygon.md#polygon-tools) for their parameters,
units, requirements, and limitations.

Node-owned Build/Nodes/Parent controls and container participation are identical
to the other shapers. Geometry/property edits need a manual build or an active
automatic timer.

## Collision and overlap

Collision is generated from the flat mesh triangles, not a solid slab.
If you need thickness or a solid visible perimeter, use `STPolygon` with a
positive height instead. Avoid stacking several floors at precisely the same
height: overlapping coplanar faces can flicker.

## Public methods

| Method | Result |
| --- | --- |
| `build() -> void` | Rebuilds the floor and its collision |
| `get_random_point() -> Vector2` | Area-weighted point in the local, unscaled drawn polygon |
| `STFloorData.get_top_position() -> float` | `geometry_distance` only |

The data height getter excludes geometry offsets, container offsets, and scene
transforms. For converting sampled drawing points, see [Scripting](scripting.md).
