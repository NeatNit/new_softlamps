
--[[-------------------------------------------------------------------------
Repeatedly used stuff
---------------------------------------------------------------------------]]
local DoNothing = function() end -- used a bunch of times


--[[-------------------------------------------------------------------------
Blenders, Modules and Renderers repositories.
	Key = name (filename)
	Value = actual module object
---------------------------------------------------------------------------]]
local Modules = {}
local Renderers = {}
local Blenders = {}


--[[-------------------------------------------------------------------------
Info - Current stack settings. Can be acquired with
	heavylight.GetCurrentSettings(). Table of:
	["modules"] - array of active modules, in order from outermost to innermost
		also module name keys which indicate that module's index in the stack,
			nil if it's not in the stack
	["renderer"] - active renderer
	["blender"] - active blender
	["poster"] - table of:
		["size"] - poster size
		["pass"] - current pass (in Start or End, will always be nil)
		["total"] - total passes, equal to size suared
---------------------------------------------------------------------------]]
local Info = {
	modules = {},

	poster = {
		size = 1,
		total = 1
	}
}





--[[-------------------------------------------------------------------------
HeavyLightBase
================
Base class - all modules derive from this
---------------------------------------------------------------------------]]
local HeavyLightBase = {}
HeavyLightBase.__index = HeavyLightBase
debug.getregistry().HeavyLightBase = HeavyLightBase

--[[-------------------------------------------------------------------------
Start (hook) - 'Get out of the way'. Called for ALL existing modules when
	rendering starts.
param: info - see Info at the top of this file
---------------------------------------------------------------------------]]
HeavyLightBase.Start = DoNothing -- by default

--[[-------------------------------------------------------------------------
End (hook) - HeavyLight finished completely.
param: info - see Info at the top of this file
---------------------------------------------------------------------------]]
HeavyLightBase.End = DoNothing -- by default

--[[-------------------------------------------------------------------------
Reset (hook) - For Modules and the Renderer, called when they need to prepare
	for another go after they've finished their last Run - e.g. when using
	SoftLamps under SuperDoF, SoftLamps will be Reset every time it's done
	and SuperDoF will be run once.

	For the Blender, it acts similarly with poster being the parent.
---------------------------------------------------------------------------]]
function HeavyLightBase:Reset(info)
	self:Start(info)
end

--[[-------------------------------------------------------------------------
MenuOpened (hook) - Gets called every time the user switches from a different
	module menu to this module's menu.
---------------------------------------------------------------------------]]
HeavyLightBase.MenuOpened = DoNothing

--[[-------------------------------------------------------------------------
IsAvailable (hook) - Return whether this module is available to be made
	active. When returning false, you can (and should) provide a second
	return value, a string explaining to the user why this isn't available.
---------------------------------------------------------------------------]]
function HeavyLightBase:IsAvailable()
	return true
end

--[[-------------------------------------------------------------------------
SetAvailable (method) - This overwrites IsAvailable with a function that
	always returns the values you specify.
params:
	(boolean) available - whether the module is available.
	(optional string) reason - if false, explain (to the user) why this isn't available. This may be a language string.
---------------------------------------------------------------------------]]
function HeavyLightBase:SetAvailable(available, reason)
	if reason then
		function self:IsAvailable()
			return available, reason
		end
	else
		function self:IsAvailable()
			return available
		end
	end
end

--[[-------------------------------------------------------------------------
IsActive (method) - Get whether this module is active in the current
	HeavyLight stack. This is implemented per
---------------------------------------------------------------------------]]
function HeavyLightBase:IsActive()
	error("This should be overwritten by child classes!")
end

--[[-------------------------------------------------------------------------
Activated (hook) - Called when the module has been activated.

Arguments:
	Info - new info, see top of this file
	Place - HeavyLightModules will get their new place in the stack
---------------------------------------------------------------------------]]
HeavyLightBase.Activated = DoNothing

--[[-------------------------------------------------------------------------
Deactivated (hook) - Called when the module has been removed from the stack.

Argument: info - new info, see top of this file
---------------------------------------------------------------------------]]
HeavyLightBase.Deactivated = DoNothing




--[[-------------------------------------------------------------------------
HeavyLightBlender
==================
Blender class. For now, this doesn't really have any functions, just
hooks.
---------------------------------------------------------------------------]]
local HeavyLightBlender = setmetatable({}, HeavyLightBase)
HeavyLightBlender.__index = HeavyLightBlender
debug.getregistry().HeavyLightBlender = HeavyLightBlender

--[[-------------------------------------------------------------------------
Activate (method) Set this as the active Blender for any upcoming HeavyLight
	renders. After this, IsActive will be true.

	Note that the only way to become inactive afterwards is when another
	blender is activated. If IsAvailable is false while active,
	HeavyLight will not allow the user to start a render until a different
	blender is selected or IsAvailable becomes true again.
---------------------------------------------------------------------------]]
function HeavyLightBlender:Activate()
	heavylight.SetActiveBlender(self)
end

--[[-------------------------------------------------------------------------
IsActive
---------------------------------------------------------------------------]]
function HeavyLightBlender:IsActive()
	return heavylight.GetCurrentSettings().blender == self
end

--[[-------------------------------------------------------------------------
PreRender (hook) - Optional. Called just before the renderer runs. You may
	want to render.PushRenderTarget something.

param: info (see top of this file)
---------------------------------------------------------------------------]]
HeavyLightBlender.PreRender = DoNothing

--[[-------------------------------------------------------------------------
PostRender (hook) - Required. Called just after the renderer runs.

	You should process the rendered image and save it in some way, because if
	it gets overwritten in a moment, you didn't accomplish anything.

	If you pushed a render target in PreRender, you should pop it here.
---------------------------------------------------------------------------]]


--[[-------------------------------------------------------------------------
Preview (hook) - Required. Called after PostRender when we want to show a
	preview on the screen. Not necessarily called every time!

	Draw something to th screen to show the user progress. Draw progress bars
	somewhere of the screen - if you don't need custom progress bars
	(which 99% of the time, you really don't), you can call the heavylight
	library's function to draw them for you.
---------------------------------------------------------------------------]]


--[[-------------------------------------------------------------------------
Finalize (hook) - Called after the last PostRender, and should draw on the
	screen the final image, the blend of all the renders so far.
---------------------------------------------------------------------------]]








--[[-------------------------------------------------------------------------
HeavyLightIterativeBase
=======================
Adds the iterative functionality of both modules and
---------------------------------------------------------------------------]]
local HeavyLightIterativeBase = setmetatable({}, HeavyLightBase)
HeavyLightIterativeBase.__index = HeavyLightIterativeBase
debug.getregistry().HeavyLightIterativeBase = HeavyLightIterativeBase

--[[-------------------------------------------------------------------------
Set/GetPassesCount - sets/gets the number of iterations this module
	expects to make. This is not binding.
---------------------------------------------------------------------------]]
AccessorFunc(HeavyLightIterativeBase, "_passes", "PassesCount", FORCE_NUMBER)
HeavyLightIterativeBase:SetPassesCount(1) -- default

--[[-------------------------------------------------------------------------
GetCurrentPass - Gets which pass this is for this module. Starts at 1, ends
	at GetPassesCount(). Returns 0 if there is no active pass
	(e.g. HeavyLight isn't running, this module is not in the stack, or this
	module is deeper down in the stack than the code currently running).

Note: SetCurrentPass is internal!!
---------------------------------------------------------------------------]]
AccessorFunc(HeavyLightIterativeBase, "_pass", "CurrentPass", FORCE_NUMBER)
HeavyLightIterativeBase:SetCurrentPass(0) -- default

--[[-------------------------------------------------------------------------
Run (hook) - Run your code, do your thing! A renderer is expected to draw to
	the active render target. A module is expected to change something in the
	world or in the view.

Arguments:
	view - ViewData structure with some of the more basic fields already
		filled in. You can modify this view and any changes will propagate
		forwards (deeper) into the stack, but not backwards. (Each module's
		view is basically derived from the previous module's view)

		Has one extra key - "weight" - which determines basically the
		weight of this frame. Default is 1. Depends on the Blender's
		implementation.
	info - see top of this file
	pass - equal to self:GetCurrentPass().
	outof - equal to self:GetPassesCount().

Return values: If SetPassesCount was set to 0, or for any reason the set
	count is no longer true, the following return values are needed:

	1. (number) passes_remaining - how many passes after this one the module
		expects to make. In particular, the sign of this number is
		interpreted as:
			Negative: "I didn't actually do anything, I was done on the
				previous iteration - act as if the previous iteration
				returned zero" (I don't know how your module is built, maybe
				you couldn't know this in advance)
			Zero: "This is my last iteration, do not call Run again"
			Positive: "There are more iterations to follow"
	2. (optional number) progress - number between 0 and 1, how much to
		visually fill the progress bar
		(default: pass/(pass + passes_remaining))
	3. (optional string) progress_text - text to display on the progress bar
		(default: pass .. "/" .. (pass + passes_remaining))
---------------------------------------------------------------------------]]








--[[-------------------------------------------------------------------------
HeavyLightRenderer
==================
Renderer module class. The simplest one just uses render.RenderView, another
	one can render just a single entity or a group or entities, or do
	something entirely different altogether.
	For now, this doesn't really have any functions, just hoooks.
---------------------------------------------------------------------------]]
local HeavyLightRenderer = setmetatable({}, HeavyLightIterativeBase)
HeavyLightRenderer.__index = HeavyLightRenderer
debug.getregistry().HeavyLightRenderer = HeavyLightRenderer

--[[-------------------------------------------------------------------------
Activate - Set this as the active Renderer for any upcoming HeavyLight
	renders. After this, IsActive will be true.

	Note that the only way to become inactive afterwards is when another
	renderer is activated. If IsAvailable is false while active, HeavyLight
	will not allow the user to start a render until a different renderer is
	selected or IsAvailable becomes true again.
---------------------------------------------------------------------------]]
function HeavyLightBlender:Activate()
	heavylight.SetActiveRenderer(self)
end

--[[-------------------------------------------------------------------------
IsActive
---------------------------------------------------------------------------]]
function HeavyLightRenderer:IsActive()
	return heavylight.GetCurrentSettings().renderer == self
end







--[[-------------------------------------------------------------------------
HeavyLightModule
================
Module that can be part of the stack, like Soft Lamps or SuperDOF. They can
	change something in the world or in the view.

	See HeavyLightIterativeBase:Run for details.
---------------------------------------------------------------------------]]
local HeavyLightModule = setmetatable({}, HeavyLightIterativeBase)
HeavyLightModule.__index = HeavyLightModule
debug.getregistry().HeavyLightModule = HeavyLightModule

--[[-------------------------------------------------------------------------
Activate - Insert the module into the stack. After this, IsActive will be
	true.

Argument: (optional integer) place - where in the stack to insert this module
	(later returned by GetPlace). If not provided or is larger than the
	number of active modules, it will be inserted as the last (deepest)
	module.
---------------------------------------------------------------------------]]
function HeavyLightModule:Activate(place)
	heavylight.ActivateModule(self, place)
end

--[[-------------------------------------------------------------------------
Deactivate - Remove the module from the stack. After this, IsActive will be
	false. If the module is not in the stack, does nothing.
---------------------------------------------------------------------------]]
function HeavyLightModule:Deactivate()
	heavylight.DeactivateModule(self)
end

--[[-------------------------------------------------------------------------
GetPlace - Get the module's position in the current HeavyLight stack,
	starting at 1 for the outer-most module. If the module is not in the
	stack (e.g. IsActive() is false), returns nil.

	Possibly rename this to GetIndex? It sounds more professional, but it
	also sounds like a more "permenant" thing rather than the changing nature
	of the stack. I also think "its place in the stack" sounds more correct
	than "its index in the stack".

	Whatever.
---------------------------------------------------------------------------]]
function HeavyLightModule:GetPlace()
	return heavylight.GetModulePlace(self)
end









--[[-------------------------------------------------------------------------
Load Modules
---------------------------------------------------------------------------]]
local mods = file.Find("lua/heavylight/modules/*.lua", "GAME")
for _, modfile in ipairs(mods) do
	-- Create a new module
	MODULE = setmetatable({}, HeavyLightModule)

	-- Define its basic parameters
	local name = string.sub(modfile, 1, -5) -- remove the extension
	MODULE.Name = name
	MODULE.PrintName = name -- default
	MODULE.Icon = "heavylight/modules/" .. name .. ".png"

	-- Run the file
	include("heavylight/modules/" .. modfile)

	-- Add to our internal list
	Modules[name] = MODULE
end

--[[-------------------------------------------------------------------------
Load Renderers
---------------------------------------------------------------------------]]
local rends = file.Find("lua/heavylight/renderers/*.lua", "GAME")
for _, rendfile in ipairs(rends) do
	-- Create a new module
	RENDERER = setmetatable({}, HeavyLightRenderer)

	-- Define its basic parameters
	local name = string.sub(rendfile, 1, -5) -- remove the extension
	RENDERER.Name = name
	RENDERER.PrintName = name
	RENDERER.Icon = "heavylight/renderers/" .. name .. ".png"

	-- Run the file
	include("heavylight/renderers/" .. rendfile)

	-- Add to our internal list
	Renderers[name] = RENDERER
end

--[[-------------------------------------------------------------------------
Load Blenders
---------------------------------------------------------------------------]]
local blends = file.Find("lua/heavylight/blenders/*.lua", "GAME")
for _, blendfile in ipairs(blends) do
	-- Create a new module
	BLENDER = setmetatable({}, HeavyLightBlender)

	-- Define its basic parameters
	local name = string.sub(blendfile, 1, -5) -- remove the extension
	BLENDER.Name = name
	BLENDER.PrintName = name
	BLENDER.Icon = "heavylight/blenders/" .. name .. ".png"

	-- Run the file
	include("heavylight/blenders/" .. blendfile)

	-- Add to our internal list
	Blenders[name] = BLENDER
end




--[[-------------------------------------------------------------------------
GUI
---------------------------------------------------------------------------]]
local mainui
local function GetMainUI()
	if mainui then return mainui end

	print "creating mainui"

	mainui = vgui.Create("DLabel")
	mainui:SetText("Hello,\nHeavyLight\nWorld!")
	mainui:SetColor(Color(255, 255, 0))
	mainui:SizeToContents()

	return mainui
end



-- Create tool tab and categories
-- (these could be together in one hook but I figured it's nice to have structure)

hook.Add("AddToolMenuTabs", "heavylight", function()
	spawnmenu.AddToolTab("heavylight","HeavyLight", "icon16/asterisk_yellow.png")
end)
hook.Add("AddToolMenuCategories","heavylight",function()
	spawnmenu.AddToolCategory("heavylight", "heavylight_main", "HeavyLight")
	spawnmenu.AddToolCategory("heavylight", "heavylight_modules", "Modules")
	spawnmenu.AddToolCategory("heavylight", "heavylight_renderers", "Renderers")
	spawnmenu.AddToolCategory("heavylight", "heavylight_blenders", "Blenders")
end)

local current_parent = nil
local function AddMainUITo(cpanel)
	cpanel:AddItem(GetMainUI())
	local parent = GetMainUI():GetParent()

	local old_Think = parent.Think or DoNothing

	function parent:Think(...)
		if current_parent ~= self --[[and self:IsVisible() -- Think should guarantee this]] then
			current_parent = self
			GetMainUI():SetParent(self)
			GetMainUI():Dock(TOP)
		end
		return old_Think(self, ...)
	end
end

-- Add actual options:
hook.Add("PopulateToolMenu", "heavylight", function()
	spawnmenu.AddToolMenuOption("heavylight","heavylight_settings", "heavylight_main_ui", "Control", "", nil, function(cpanel)
		AddMainUITo(cpanel)
	end)

	-- Add modules
	for name, mod in pairs(Modules) do
		spawnmenu.AddToolMenuOption("heavylight","heavylight_modules", "heavylight_module_" .. name, mod.PrintName, "", nil, function(cpanel)
			AddMainUITo(cpanel)

			return mod.BuildCPanel(cpanel)
		end)
	end

	-- Add blenders
	for name, blend in pairs(Blenders) do
		spawnmenu.AddToolMenuOption("heavylight","heavylight_blenders", "heavylight_blender_" .. name, blend.PrintName, "", nil, function(cpanel)
			AddMainUITo(cpanel)

			return blend.BuildCPanel(cpanel)
		end)
	end

	-- Add renderers
	for name, rend in pairs(Renderers) do
		spawnmenu.AddToolMenuOption("heavylight","heavylight_blenders", "heavylight_renderer_" .. name, rend.PrintName, "", nil, function(cpanel)
			AddMainUITo(cpanel)

			return rend.BuildCPanel(cpanel)
		end)
	end
end)







--[[-------------------------------------------------------------------------
The HeavyLight Library
---------------------------------------------------------------------------]]
local _G = _G
module("heavylight")

-- function NewModule()
-- 	local m = setmetatable({}, HeavyLightModule)
-- 	Modules[m] = m
-- 	return m
-- end

-- function NewBlender()
-- 	local b = setmetatable({}, HeavyLightBlender)
-- 	Blenders[b] = b
-- 	return b
-- end

-- function NewRenderer()
-- 	local r = setmetatable({}, HeavyLightRenderer)
-- 	Renderers[r] = r
-- 	return r
-- end


local function DoHeavyLightRender()
	local a = true
	hook.Add("RenderScene", "HeavyLight", function()
		if a then a = false return end

		local lamp = ents.FindByClass("hl_softlamp")[1]
		hook.Remove("RenderScene", "HeavyLight")

		mat_copy:SetTexture("$basetexture", tex_scrfx)
		local i = 0
		while lamp:NextPT() do
			i = i + 1
			--render.Clear(255, 255, 255)
			render.RenderView()
			render.UpdateScreenEffectTexture()

			render.PushRenderTarget(tex_blend)
				mat_copy:SetFloat("$alpha", 1 / i)
				render.SetMaterial(mat_copy)
				render.DrawScreenQuad()
			render.PopRenderTarget()
		end

		mat_copy:SetTexture("$basetexture", tex_blend)
		mat_copy:SetFloat("$alpha", 1)
		render.SetMaterial(mat_copy)
		render.DrawScreenQuad()

		return true
	end)

	RunConsoleCommand("poster", 1)
end


