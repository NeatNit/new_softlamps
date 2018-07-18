--[[-------------------------------------------------------------------------
Blenders, Modules and Renderers repositories. These should basically just be
lists, but for easier adding and removing, they will be [module] = module
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
Set/GetName - friendly name / title
---------------------------------------------------------------------------]]
AccessorFunc(HeavyLightBase, "_name", Name, FORCE_STRING)

--[[-------------------------------------------------------------------------
Set/GetParent - sets/gets a parent entity (or other object) so the module gets
	automatically removed when it's found to be invalid. This is optional.
---------------------------------------------------------------------------]]
function HeavyLightBase:SetParent(p)
	if not p.IsValid then error("Attempt to set a parent without an IsValid fuction!") end
	self._parent = p
end
function HeavyLightBase:GetParent()
	return self._parent
end

--[[-------------------------------------------------------------------------
Start (hook) - 'Get out of the way'. Called for ALL existing modules when
	rendering starts.
param: HeavyLightStackStructure
---------------------------------------------------------------------------]]
HeavyLightBase.Start = DoNothing -- by default

--[[-------------------------------------------------------------------------
New (hook) - notification that this is a new scene (view changed or something
	in the world changed).
param: HeavyLightStackStructure
---------------------------------------------------------------------------]]
HeavyLightBase.New = DoNothing -- by default
--[[ examples:

-- a renderer might need to clear the screen before ticking:
function some_renderer:New(stack)
	render.Clear(0, 0, 0, 255)
end

-- a module might reset some internal variables or prep stuff:
function some_module:New(stack)
	self:GetParent():PrepareForHeavyLightTick()
end
]]


--[[-------------------------------------------------------------------------
Finish (hook) - HeavyLight finished completely.
param: HeavyLightStackStructure
---------------------------------------------------------------------------]]
HeavyLightBase.Finish = DoNothing -- by default





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


-- Add actual options:
hook.Add("PopulateToolMenu", "heavylight", function()
	spawnmenu.AddToolMenuOption("heavylight","heavylight_main", "heavylight_main_ui", "Control", "", nil, function(cpanel)
		print(cpanel)
		cpanel:AddItem(GetMainUI())
		print(GetMainUI():GetParent())
	end)
end)
