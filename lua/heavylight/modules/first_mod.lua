print("\nModule file running! MODULE:")
PrintTable(MODULE)
print("\n***********************************\n")

MODULE.PrintName = "My first module"

function MODULE.BuildCPanel(cpanel)
	cpanel:Help("This is the module's context menu!")
end
