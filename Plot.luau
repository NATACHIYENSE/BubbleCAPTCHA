--!strict

--[[
	A coroutine iterator to generate quasirandom points in a rectangle.
]]

local function generatePlane(from: Vector3, to: Vector3, random: Random, offset: number?, rot: CFrame?): () -> (number, Vector3)
	return coroutine.wrap(function()
		local offset: number = offset or random:NextNumber(0.25, 0.75) --radial offset from grid position
		local rot: CFrame = rot or CFrame.Angles(0, random:NextNumber(-0.1, 0.1), 0) --global orientation of the entire grid
		local counter: number = 0
		
		for x = from.X, to.X do
			for z = from.Z, to.Z do
				counter += 1
				local angle: number = random:NextNumber(0, math.pi*2)
				local pos: Vector3 = Vector3.new(
						x + math.cos(angle)*offset,
						0,
						z + math.sin(angle)*offset
					)
				coroutine.yield(counter, rot:PointToWorldSpace(pos))
			end
		end
	end)
end

local module = {
	GeneratePlane = generatePlane,
}

return module
