# ~~Phase 1: Demo to JK (Sep 27)~~
- [x] visibly working arcade machine
- [x] first person exploration
- [x] interesting level
- [x] interactive coins

# ~~Phase 2: Core Functionality (Oct 01)~~
## Arcade Cabinet
- [x] video
- [-] audio
- [x] input
## Player Character
- [x] basic first person controls
- [x] crouching
- [x] interaction
- [x] cabinet lock-on
- [x] tooltips
- [x] inventory
## Level
- [-] collisions on walls and floor
- [x] hidden coins
- [x] switchable lights

# Phase 3: Open For Submissions (Oct 09)
- [x] documentation
- [x] an easy way to test the game during development
- [-] get started on our respective games to know what's needed
- [ ] different places to put games, how accessible?
- [-] A nice looking screenshot/video/gif for the announcement
## Arcade Cabinet
- [x] screen works for various sizes
- [-] different control schemes
- [x] visual controls
- [x] lock-on bugs fixed
- [-] different cabinet styles with similar UVs
- [ ] insert coins
## API
- [x] port over FX code, add user-added FX library support
- [x] port over utils, split into own files, add 3D support of neccesary
- [ ] port unit.gd and shoota.gd and such
- [-] add documentation comments to everything
- [ ] abstract out useful building blocks such as *lives*
## Highscore
- [x] preset highscore screen
- [x] scorekeeping library
- [ ] online highscores
## Arcade Games
- [x] verify Invaders still works
- [ ] prototype Sakura Shootout mechanics
## Level
- [ ] proper rigidbody interaction
## Audio
- [x] Pool my sfxr effects
- [x] Warioware sfx
- [ ] footsteps
- [-] cabinet controls
- [ ] cabinet power on
- [ ] cabinet insert coins
- [ ] just some, y'know, things buzzing

# Phase 4: Game Jam (Oct 20)
- [ ] help jammers with music
- [ ] fix inevitable bugs
- [ ] provide feedback to jammers
## Night of the Invaders
- [ ] high score
- [ ] upgrades
- [ ] 6+ stages
- [ ] stronger win/loose conditions
- [ ] finish ember
- [ ] endless mode
- [ ] enemy power-ups
### Maybe
- [ ] boss fight
- [ ] other 3 invaders
## Sakura Shootout

# Phase 5: Release (Oct 30)
- [ ] help jammers with custom arcade cabinets
- [ ] impassable areas (perhaps a "too dark" wall)
- [ ] adventure game mechanics
- [ ] fix bugs in the jam games
- [ ] add scares
- [ ] finalize the layout
- [ ] make coins and collectables extra juicy
- [ ] promote
- [ ] hope

# Misc.
## Mood and Story
- [ ] breaking and entering
- [ ] contrast between finished and unfinished areas
- [ ] evidence of the passage of time since construction
- [ ] bringing the arcade back online
- [ ] "puzzles" to unlock new areas
- [ ] something not quite right about this place
## Progression
- [ ] coins hidden deeper in the arcade
- [ ] fuses bring new areas online
- [x] machines print prize tickets
- [ ] vending machine or claw machine to give out prizes
- [ ] glowing pippa
## Visual
- [ ] transluscent drapecloths
- [ ] player character casts a shadow
- [ ] rigid bodies
- [ ] cabinets illuminate themselves
- [ ] flickering lights
## Gamefeel
- [x] gradual angle-based transition from cabinet lock-on
## Props
- [ ] wrecked cabinets
- [ ] various light sources which could operate without mains power
- [ ] things that produce environmental audio
- [x] working doors
- [ ] doors that work and aren't weird or clunky
## Scares
- [ ] things that go bump in the night
- [ ] power outages
- [ ] singing fish
- [ ] signs of a struggle
- [ ] rats
- [ ] dizzy phasebear
## Audio
- [-] coins
- [ ] ambiance
- [ ] good reverb settings
## Arcade Mechanics
- [ ] add demo recording and demo screen
## Convenience
- [x] aggregate reference material in the repo
### Import script
- [x] pull assets from a multi-asset export
- [ ] bounding box
- [ ] rigidbodies

`[x]`: done, `[-]`: WIP, better than nothing

# See Also:
[` assert (height >= width) #TODO  assert does nothing in tool mode, need a better way to handle this`](./player/first_person_player.gd)

[` return initial.move_toward(direction * sharpness / delta, snappiness) - initial #TODO refactor`](./addons/jodot/yute.gd)

[` Game.play_sfx(self, sustain_sfx) #TODO  need to support actual looping of sfx`](./Arcade Games/Invaders/units/weapons/sustainer.gd)

[` assert(false) #TODO  more helpful error message, maybe config warning`](./Arcade Games/game.gd)
