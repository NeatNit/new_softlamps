print("\nBlender file running! BLENDER:")
PrintTable(BLENDER)
print("\n***********************************\n")

BLENDER.PrintName = "My first blender"

function BLENDER.BuildCPanel(cpanel)
	cpanel:Help("This is the blender's context menu!")
end
