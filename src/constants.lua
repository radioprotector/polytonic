--- Contains utility constants to be shared across all files
--- @class constants
local C = {}
local THIRD_PI = math.pi / 3

--- The golden ratio.
C.PHI = 1.618

--- One-third of pi, or 60 degrees.
C.THIRD_PI = THIRD_PI

--- One-sixth of pi, or 30 degrees.
C.SIXTH_PI = math.pi / 6

--- Two pi, or 360 degrees.
C.TWO_PI = 2 * math.pi

--- Half of pi, or 90 degrees.
C.HALF_PI = math.pi / 2

--- The number of rings supported by the application.
C.RING_COUNT = 8

--- The radii of each ring's corresponding polygon.
C.POLYGON_RADII = {16, 32, 48, 64, 80, 96, 112, 128}

--- The number of vertices for each ring's corresponding polygon.
C.POLYGON_VERTICES = 6

--- The unit circle degrees, in radians, for each vertex of the ring polygons.
C.POLYGON_VERTEX_RADIANS = {0, THIRD_PI, 2 * THIRD_PI, math.pi, 4 * THIRD_PI, 5 * THIRD_PI, 0}

--- The minimum ring velocity before it is rounded to zero.
C.VELOCITY_MIN = 0.005 * math.pi

--- The maximum ring velocity.
C.VELOCITY_MAX = 4 * math.pi

--- The velocity at which maximum volume is achieved.
C.VELOCITY_VOLUME_MAX = 2 * math.pi

--- The minimum velocity for LFO-based amplitude modulation.
C.VELOCITY_AMP_LFO_MIN = C.VELOCITY_VOLUME_MAX

--- The maximum velocity for LFO-based amplitude modulation.
C.VELOCITY_AMP_LFO_MAX = C.VELOCITY_MAX

--- The amount of angular velocity to apply when pushing a single ring, in degrees.
C.VELOCITY_PUSH_SINGLE_DEG = 20

--- The amount of angular velocity to apply when pushing all rings at once.
C.VELOCITY_PUSH_GLOBAL_DEG = 10

--- The multiplier to apply to angular velocity when braking a single ring.
C.VELOCITY_BRAKE_SINGLE_SCALING = 0.75

--- The multiplier to apply to angular velocity when braking all rings at once.
C.VELOCITY_BRAKE_GLOBAL_SCALING = 0.85

--- The period over which velocity decay is distributed.
C.VELOCITY_DECAY_SECONDS = 10

--- The center x-coordinate.
C.CENTER_X = 200

--- The center y-coordinate.
C.CENTER_Y = 120

--- The unscaled screen height.
C.SCREEN_HEIGHT = 240

--- The unscaled screen width.
C.SCREEN_WIDTH = 400

return C
