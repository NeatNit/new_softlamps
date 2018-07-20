# TO DO

Make this file useful for keeping track of my goals!

---

## Classes

### HeavyLightBase
All HeavyLight addons are derived from this class.

#### Hook: Start
This hook is optional.

The HeavyLight rendering is beginning, perform any preperations necessary - e.g. turn off any visuals that are intended for gameplay only.

#### Hook: End
This hook is optional.

The HeavyLight rendering process has finished, gameplay is now resuming.

#### Method: IsActive
Get whether this module is active in the current HeavyLight stack.

#### Hook: IsAvailable
This hook is optional, and by default always returns `true`.

Return whether this module is available to be made active.

#### Item: AddToMenu
Similar to the TOOL structure, set this to `false` to make the module not appear on the menu.

#### Hook-like: BuildCPanel
This element is required if AddToMenu is not `false`.

Works exactly like TOOL's BuildCPanel function. It's a function with one parameter, the ControlPanel (DForm) to which you can add controls. The 'self' argument isn't provided! See TOOL definitions for examples.

Notably, the top HeavyLight UI will already be added when this function is called, and your custom UI will be insterted below.

### HeavyLightIterativeBase
Derived from HeavyLightBase, parent to HeavyLightModule and HeavyLightRenderer - both can be iterative.


### HeavyLightModule
#### Method: GetPlace
Get the module's position in the current HeavyLight stack, starting at 1 for the outer-most module. If the module is not in the stack (e.g. IsActive() is false), returns `false`.


Types of HeavyLight modules:

1. Multipliers - modules that change something in the world or something in the camera view before each render. Examples: soft lamps, Super DOF
2. Blender - sets the render target, calls the renderer and takes care of blending the results. Examples: Default (with anti-aliasing), Floating-Point Texture (with better HDR), or each of the above with additive blending.
3. Renderer/Render Multiplier - modules that render the scene, possibly in a nonstandard way. Examples: soft lamps godrays, good old RenderView.

HeavyLightBase - base metatable that all others inherit from:
SetParent: add an object when an IsValid method that, when it becomes invalid, means the module should be removed. This is optional. Set to nil to unset.
GetParent: gets the previously set parent, or nil if there is none.
Start (hook): basically says "get out of the way and/or prep to be called", will be called for ALL modules regardless if they are active (in the stack) or not, with probably a parameter to indicate whether they are.
Finish (hook): HeavyLight is done, return to gameplay.
IsActive: gets whether the module is selected. Implemented per
TODO: settings, panels, etc

HeavyLightBlender - handles the render target mess:
TO DO (this will be tricky to define)
Finalize (hook): we are all done, put the actual result on the screen to be saved.
Preview (hook):

HeavyLightIterativeBase - middle class for renderers and modules
SetPassesCount: sets how many iterations I expect to make. This is not binding, it's only an estimate, and it can be updated whenever.
GetPassesCount: gets the previously set length. 1 by default.

HeavyLightRenderer - module that renders the scene to the active render target:
New (hook): this is a new scene, if you need to clean it up in some way, do it now.
Render (hook): render the scene. *Should* have a guarantee that the render target remains unmodified and is always the same one between calls. Return true when done, or false to signal that you were done.

HeavyLightModule - modifies something in the world or the view when called:
Tick (hook): make your change for the next iteration. Return true to confirm, or false to signal that you are all done.
GetIndex: this module's position in the stack, or nil if it's not in the stack
