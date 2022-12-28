--- The component for generating sound for a ring.
--- @class RingSoundComponent
--- @field ring Ring The ring represented by this instance.
--- @field update fun(self: RingSoundComponent) Updates this instance.
import 'CoreLibs/object'

import 'glue'
local C <const> = require 'constants'
local snd <const> = playdate.sound

-- Ensure commonly-used math utilities are local for performance
local math_modf <const> = math.modf
local math_abs <const> = math.abs
local math_clamp <const> = math.clamp
local math_mapLinear <const> = math.mapLinear

-- Similarly localize key constants
local VELOCITY_MAX <const> = C.VELOCITY_MAX
local VELOCITY_VOLUME_MAX <const> = C.VELOCITY_VOLUME_MAX
local VELOCITY_AMP_LFO_MIN <const> = C.VELOCITY_AMP_LFO_MIN
local VELOCITY_AMP_LFO_MAX <const> = C.VELOCITY_AMP_LFO_MAX

--- The waveform to use for each sound, keyed by ring layer.
local RING_WAVEFORMS <const> = {
  snd.kWavePOVosim,
  snd.kWaveSquare,
  snd.kWaveSine,
  snd.kWaveTriangle,
  snd.kWaveSawtooth,
  snd.kWaveSine,
  snd.kWaveSquare,
  snd.kWaveSawtooth
}

--- The base note to use for each sound, keyed by ring layer.
local RING_NOTES <const> = {
  'E5',
  'C5',
  -- Triad for the next three
  'G4',
  'E4',
  'C4',
  'C3',
  -- Basses
  'G2',
  'C2'
}

--- The frequency modulation LFO depth to use for each sound, keyed by ring layer.
local RING_FREQ_LFO_DEPTHS <const> = {
  0.004,
  0.007,
  0.009,
  0.01,
  0.01,
  0.01,
  0.01,
  0.01
}

--- The global volume applied to each sound's corresponding channel.
local CHANNEL_VOLUME <const> = 0.01

--- The maximum volume for each sound's corresponding instrument.
local INSTRUMENT_VOLUME_MAX <const> = 0.125

--- The minimum rate for the amplitude modulation LFO, in hertz.
local AMP_LFO_RATE_MIN <const> = 0.025

--- The maximum rate for the amplitude modulation LFO, in hertz.
local AMP_LFO_RATE_MAX <const> = 5

--- The center of the amplitude modulation LFO. Structured to vary between 40-100%.
local AMP_LFO_CENTER <const> = 0.70

--- The range of the amplitude modulation LFO. Structured to vary between 40-100%.
local AMP_LFO_DEPTH <const> = 0.3

--- The minimum rate for the frequency modulation LFO, in hertz.
local FREQ_LFO_RATE_MIN <const> = AMP_LFO_RATE_MIN * 2

--- The maximum rate for the frequency modulation LFO, in hertz.
local FREQ_LFO_RATE_MAX <const> = AMP_LFO_RATE_MAX * 2

--- The center of the frequency modulation LFO.
local FREQ_LFO_CENTER <const> = 0 -- By default, keep the frequency where it is

class('RingSoundComponent').extends()

--- Creates a new instance of the RingSoundComponent class.
--- @param ring Ring The ring entity represented by this instance.
function RingSoundComponent:init(ring)
  RingSoundComponent.super.init(self)
  self.ring = ring
  self.base_note = RING_NOTES[self.ring.layer]
  self.waveform = RING_WAVEFORMS[self.ring.layer]
  self.freq_lfo_depth = RING_FREQ_LFO_DEPTHS[self.ring.layer]

  if not self.base_note or not self.waveform or not self.freq_lfo_depth then
    print("invalid ring! layer #" .. ring.layer)
    return
  end

  -- Create a synth.
  -- Previously we looked at wrapping this in an instrument for polyphony,
  -- but I think that's too much of a performance hit at the moment.
  self.base_synth = snd.synth.new(self.waveform)
  self.base_synth:playNote(self.base_note)
  self.base_synth:setVolume(0.0)

  -- Create a phase to share across the LFOs
  local amp_lfo_phase <const> = (self.ring.layer - 1) / C.RING_COUNT
  local _, freq_lfo_phase <const> = math_modf(amp_lfo_phase + 0.5)

  -- Create an LFO for the synth amplitude
  self.amp_lfo = snd.lfo.new(snd.kLFOSine)
  self.amp_lfo:setCenter(AMP_LFO_CENTER)
  self.amp_lfo:setRate(AMP_LFO_RATE_MIN)
  self.amp_lfo:setPhase(amp_lfo_phase)
  self.amp_lfo:setDepth(0)
  self.amp_lfo_active = false
  self.base_synth:setAmplitudeMod(self.amp_lfo)

  -- Create an LFO for the synth frequency
  self.freq_lfo = snd.lfo.new(snd.kLFOSine)
  self.freq_lfo:setCenter(FREQ_LFO_CENTER)
  self.freq_lfo:setRate(FREQ_LFO_RATE_MIN)
  self.freq_lfo:setPhase(freq_lfo_phase)
  self.freq_lfo:setDepth(0)
  self.freq_lfo_active = false
  self.base_synth:setFrequencyMod(self.freq_lfo)

  -- Create a channel just for this synth
  self.channel = snd.channel.new()
  self.channel:setVolume(CHANNEL_VOLUME)
  self.channel:addSource(self.base_synth)
end

--- Updates this instance's sound based on the current state of its associated ring.
function RingSoundComponent:update()
  if not self.base_synth then
    return
  end

  -- Change the volume of the instrument, up to a set threshold, based on the velocity
  local velocity <const> = self.ring.angle_velocity
  local abs_velocity <const> = math_abs(velocity)
  local volume_amplitude = math_clamp(abs_velocity / VELOCITY_VOLUME_MAX, 0.0, INSTRUMENT_VOLUME_MAX)
  self.base_synth:setVolume(volume_amplitude)

  -- Change the intensity of the amplitude LFO if velocity is high enough
  if abs_velocity > VELOCITY_AMP_LFO_MIN then
    local amp_lfo_rate = math_mapLinear(abs_velocity, VELOCITY_AMP_LFO_MIN, VELOCITY_AMP_LFO_MAX, AMP_LFO_RATE_MIN, AMP_LFO_RATE_MAX)
    self.amp_lfo:setRate(amp_lfo_rate)

    -- Only mess with the depth if the LFO is not activated
    if not self.amp_lfo_active then
      self.amp_lfo:setDepth(AMP_LFO_DEPTH)
      self.amp_lfo_active = true
    end
  elseif self.amp_lfo_active then
    self.amp_lfo:setDepth(0)
    self.amp_lfo_active = false
  end

  -- Change the depth of the frequency LFO if in a counter-clockwise (positive radians) velocity
  if velocity > 0 then
    local freq_lfo_rate = math_mapLinear(abs_velocity, 0, VELOCITY_MAX, FREQ_LFO_RATE_MIN, FREQ_LFO_RATE_MAX)
    self.freq_lfo:setRate(freq_lfo_rate)

    -- Only mess with the depth if the LFO is not activated
    if not self.freq_lfo_active then
      self.freq_lfo:setDepth(self.freq_lfo_depth)
      self.freq_lfo_active = true
    end
  elseif self.freq_lfo_active then
    self.freq_lfo:setDepth(0)
    self.freq_lfo_active = false
  end
end
