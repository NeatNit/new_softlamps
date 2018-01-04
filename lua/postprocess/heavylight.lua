local DoNothing = function() end -- used a bunch of times

--[[-------------------------------------------------------------------------
HeavyLightModule
================
Base class - all modules derive from this
---------------------------------------------------------------------------]]
local HeavyLightModule = {}
HeavyLightModule.__index = HeavyLightModule
debug.getregistry().HeavyLightModule = HeavyLightModule

--[[-------------------------------------------------------------------------
Set/GetParent - sets/gets a parent entity (or other object) so the module gets
	automatically removed when it's found to be invalid. This is optional.
---------------------------------------------------------------------------]]
local parent = {} -- private key
function HeavyLightModule:SetParent(p)
	if not p.IsValid then error("Attempt to set a parent without an IsValid fuction!") end
	self[parent] = p
end
function HeavyLightModule:GetParent()
	return self[parent]
end

--[[-------------------------------------------------------------------------
Set/GetPassesCount - sets/gets the number of iterations this module
	expects to make. This is not binding.
---------------------------------------------------------------------------]]
local passes = {} -- private key
HeavyLightModule[passes] = 1 -- defaults
function HeavyLightModule:SetPassesCount(p)
	self[passes] = p
end
function HeavyLightModule:GetPassesCount()
	return self[passes]
end

--[[-------------------------------------------------------------------------
Start (hook) - 'Get out of the way'. Called for ALL existing modules when
	rendering starts.
param: HeavyLightStackStructure
---------------------------------------------------------------------------]]
HeavyLightModule.Start = DoNothing -- by default

--[[-------------------------------------------------------------------------
New (hook) - notification that this is a new scene (view changed or something
	in the world changed).
param: HeavyLightStackStructure
---------------------------------------------------------------------------]]
HeavyLightModule.New = DoNothing -- by default
--[[ examples:

-- a renderer module might need to clear the screen before ticking:
function some_rendering_module:New(stack)
	render.Clear(0, 0, 0, 255)
end

-- a stack module might reset some internal variables or prep stuff:
function some_stack_module:New(stack)
	self:GetParent():PrepareForHeavyLightTick()
end
]]

--[[-------------------------------------------------------------------------
Finish (hook) - HeavyLight finished completely.
param: HeavyLightStackStructure
---------------------------------------------------------------------------]]
HeavyLightModule.Finish = DoNothing -- by default



--[[-------------------------------------------------------------------------
HeavyLightRenderer
==================
Renderer module class. For now, this doesn't really have any functions, just
hoooks.
---------------------------------------------------------------------------]]
local HeavyLightRenderer = setmetatable({}, HeavyLightModule)
HeavyLightRenderer.__index = HeavyLightRenderer
debug.getregistry().HeavyLightRenderer = HeavyLightRenderer

--[[-------------------------------------------------------------------------
Render (hook) - called when stuff needs to be rendered.
param: view - ViewData structure
	http://wiki.garrysmod.com/page/Structures/ViewData
---------------------------------------------------------------------------]]
--[[ example:
function HeavyLightRenderer:New(view)
	render.RenderView(view)
end ]]




--[[-------------------------------------------------------------------------
HeavyLightBlender
==================
Renderer module class. For now, this doesn't really have any functions, just
hoooks.
---------------------------------------------------------------------------]]
local HeavyLightBlender = setmetatable({}, HeavyLightModule)
HeavyLightBlender.__index = HeavyLightBlender
debug.getregistry().HeavyLightBlender = HeavyLightBlender





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

local PANEL = {}

local HeavyLightWindow = nil

function PANEL:Init()
	self:SetTitle("HeavyLight")
	self:SetSize( 600, 220)

	self.ActionButtonsPanel = vgui.Create("DPanel", self)

	self.StartButton = vgui.Create("DButton", self.ActionButtonsPanel)
	self.StartButton:SetText("Test Button")
	self.StartButton.DoClick = DoHeavyLightRender

	self.ActionButtonsPanel:Dock(FILL)
end

PANEL = vgui.RegisterTable(PANEL, "DFrame")

concommand.Add("hl_openwindow", function()
	if IsValid(HeavyLightWindow) then
		print "Deleting old window"
		HeavyLightWindow:Remove()
	end

	print "Creating new window"
	HeavyLightWindow = vgui.CreateFromTable(PANEL)

	HeavyLightWindow:AlignBottom(50)
	HeavyLightWindow:CenterHorizontal()
	HeavyLightWindow:MakePopup()
end)

list.Set("PostProcess", "HeavyLight", {
	icon = "gui/postprocess/superdof.png",
	category = "#effects_pp",
	onclick = function() RunConsoleCommand("hl_openwindow") end
})
