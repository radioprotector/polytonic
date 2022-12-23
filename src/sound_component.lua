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
  -- Dyad for the top two notes
  'G5',
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

  self.base_synth = snd.synth.new(self.waveform)
  self.instrument = snd.instrument.new(self.base_synth)
  self.instrument:playNote(self.base_note)
  self.instrument:setVolume(0.0)
end

function SoundComponent:update()
  if not self.instrument or not self.base_synth then
    return
  end

  local volume_amplitude = math.min(math.abs(self.ring.angle_velocity) / C.VELOCITY_VOLUME_MAX, 1.0)
  self.instrument:setVolume(volume_amplitude)
end
