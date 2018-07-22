
--[[-------------------------------------------------------------------------
Blenders, Modules and Renderers repositories.
---------------------------------------------------------------------------]]
local Modules = {}
local Blenders = {}
local Renderers = {}

local DoNothing = function() end -- used a bunch of times

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
param: info
---------------------------------------------------------------------------]]
HeavyLightBase.Start = DoNothing -- by default

--[[-------------------------------------------------------------------------
End (hook) - HeavyLight finished completely.
param: info - Table of:
	["stack"] - array of active modules, in order from outermost to innermost
	["renderer"] - active renderer
	["blender"] - active blender
	["poster"] - table of:
		["size"] - poster size
		["pass"] - current pass (in Start or End, will always be nil)
		["total"] - total passes, equal to size suared
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
HeavyLightBlender
==================
Blender class. For now, this doesn't really have any functions, just
hooks.
---------------------------------------------------------------------------]]
local HeavyLightBlender = setmetatable({}, HeavyLightBase)
HeavyLightBlender.__index = HeavyLightBlender
debug.getregistry().HeavyLightBlender = HeavyLightBlender







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
AccessorFunc(HeavyLightBase, "_passes", "PassesCount", FORCE_NUMBER)
HeavyLightBase:SetPassesCount(1) -- default





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

function HeavyLightRenderer:IsActive()
	error("to do")
end







--[[-------------------------------------------------------------------------
HeavyLightModule
================
Module that can be part of the stack, like Soft Lamps or SuperDOF. They can
	change something in the world or
---------------------------------------------------------------------------]]
local HeavyLightModule = setmetatable({}, HeavyLightIterativeBase)
HeavyLightModule.__index = HeavyLightModule
debug.getregistry().HeavyLightModule = HeavyLightModule



--[[-------------------------------------------------------------------------
Load modules
---------------------------------------------------------------------------]]
local mods, b = file.Find("lua/heavylight/*.lua", "GAME")
for _, mod in ipairs(mods) do
	include("heavylight/" .. mod)
end



--[[-------------------------------------------------------------------------
GUI
---------------------------------------------------------------------------]]

--[[ OLD (copied from SuperDOF):
local PANEL = {}

local HeavyLightWindow = nil

function PANEL:Init()
	self:SetTitle("HeavyLight")
	self:SetSize( 600, 220)

	self.ActionButtonsPanel = _G.vgui.Create("DPanel", self)

	self.StartButton = _G.vgui.Create("DButton", self.ActionButtonsPanel)
	self.StartButton:SetText("Test Button")
	self.StartButton.DoClick = DoHeavyLightRender

	self.ActionButtonsPanel:Dock(FILL)
end

PANEL = _G.vgui.RegisterTable(PANEL, "DFrame")

_G.concommand.Add("hl_openwindow", function()
	if _G.IsValid(HeavyLightWindow) then
		_G.print "Deleting old window"
		HeavyLightWindow:Remove()
	end

	_G.print "Creating new window"
	HeavyLightWindow = _G.vgui.CreateFromTable(PANEL)

	HeavyLightWindow:AlignBottom(50)
	HeavyLightWindow:CenterHorizontal()
	HeavyLightWindow:MakePopup()
end)

_G.list.Set("PostProcess", "HeavyLight", {
	icon = "gui/postprocess/superdof.png",
	category = "#effects_pp",
	onclick = function() _G.RunConsoleCommand("hl_openwindow") end
})
]]

-- New, and atm just proof of concept:
local mainui
local function GetMainUI()
	if mainui then return mainui end

	print "creating mainui"

	mainui = vgui.Create("DLabel")
	mainui:SetText("Hello,\nHeavyLight\nWorld!")
	mainui:SetColor(Color(255, 0, 0))
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
local function SetAutoDockTo(parent)
	local old_Think = type(parent.Think) == "function" and parent.Think or DoNothing

	function parent:Think(...)
		if current_parent ~= self --[[and self:IsVisible() -- Think should guarantee this]] then
			current_parent = self
			GetMainUI():SetParent(self)
			GetMainUI():Dock(TOP)
		end
		old_Think(self, ...)
	end
end

-- Add actual options:
hook.Add("PopulateToolMenu", "heavylight", function()
	spawnmenu.AddToolMenuOption("heavylight","heavylight_main", "heavylight_main_ui", "Control", "", nil, function(cpanel)
		cpanel:AddItem(GetMainUI())
		local parent = GetMainUI():GetParent()

		SetAutoDockTo(parent)
	end)

	spawnmenu.AddToolMenuOption("heavylight","heavylight_modules", "heavylight_superdof", "SuperDOF", "", nil, function(cpanel)
		cpanel:AddItem(GetMainUI())
		local parent = GetMainUI():GetParent()

		SetAutoDockTo(parent)
	end)
end)





--[[-------------------------------------------------------------------------
The HeavyLight Library
---------------------------------------------------------------------------]]
local _G = _G
module("heavylight")

function NewModule()
	local m = setmetatable({}, HeavyLightModule)
	Modules[m] = m
	return m
end

function NewBlender()
	local b = setmetatable({}, HeavyLightBlender)
	Blenders[b] = b
	return b
end

function NewRenderer()
	local r = setmetatable({}, HeavyLightRenderer)
	Renderers[r] = r
	return r
end


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


