# Materials and UVs

[Documentation home](../README.md)

Each shaper has a dedicated materials resource. These resources select which
surfaces are emitted and how their texture coordinates and winding are built.
They do not change the outline.

## Surface groups

| Resource | Surface groups | Override selectors |
| --- | --- | --- |
| `STPolygonMaterials` | Top, Bottom, Sides | `override_apply_to_top`, `override_apply_to_bottom`, `override_apply_to_sides` |
| `STFloorMaterials` | Top, Bottom | `override_apply_to_top`, `override_apply_to_bottom` |
| `STSlopeMaterials` | Slope, Sides, Back, Bottom | `override_apply_to_slope`, `override_apply_to_sides`, `override_apply_to_back`, `override_apply_to_bottom` |
| `STWallMaterials` | Front, Back | `override_apply_to_front`, `override_apply_to_back` |

Use the group prefix in property names, such as `top_tile_horizontal`,
`sides_texture_direction`, or `front_rotation`.

## Material type

`ShaperTech.MaterialType` has three values:

| Type | Resolution |
| --- | --- |
| `SOLID` | Uses the group's assigned material; if null, uses the bundled solid material |
| `TRANSPARENT` | Uses the bundled transparent material, regardless of the assigned material |
| `DISABLED` | Returns no material and omits the corresponding surface |

The default type is `SOLID`. The bundled solid material uses the supplied texture
with nearest filtering. The bundled transparent material has alpha scissor
transparency and zero albedo alpha: it is intended to be invisible, not a visible
glass preset.

To use your own translucent/glass material, select `SOLID` and assign that
material. The enum chooses a resource-selection path; it does not force your
assigned material to be opaque.

`TRANSPARENT` and `DISABLED` are not equivalent. Transparent surfaces are emitted
and can contribute collision. Disabled surfaces are not emitted.

## Common per-group settings

| Suffix | Default | Meaning |
| --- | --- | --- |
| `_material` | `null` | Custom Godot `Material` used in SOLID mode |
| `_reverse_faces_mode` | `DISABLED` | Triangle-winding control |
| `_tile_horizontal` | `true` | Keeps U in surface-distance units rather than normalizing it |
| `_tile_vertical` | `true` | Keeps V in surface-distance units rather than normalizing it |
| `_texture_direction` | `Vector2.RIGHT` | UV projection direction, normalized by the builder |
| `_rotation` | `0.0` | Additional UV rotation in degrees |

These settings generate UVs. They do not enable sampler repeat, edit a material's
UV scale, or change its culling/transparency configuration. Configure the assigned
material or shader to match the intended repeat behavior.

## Tiling versus stretching

With direction `(1, 0)` and rotation `0`, tiled axes use distance-based UV values.
A 4-by-2 top face spans approximately U `0..4` and V `0..2`.
Disabling horizontal tiling normalizes its U extent to approximately `0..1`;
disabling vertical tiling does the same for V.

```text
Surface width = 4 units, direction = RIGHT

tile horizontal = true       tile horizontal = false
+---+---+---+---+             +---------------+
| 1 | 2 | 3 | 4 |             | one full tile |
+---+---+---+---+             +---------------+
U: 0           4             U: 0           1
```

Normalization uses the surface's projected bounding dimensions. It is not
automatic island unwrapping or uniform texel-density correction.

| Surface | UV distance space |
| --- | --- |
| Polygon/floor Top and Bottom | Converted horizontal points relative to their minimum X/Z bounding corner |
| Polygon Sides | Accumulated perimeter and nominal height; normalization uses the complete perimeter |
| Slope | Across width and accumulated arc length of each edge; each edge has its own normalization length |
| Slope Sides | Longitudinal distance and each edge's actual local Y, including raised corners |
| Slope front/back closure | Width and actual per-corner local heights |
| Slope Bottom | Width and centerline length |
| Wall Front/Back | Per-segment local distance and endpoint bottom-to-top lengths |

For wall segments the UV origin resets on each segment, including in tiled mode.
Texture phase is not guaranteed to continue uninterrupted around a multi-point
path. For a raised or skewed shape, stretching refers to these builder dimensions,
not necessarily the exact visible bounds of every individual quad.

## Direction and rotation

For a surface point `p`, origin `o`, normalized texture direction `d`, and
perpendicular `n = (-d.y, d.x)`:

```text
u = dot(p - o, d)
v = dot(p - o, n)
```

Non-tiled axes are divided by their projected width/height. The resulting UV is
then rotated around UV origin `(0, 0)` by the group's `_rotation` angle.

Use `(1, 0)` for the default alignment and `(0, 1)` to align U with the second
surface axis. Direction magnitude does not set texture density because the
vector is normalized. A zero/near-zero direction falls back to `Vector2.RIGHT`.
Combining direction changes with rotation applies both operations; rotation is
not around the center of the face.

## Reverse faces

`ShaperTech.MaterialReverseFacesMode`:

| Mode | Meaning |
| --- | --- |
| `DISABLED` | Uses the builder's default triangle order |
| `ENABLED` | Reverses that order |
| `AUTOMATIC` | For Polygon/Floor caps, derives reversal from triangulation; for Polygon sides, derives it from outline winding |

For slopes and walls, `AUTOMATIC` currently behaves like `DISABLED`: those builders
construct their own face orders rather than inspecting arbitrary polygon winding.

Reversing triangles affects front/back culling and generated normals. It is not a
texture mirror operation. If a face disappears when viewed from the expected
side, inspect winding before replacing the material.

## Overrides

Enable the relevant `override_apply_to_*` selectors to use the Override group's
entire setting set for those surfaces:

```text
selected surface
    -> override type + material
    -> override reverse-face mode
    -> override tile flags + direction + rotation
```

Unselected groups retain their own settings. Override selectors default to false.
An override does not turn on a slope exterior/inward-face flag that is disabled.

## Slope inward faces

Slope resources additionally have `_enabled` and `_double_sided` flags
(`slope_top_enabled` for the slope exterior). Despite the double-sided name,
the latter explicitly emits an additional inward-facing set of triangles.

| Exterior enabled | Double sided | Emitted faces |
| --- | --- | --- |
| `false` | `false` | None |
| `true` | `false` | Exterior only |
| `false` | `true` | Inward only |
| `true` | `true` | Both |

Material type must also resolve to a material. `DISABLED` omits both sets.
These are geometry controls, separate from a material's cull mode, and can
increase both mesh and collision triangle counts.
