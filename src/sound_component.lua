import 'CoreLibs/object'

import 'glue'
local C <const> = require 'constants'
local snd <const> = playdate.sound

local RING_WAVEFORMS <const> = {
  snd.kWavePOVosim,
  snd.kWaveTriangle,
  snd.kWaveSine,
  snd.kWavePODigital,
  snd.kWavePOPhase,
  snd.kWaveSine,
  snd.kWaveSquare,
  snd.kWaveSawtooth
}

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

local CHANNEL_VOLUME <const> = 0.01
local INSTRUMENT_VOLUME_MAX <const> = 0.125
local LFO_RATE_MIN <const> = 0.025
local LFO_RATE_MAX <const> = 5
local LFO_DEPTH_MIN <const> = 0.5
local LFO_DEPTH_MAX <const> = 1.0
local LFO_DEPTH_RANGE <const> = LFO_DEPTH_MAX - LFO_DEPTH_MIN

class('SoundComponent').extends()

function SoundComponent:init(ring)
  SoundComponent.super.init(self)
  self.ring = ring
  self.base_note = RING_NOTES[self.ring.layer]
  self.waveform = RING_WAVEFORMS[self.ring.layer]

  if not self.base_note or not self.waveform then
    print("invalid ring! layer #" .. ring.layer)
    return
  end

  -- Create a synth.
  -- Previously we looked at wrapping this in an instrument for polyphony,
  -- but I think that's too much of a performance hit at the moment.
  self.base_synth = snd.synth.new(self.waveform)
  self.base_synth:playNote(self.base_note)
  self.base_synth:setVolume(0.0)

  -- Create an LFO for the synth amplitude
  self.lfo = snd.lfo.new(snd.kLFOSine)
  self.lfo:setCenter(LFO_DEPTH_MIN + (LFO_DEPTH_RANGE / 2))
  self.lfo:setRate(LFO_RATE_MIN)
  self.lfo:setPhase((self.ring.layer - 1) / C.RING_COUNT)
  self.lfo:setDepth(0)
  self.lfo_active = false
  self.base_synth:setAmplitudeMod(self.lfo)

  -- Create a channel just for this synth
  self.channel = snd.channel.new()
  self.channel:setVolume(CHANNEL_VOLUME)
  self.channel:addSource(self.base_synth)
end

function SoundComponent:update()
  if not self.base_synth then
    return
  end

  -- Change the volume of the instrument, up to a set threshold, based on the velocity
  local abs_velocity = math.abs(self.ring.angle_velocity)
  local volume_amplitude = math.clamp(abs_velocity / C.VELOCITY_VOLUME_MAX, 0.0, INSTRUMENT_VOLUME_MAX)
  self.base_synth:setVolume(volume_amplitude)

  -- Change the intensity of the LFO based on whether we're at the sufficient threshold
  if abs_velocity > C.VELOCITY_LFO_MIN then
    local lfo_rate = math.mapLinear(abs_velocity, C.VELOCITY_LFO_MIN, C.VELOCITY_LFO_MAX, LFO_RATE_MIN, LFO_RATE_MAX)
    self.lfo:setRate(lfo_rate)

    -- Only mess with the depth if the LFO is not activated
    if not self.lfo_active then
      self.lfo:setDepth(LFO_DEPTH_RANGE)
      self.lfo_active = true
    end
  elseif self.lfo_active then
    self.lfo:setDepth(0)
    self.lfo_active = false
  end
end
