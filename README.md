# Classes

## HeavyLightBase
All HeavyLight addons are derived from this class.

### Item: Name
(string) Nice name which will appear in the menu. This can use language strings.

### Item: Icon
(string) A 64x64 icon to disaplay. Defaults to the "<filename>.png".

### Item: BuildCPanel(cpanel)
This element is required.

Works exactly like TOOL's BuildCPanel function. It's a function with one parameter, the ControlPanel (DForm) to which you can add controls. The 'self' argument isn't provided! See TOOL definitions for examples.

Notably, the top HeavyLight UI will already be added when this function is called, and your custom UI will be insterted below.

### Hook: Start(info)
This hook is optional.

The HeavyLight rendering is beginning, perform any preperations necessary - e.g. turn off any visuals that are intended for gameplay only.

Return `false, reason` to cancel the operation, where `reason` is a string explaining why (shown to the user).

Argument: *info* - Table of:
- \["stack"] - array of active modules, in order from outermost to innermost
- \["renderer"] - active renderer
- \["blender"] - active blender

### Hook: End(info)
This hook is optional.

The HeavyLight rendering process has finished, gameplay is now resuming.

Argument: *info* - Table of:
- \["stack"] - array of active modules, in order from outermost to innermost
- \["renderer"] - active renderer
- \["blender"] - active blender

### Hook: MenuOpened
This hook is optional.

Gets called every time the user switches from a different module menu to this module's menu.

### Hook: IsAvailable
This hook is optional, and by default always returns `true`.

Return whether this module is available to be made active. When returning false, you can (and should) provide a second return value, a string explaining to the user why this isn't available.

### Method: SetAvailable(available, reason)
This overwrites IsAvailable with a function that always returns the values you specify.

Arguments:
- (boolean) *available* - whether the module is available.
- (optional string) *reason* - if false, explain (to the user) why this isn't available. This may be a language string.

### Method: IsActive
Get whether this module is active in the current HeavyLight stack.

## HeavyLightIterativeBase
Derived from HeavyLightBase, parent of HeavyLightModule and HeavyLightRenderer - both can be iterative.

### Method: SetPassesCount(count)
Argument: (non-negative integer) *count* - number of passes (iterations) this element will create.

This is 1 by default. If set to 1, it's not actually iterative (there's just 1 iteration) and it will not get a progress bar at the bottom of the screen when used.

Set it to 0 to say "I don't know and I'll tell you in real-time".

### Method: GetPassesCount
Returns the value set by SetPassesCount.

### Method: GetCurrentPass
Gets which pass this is for this module. Starts at 1, ends at GetPassesCount(). Returns 0 if there is no active pass (e.g. HeavyLight isn't running, this module is not in the stack, or this module is deeper down in the stack than the code currently running).

### Hook: Run(view, info, pass, outof)
Run your code, do your thing! A renderer is expected to draw to the active render target. A module is expected to change something in the world or in the view.

Arguments:
- *view* - [ViewData structure](http://wiki.garrysmod.com/page/Structures/ViewData) with some of the more basic fields already filled in. You can modify this view and any changes will propagate forwards (deeper) into the stack, but not backwards. (Each module's view is basically derived from the previous module's view)
- *info* - same as in the hooks Start and End.
- *pass* - equal to `self:GetCurrentPass()`.
- *outof* - equal to `self:GetPassesCount()`.

## HeavyLightModule
### Method: Activate(place)
Insert the module into the stack. After this, IsActive will be true.

Throws an error if IsAvailable returns false.

Argument: (optional integer) *place* - where in the stack to insert this module (later returned by GetPlace). If not provided or is larger than the number of active modules, it will be inserted as the last (deepest) module.

### Method: Deactivate
Remove the module from the stack. After this, IsActive will be false.
If the module is not in the stack, does nothing.

### Method: GetPlace
Get the module's position in the current HeavyLight stack, starting at 1 for the outer-most module. If the module is not in the stack (e.g. IsActive() is false), returns `false`.

## HeavyLightRenderer
### Method: Activate
Set this as the active Renderer for any upcoming HeavyLight renders. After this, IsActive will be true.

Throws an error if IsAvailable returns false.

Note that the only way to become inactive afterwards is when another renderer is activated. If IsAvailable becomes `false` while active, HeavyLight will not allow the user to start a render until a different renderer is selected or IsAvailable becomes true again.


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
