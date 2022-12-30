# polytonic

Polytonic is an audiovisual fidget spinner for the [Panic Playdate](https://play.date/). It is inspired by Electroplankton's Lumiloop, originally released for the Nintendo DS.

## Interaction

Eight "rings" are depicted on screen.

- ⬆️ and ⬇️ moves the selected ring outward and inward respectively.
- ⬅ and ➡ push the selected ring counter-clockwise and clockwise respectively.
- Ⓑ and Ⓐ push _all_ rings counter-clockwise and clockwise respectively.
- Ⓑ+Ⓐ simultaneously will:
  - Brake the currently-selected ring, if there is one; or
  - Brake _all_ rings otherwise
- Turning the crank will rotate the selected ring.

A guide to these controls can be viewed by selecting the *Show Help* menu option on the pause screen.

The background will animate depending on how all rings are aligned. This can be turned off by unchecking the *Animate BG* menu option on the pause screen.

## Sound

Turning a ring will make it generate sound. As the ring turns faster, it will play more loudly up to a certain threshold. Once that threshold has been reached, the volume will become more varied.

If the ring turns counter-clockwise, it will experience a vibrato effect as its speed increases.

Each ring is assigned its own note and waveform:

| Ring Layer | Note | Waveform       |
| ---------- | ---- | -------------- |
| 1 (Inner)  | E5   | PO Vosim       |
| 2          | C5   | Square         |
| 3          | G4   | Sine           |
| 4          | E5   | Triangle       |
| 5          | C4   | Sawtooth       |
| 6          | C3   | Sine           |
| 7          | G2   | Square         |
| 8 (Outer)  | C2   | Sawtooth       |

## Technical Details

I didn't have experience with Lua going into this, so I tried to structure things as best I could. The key files are:

- `main.lua` is the key entry point for the application, tracks most global objects, contains the main game loop, and performs Playdate event handling.
- `constants.lua` contains key constants shared throughout the application.
- `glue.lua` contains glue code for `require`-like syntax and some extensions to the `math` library
- `app_state.lua` contains a singleton for configuration state and utilities for saving/loading that state to JSON.
- `ring.lua` is the main ring entity definition.
- `ring_display_component.lua` and `ring_sound_component.lua` contain the components for displaying and generating sound from each ring respectively.
- `ui_component.lua` is a singleton for rendering UI-related concerns.

The game is targeted to run at 30 FPS. Each entity and component has an `update` method that is called each frame. Display-oriented components have one or more `draw` methods to render to screen each frame.

Internally, angular position and velocity is represented in terms of radians. This requires some conversion when interacting with the crank, as its input methods return degrees instead. There is also some conversion required to turn "positive" radians into clockwise motion, as the unit circle normally goes counter-clockwise.

Because I ran into performance issues using sprites (particularly with `drawPolygon` and `fillPolygon` calls), all display/UI elements are drawn directly to the frame buffer.

I looked into adding more robust sound effects, particularly in response to motion. However, because the tones are themselves fairly "pure" and constant, the available suite of effects did not seem to create enough variance. Amplitude and frequency LFOs seemed much more impactful.

For UI elements, I drew some custom glyphs to better represent the different actions available and embedded those in a custom font. The existing `drawText` method is provided the Unicode code points for those custom glyphs.

