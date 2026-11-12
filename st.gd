@icon("resources/icons/st.svg")
class_name ShaperTech

#region Enums
enum BuildOnReadyType {DISABLED, EDITOR_ONLY, ALWAYS}
enum BuildMode {MANUAL, AUTOMATIC_EDITOR_ONLY, AUTOMATIC_ALWAYS}
enum PresetType {NONE, CIRCLE, RECTANGLE, TORUS}
enum MaterialType {SOLID, TRANSPARENT, DISABLED}
enum MaterialReverseFacesMode {DISABLED, ENABLED, AUTOMATIC}
#endregion

#region Constants
const DEFAULT_MATERIAL_SOLID: StandardMaterial3D = preload("uid://vde58ckktsu5")
const DEFAULT_MATERIAL_TRANSPARENT: StandardMaterial3D = preload("uid://c6ukoruhpitps")
const DEFAULT_TEXTURE: CompressedTexture2D = preload("uid://bfrh1yynkwyt2")
const DEFAULT_GEOMETRY_SCALE: float = 32.0
const DEFAULT_BUILD_AUTOMATIC_INTERVAL: float = 0.5
const DEFAULT_COLLISION_LAYER: int = 1
const DEFAULT_COLLISION_MASK: int = 1

const MIN_DIRECTION_LENGTH: float = 0.0001
const MIN_DISTANCE_LENGTH: float = 0.001
const MIN_TIMER_INTERVAL: float = 0.001

const METHOD_BUILD: StringName = &"build"
#endregion
