-- Contains utility constants to be shared across all files
local C = {}
local THIRD_PI = math.pi / 3

C.THIRD_PI = THIRD_PI
C.TWO_PI = 2 * math.pi
C.RING_COUNT = 8
C.POLYGON_RADII = {16, 32, 48, 64, 80, 96, 112, 128}
C.POLYGON_VERTICES = 6
C.POLYGON_VERTEX_RADIANS = {0, THIRD_PI, 2 * THIRD_PI, math.pi, 4 * THIRD_PI, 5 * THIRD_PI, 0}
C.VELOCITY_MIN = 0.01 * math.pi
C.VELOCITY_MAX = 4 * math.pi
C.VELOCITY_PUSH_DEG = 5
C.VELOCITY_DECAY_SECONDS = 30
C.CENTER_X = 200
C.CENTER_Y = 120
C.SCREEN_HEIGHT = 240
C.SCREEN_WIDTH = 400

return C
