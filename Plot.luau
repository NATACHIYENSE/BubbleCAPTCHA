--!strict

--[[
	A coroutine iterator to generate quasirandom points in a rectangle.
]]

local function generatePlane(from: Vector3, to: Vector3, seed: number, offset: number?): () -> (number, Vector3)
	return coroutine.wrap(function()
		local r: Random = Random.new(seed)
		local offset: number = offset or .5
		local counter: number = 0
		
		for x = from.X, to.X do
			for z = from.Z, to.Z do
				counter += 1
				local angle: number = r:NextNumber()*math.pi*2
				coroutine.yield(
					counter,
					Vector3.new(
						x + math.cos(angle)*offset,
						0,
						z + math.sin(angle)*offset
					)
				)
			end
		end
	end)
end

local module = {
	GeneratePlane = generatePlane,
}

return module
