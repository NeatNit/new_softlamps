print("\nRenderer file running! RENDERER:")
PrintTable(RENDERER)
print("\n***********************************\n")

RENDERER.PrintName = "My First Renderer"

function RENDERER.BuildCPanel(cpanel)
	cpanel:Help("This is the renderer's context menu!")
end

function RENDERER:Run(data, view)
	view.origin = Vector(0, 0, 0)
	render.RenderView(view)
end
