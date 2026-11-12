# STWall

[Documentation home](../README.md)

`STWall` extends `Line2D`. It builds one vertical quad for every adjacent pair
of line points, with separate front and back materials.

## Shape

Use two or more points. The path is open: the last point is not automatically
connected to the first. To create a closed perimeter, explicitly end the path at
its starting point.

The wall is a **zero-thickness surface**. It has no width setting and generates
no top cap, bottom cap, or solid end caps. The front and back occupy the same
surface with opposite winding. For a thick barrier, draw a narrow polygon and
use [STPolygon](polygon.md) instead.

`Line2D.width`, its 2D texture, and other visual line settings are not wall
geometry controls. Use the shaper's Data and Materials resources.

## Geometry data

`STWallData.geometry_height` defaults to `1.0`. The shared distance, rotation,
position, scale, visibility, and collision properties follow
[Coordinates and building](coordinates-and-building.md).

The wall-specific properties all default to zero/false:

| Property | Effect |
| --- | --- |
| `geometry_skew_y` | Vertical offset applied using the endpoint rules below |
| `geometry_skew_y_reversed` | Selects the bottom shift and which segment top endpoint receives the offset |
| `geometry_skew_z` | Depth offset along global mesh-local Z, not along each segment's normal |
| `geometry_skew_z_reversed` | Chooses whether the depth shift is on the bottom or top |

Skew is applied in 3D units after converting the drawing points. With height
`H` and vertical skew `K`, each segment uses:

| Y-skew reversed | Bottom start/end | Top start | Top end |
| --- | --- | --- | --- |
| `false` | `0` | `H` | `H + K` |
| `true` | `K` | `H + K` | `H` |

These are **per-segment** endpoint rules. On a multi-segment path a shared point
can have different top heights on its two adjacent quads when `K` is nonzero.
Do not treat this setting as a continuous height spline.

For depth skew, unreversed mode subtracts `geometry_skew_z` from top Z and
leaves bottom Z unchanged. Reversed mode adds it to bottom Z and leaves top Z
unchanged.

## Materials and texture coordinates

`STWallMaterials` provides Front, Back, and Override groups. Each face can be
solid, transparent, or disabled, with its own direction, tiling, rotation, and
reverse-face mode. Disable one group for a one-sided wall.

The UV origin resets for each segment. Horizontal stretching therefore maps
each segment independently; unequal segment lengths can produce unequal texture
density when stretching. Vertical UV extents are derived from the distance
between each bottom and top endpoint, including skew, rather than only nominal
height. See [Materials and UVs](materials-and-uvs.md).

## Public methods

| Method | Result |
| --- | --- |
| `build() -> void` | Rebuilds all segment surfaces and collision |
| `get_calculated_points() -> PackedVector2Array` | Cached points after geometry rotation and origin/offset addition, but before division by scale |
| `STWallData.get_top_position() -> float` | Nominal `geometry_distance + geometry_height` |

Call `build()` before using cached points. Divide `get_calculated_points()`
by `geometry_scale` to obtain the horizontal coordinates used by the mesh;
the cache excludes vertical placement and skew. The nominal height getter
excludes skew, offsets, containers, and scene transforms.
