-- Contains utility constants to be shared across all files
local C = {}
local THIRD_PI = math.pi / 3

C.PHI = 1.618
C.THIRD_PI = THIRD_PI
C.TWO_PI = 2 * math.pi
C.HALF_PI = math.pi / 2
C.RING_COUNT = 8
C.POLYGON_RADII = {16, 32, 48, 64, 80, 96, 112, 128}
C.POLYGON_VERTICES = 6
C.POLYGON_VERTEX_RADIANS = {0, THIRD_PI, 2 * THIRD_PI, math.pi, 4 * THIRD_PI, 5 * THIRD_PI, 0}
C.RING_BASE_ZINDEX = 1000
C.UI_BASE_ZINDEX = 2000
C.VELOCITY_MIN = 0.005 * math.pi
C.VELOCITY_MAX = 4 * math.pi
C.VELOCITY_VOLUME_MAX = 2 * math.pi
C.VELOCITY_AMP_LFO_MIN = C.VELOCITY_VOLUME_MAX
C.VELOCITY_AMP_LFO_MAX = C.VELOCITY_MAX
C.VELOCITY_PUSH_SINGLE_DEG = 20
C.VELOCITY_PUSH_GLOBAL_DEG = 10
C.VELOCITY_BRAKE_SINGLE_SCALING = 0.75
C.VELOCITY_BRAKE_GLOBAL_SCALING = 0.85
C.VELOCITY_DECAY_SECONDS = 10
C.CENTER_X = 200
C.CENTER_Y = 120
C.SCREEN_HEIGHT = 240
C.SCREEN_WIDTH = 400

return C
