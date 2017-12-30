include("shared.lua")


function ENT:Initialize()
	-- Create Projected Texture
	self.PT = ProjectedTexture()
	self.PT:SetColor(Color(255, 255, 255))
	self.PT:SetBrightness(3)
	self.PT:SetEnableShadows(true)
	self.PT:SetNearZ(20)
	self.PT:SetFarZ(1000)
	self.PT:SetTexture("effects/flashlight/square")
	self.PT:SetPos(self:GetPos())
	self.PT:SetAngles(self:GetAngles())
	self.PT:Update()

	-- internal state
	self.state = {
		ptindex = 0
	}
end


function ENT:CalcAbsolutePosition(pos, ang)
	-- Whenever the entity moves, update the position of the projected texture.
	self.PT:SetPos(pos)
	self.PT:SetAngles(ang)
	self.PT:Update()
end

local ptindex_pos = {
	Vector(0, -1,  3),
	Vector(0,  1,  3),
	Vector(0, -3,  1),
	Vector(0, -1,  1),
	Vector(0,  1,  1),
	Vector(0,  3,  1),
	Vector(0, -3, -1),
	Vector(0, -1, -1),
	Vector(0,  1, -1),
	Vector(0,  3, -1),
	Vector(0, -1, -3),
	Vector(0,  1, -3),
}
function ENT:NextPT()
	self.state.ptindex = self.state.ptindex + 1
	local ptpos = ptindex_pos[self.state.ptindex]
	if ptpos == nil then
		self.state.ptindex = 0
		self.PT:SetPos(self:GetPos())
		self.PT:Update()
		return false
	end

	self.PT:SetPos(self:LocalToWorld(ptpos * 10))
	self.PT:Update()

	return true
end


function ENT:OnRemove()
	if IsValid(self.PT) then self.PT:Remove() end
end
