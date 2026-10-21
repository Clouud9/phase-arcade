# Phase Arcade is Open
![](Images/phase_arcade.gif)
We want *your* games to populate *Phase Arcade*; a mysterious abandoned entertainment venue set as a showcase of jammers' talents, and perhaps something more sinister...?

# When?
We're hoping to finish up the Arcade for its grand opening by Halloween. We don't yet know what happens after that

# What Type of Game?
The ideal game for the Arcade has these qualities:
1. it's an _Arcade game_
2. it's a _Phase game_, and
3. it's at least a little bit _haunted_.

See also the [Limitations and Guidelines](#limitations-and-guidelines) section for details. Some of those *may* be a dealbreaker. We've done what we can to allow just about any [Godot](https://godotengine.org/) game to run in the arcade, but there are still some unavoidable restrictions.

An arcade game is about exchanging quarters for lives, earning points, and getting a high score. We're building systems to support those specific things, and also earning tickets for prizes. We have a system we're quite proud of that can print ludicrous quantities of tickets, so if you want to make a game you can crack wide open, Balatro-style, that would be cool. If your game doesn't have much to do with these systems, that's fine. But be aware that your game may end up playing a less meaningful role in the overall experience as a result.

While the jam is a great opportunity to make a fresh game for the arcade, it's not just jam games you can submit; any game you've made, if it's a good fit, and if we can port it to the arcade, would be welcome!
This documentation focuses on video game cabinets but if you'd like to make some other kind of arcade attraction; pinball, or a claw-machine, or something of that sort, we'd be delighted to accommodate! We will have to ask you to work a little more closely with us to ensure that your submission will work in the arcade, mechanically and thematically.

# Step-by-step Guide
- [Setting up your game](#setting-up-your-game)
- [Testing your game](#testing-your-game)
- [Limitations and Guidelines](#limitations-and-guidelines)
  - [Input](#input)
  - [Video](#video)
  - [Audio](#audio)
  - [Getting along with your neighbors](#getting-along-with-your-neighbors)
- [Setting up your cabinet](#setting-up-your-cabinet)
  - [Configuring the cabinet](#configuring-the-cabinet)
    - [Screen Size](#screen-size)
    - [CRT Filter](#crt-filter)
    - [Screen Illumination](#screen-illumination)
    - [Controls](#controls)
  - [Customizing your cabinet](#customizing-your-cabinet)
    - [Cabinet Model](#cabinet-model)
    - [Material](#material)
    - [Texture](#texture)
- [Other things](#other-things)
  - [Score and Highscore](#score-and-highscore)
  - [Project Settings](#project-settings)
    - [Low tick rate](#low-tick-rate)
    - [Interpolation](#interpolation)
  - [Other ways to help](#other-ways-to-help)

The first step is downloading [Godot 4.7](https://godotengine.org/download/archive/4.7.2-stable) if you don't have it already. Games made with other versions of Godot will probably work, and if not, they can probably be ported. But 4.7 is what we're using.


The next step is cloning the repo. We're using [LFS](https://git-lfs.com/) to manage large files such as audio and lightmaps. If you have LFS isntalled, good, but it's not required to clone the repo. Run `git clone https://github.com/jcomcl/phase-arcade.git --depth=1`. The `--depth=1` option will reduce the download size quite substantially.

## Setting up your game
Create a folder for your game in `Arcade Games`, then pick whichever template project suits you most, (either `_Game2D.tscn`, or `_Game3D.tscn`, `_GameUI.tscn`), and create a new inherited scene from it, which will go in your new game folder.

![](Images/new_game.jpg)

The game root will have a script attached: [`game.gd`](Arcade Games/game.gd). Right click to find '*Open Documentation*', which will tell you more about it. There is a lot of existing code in this project, and we've done our best to document the parts that you might want or need to use. Be sure to read the documentation, and let us know if there are any issues with it. This guide is specifically for the high-level details that aren't covered in the docs, so it won't suffice on its own.
You may want to click `*Extend Script*` on your root node to have your own root script without breaking compatibility. **We recommend relying on the `Game` class where you can**, as it will make it easier for us to fix any bugs and to ensure compatibility.
## Testing your game
You'll see file called [closet.tscn](closet.tscn) in the repo root. This is where you can run your game on one of the cabinets. Click on the Cabinet node and drag your game's tscn into the cabinet's `Game Scene` slot in the inspector panel.

![Yo, if you're blind, that sucks, dude. I'm sorry to hear that](Images/add_game_to_cabinet.jpg)

After that, hit play; it should just work. There's a decent chance it will be cropped incorrectly; to fix that see [Setting up your cabinet](#setting-up-your-cabinet)

## Limitations and Guidelines
Before you start on your game, there are some things you should be aware of about how the arcade cabinet actually embeds your game. Some of these won't present as problems until way later, when your custom cabinet is being added to the Arcade, at which point it will be much harder to fix. The **important parts** will be in bold.
### Input
Redirecting input events is fairly easy in Godot. Any [`_input`](https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-unhandled-input) or [`_unhandled_input`](https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-unhandled-input) in your game will receive only the input events sent by the cabinet via the player. However, you should **never use the [`Input`](https://docs.godotengine.org/en/stable/classes/class_input.html) singleton** as that will query *all* input, even when your game is not being played. As a substitute, you can call `ArcadeCabinet.get_input_state(self)` from any node in your game, which will return the current state of the cabinet control surface. If control the surface seems too limited, let us know and we may add more.
If you have custom UI in your game, make sure that it controls using `ui_` events (`ui_up`, `ui_down`, etc) instead of movement events (`up`, `down` `left`, `right`). Movement events won't behave correctly for joysticks.

Oh yes, also **test on a joypad** if you have one to hand. Your game should work flawlessly with one.
### Video
Video redirection is achieved using [SubViewports](https://docs.godotengine.org/en/stable/tutorials/rendering/viewports.html). You may need to learn a little bit about how these work if you run into any problems, but you'll probably be fine. What's more important to be aware of is **your game should run at around Standard Definition (~480p) or lower**. This will limit the amount of text you can fit on the screen. See the [screen size section](#screen-size) for more details. Note that this is mostly a stylistic decision, and we could make exceptions, but we really encourage you to try to lean into the limitations of the medium.
### Audio
Audio is redirected using [`AudioEffectCapture`](https://docs.godotengine.org/en/stable/classes/class_audioeffectcapture.html), which *should* Just Work™, but it has some known shortcomings: It adds an unavoidable 40ms of latency to the audio, and it can very easily choke and crackle in web builds. However, it seems rock-solid so far. If we end up having to replace it with something more bone-headed, it can hopefully be done automatically.
### Getting along with your neighbors
This is a shared Godot project, it's been set up in a somewhat opinionated way. Many of the layers already have names, and many of the good class names have already been taken. If you're used to a very specific kind of workflow that relies on your `project.godot` being set up in a very specific way, you may struggle here. For best results, prefix your class names with the name of your game, and use your game root script for any utility functions. You may be surprised to learn how much of the usecase for `Autoload` can be replaced with `static` functions. Alternatively, if you're used to cowboy-coding, and your gdscript has a lot of `get_parent().get_parent().get_parent().get_child(4)`, you should have absolutely no trouble with this new workflow.

## Setting up your cabinet
So you want your own, dedicated cabinet with its own model, texture, and branding? This section shows you how to set that up, but it also applies to the placeholder cabinet in the test closet. You'll want to experiment with the settings; how your cabinet is set up *will impact* the game.
Many aspects of the cabinet will already be documented, you can hover over something to see what it does.

![](Images/tooltip.jpg)

If you find something which isn't documented and should be, let us know.

### Configuring the cabinet

![](Images/cabinet.png)

Here are the aspects of the cabinet you'll likely want to modify in descending order of importance
#### Screen Size
the `SubViewport` `size` property controls screen size and synchronizes it with the other components automatically. At higher resolutions like 640x480, you may want to increase `crt downscale` to reduce artifacts, we're working on an automatic fix for this problem. You may still want to increase it for aesthetic purposes.
Note: The 3D and UI game presets should adapt automatically to the new screen size, but **the 2D preset will require manually managing the game size**. Screen size often has a lot of gameplay consequences in 2D games so it's worth nailing down early. In general we recommend going with the smallest size you feel like you can get away with.
#### CRT Filter
The `Screen` has a CRT filter on it, we've chosen reasonable defaults but you're welcome to experiment. Many of the settings alter the color and contrast, so be sure to check that your game looks as good on the screen as it does in your editor.
#### Screen Illumination
We're using Godot 4.7's new AreaLights to illuminate the cabinet from the screen. It's not physically accurate because doing it physically accurately would be unbelievably expensive, so you may have to dial in some setting to make the effect look good for your particular game. If your game is relatively dark, you may want to increase the Energy on the `ScreenLight`. `Downsample` is the SubViewport which creates the texture for the light's color. Increasing the size can help smooth out flickering caused by a low sample size, but also exponentially costs performance. Increasing the cabinet's `light_update_interval` will also reduce flickering by smoothing the transition over time, but this will make it less responsive.

Increasing `light_update_interval` can also improve performance, however if recalculating the lighting is causing noticable lag spikes then this will only space those out. If it's a common problem we'll look at implementing a smarter sampling method that lets us use a smaller sample texture in the future.

Also note, **many of the performance-related options will be automatically modulated in the arcade** if necessary. So don't worry too much about that.

#### Controls
`ControlPlane` manages the controls. Set visibility off on the ones you aren't using. Feel free to move them and scale them you your liking. For best results, use the transform property editor instead of the gizmo. The gizmo doesn't operate in local space.

![](Images/transform-property.png)

If you want more controls, or different type of controls, let us know.

### Customizing your cabinet
To create a custom cabinet, you'll want a model, a material, and a texture in the `cabinet` folder in your game.

![](Images/custom-cabinet-folder.png)

#### Cabinet Model
There are currently three pre-made models in `Cabinets/presets/`, each inspired by a different real arcade cabinet. Choose whichever one you prefer and create a *New Inherited Scene* in your game's cabinet folder. You can use the `_cabinet.tscn` preset if you want more control, to bring your own model. Feel free to request a specific cabinet model, I can make them pretty quickly now, and I will be adding more anyway.
#### Material

![](Images/new-material.jpg)

Duplicate `Arcade_machine.tres` into you cabinet folder. Call it whatever you like. You need a new material to change the textures, but you'll probably want to keep almost everything the same. To apply your material, add it to the cabinet's "Custom Material" slot.

![](Images/apply-custom-material.jpg)

#### Texture

[Cabinets/textures/](Cabinets/textures/) has some good resources to get you started, in particular [flat-colors](Cabinets/textures/flat-colors.png) and [annotations](Cabinets/textures/annotations.png). There are some minor differences in how the textures a mapped for different cabinets, be sure to check in-engine that your work looks the way you expect.
Drag your texture into the "Albedo" slot in your custom material.

![](Images/drag-albedo-texture.jpg)

And there you go! A work of art.

![](Images/kool-kustom-kabinet.png)

## Other things
### Score and Highscore
Use the game's `score` methods to track the score. We haven't figured out highscore yet. We're hoping to do that within the first few days of the jam, and with any luck the online component will be handled for you without you needing to lift a finger.
### Project Settings
#### Low tick rate
The project is using a much lower-than-default physics tick rate of `15`. I like to do this to catch bugs that come from relying on the tick rate being the same as the refresh rate of most people's monitors. It may result in poor physics accuracy. If so, let us know and we will raise it back up again.
#### Interpolation
We also have physics interpolation enabled. If you find that things are smoothly moving across when they were supposed to teleport, remember to call `reset_physics_interpolation`.
See here for more info: [using_physics_interpolation](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/using_physics_interpolation.html)
### Other ways to help
The Arcade is a big project and we have lot's of ideas, but only enough time to implement a few of them. If you want to help out, we can almost certainly find a job for you. Here are some other easy things that you could contribute:
- Posters (png)
- Graffiti (png)
- Other props

If you want to do **character modelling** for us, we have a special task that's particularly dear to me, which may otherwise not make it in.
