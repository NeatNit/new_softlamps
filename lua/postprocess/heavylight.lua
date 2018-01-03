local _G = _G
module("heavylight")

local renderer_meta = {}

function NewRenderer()
	return setmetatable({}, renderer_meta)
end

local tex_scrfx = render.GetScreenEffectTexture()
local tex_blend = GetRenderTarget("HeavyLightYay", ScrW(), ScrH(), false)
local mat_copy = Material("pp/copy")

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
