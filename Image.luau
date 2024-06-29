--!strict
--[[
	Functions for drawing and rendering the generated images.
	Things in here are a bit hardcoded, but it shouldn't be too difficult to customize.
	If you do change things, pay special attention to the size of the buffers.
	
	fillQuota is the guarantee for the minimum number of shaded bubbles.
	The draw function generates the image encoded as two buffers (an "Image" type).
	The render function uses the two buffers to generate a WorldModel containing the image.
]]

local main = script.Parent
local T = require(main:WaitForChild('Types'))
local CharMap = require(script:WaitForChild('CharMap'))
local SegSpherInter = require(script:WaitForChild('SegSpherInter'))
local Plot = require(script:WaitForChild('Plot'))

local imageQuadrantSize: number = 12
local fillQuota: number = 240

local imageArea: number = (imageQuadrantSize*2+1)^2
local imageDimMin: Vector3 = Vector3.one*-imageQuadrantSize
local imageDimMax: Vector3 = Vector3.one*imageQuadrantSize

local function draw(char: T.Char, random: Random?): T.Image
	local rand: Random = random or Random.new(tick())
	local rot: CFrame = CFrame.Angles(-math.pi/2, 0, rand:NextNumber()-.5)
	local points: {Vector3} = CharMap.Transform(rot, assert(CharMap.CharMap[char], `character "{char}" isn't defined`), 5)
	
	local grid: buffer = buffer.create(imageArea * 3 * 4) --size of grid * 3 components in each vector * 4 bytes in f32
	local dyed: {number} = {}
	local dyedHash: {[number]: true} = {}
	for i, pos in Plot.GeneratePlane(imageDimMin, imageDimMax, Random.new(tick()*rand:NextInteger(0, 12_345)%123_456)) do
		
		local b: number = i * 12
		buffer.writef32(grid, b-12, pos.X)
		buffer.writef32(grid, b-8, pos.Y + rand:NextNumber(-5, 5)) --add some randomness to the Y position
		buffer.writef32(grid, b-4, pos.Z)
		
		for j = 1, #points-1 do
			if SegSpherInter(points[j], points[j+1], pos, 2) then --record the shaded regions
				table.insert(dyed, i)
				dyedHash[i] = true
				break
			end
		end
	end
	
	--this part is for enforcing the fill quota.
	--it attempts to constrain the image bubble count to a certain size to help further obfuscate it.
	for i = #dyed, fillQuota do
		local pos: number
		local timeOut: number = 0
		repeat
			pos = rand:NextInteger(1, imageArea)
			timeOut += 1
		until timeOut > 10 or not dyedHash[pos]
		dyedHash[pos] = true
		table.insert(dyed, pos)
	end
	
	--shuffle the Fill buffer
	rand:Shuffle(dyed)
	
	local fill: buffer = buffer.create(#dyed * 2) --number of dyed points * 2 bytes in u16
	for i, v in dyed do
		buffer.writeu16(fill, i*2-2, v)
	end
	
	return {
		Grid = grid, --the grid of bubbles
		Fill = fill, --the colored bubbles (just an array of the bubble's index in the Grid buffer)
	}
end

local clr_black: Color3 = Color3.new(0, 0, 0)
local function render(image: T.Image): WorldModel
	local grid: buffer = image.Grid
	local fill: buffer = image.Fill
	local wm: WorldModel = Instance.new('WorldModel')
	wm.Name = 'Image'
	
	local dyed: {[number]: true} = {}
	for i = 0, buffer.len(fill)-1, 2 do
		dyed[buffer.readu16(fill, i)] = true
	end
	
	for i = 0, buffer.len(grid)-1, 12 do
		local pos: Vector3 = Vector3.new(
			buffer.readf32(grid, i),
			buffer.readf32(grid, i+4),
			buffer.readf32(grid, i+8)
		)
		
		---[[
		if dyed[i//12+1] then --skip rendering shaded regions
			continue
		end
		--]]
		
		local p = Instance.new('Part')
		--[[
		if dyed[i//12+1] then --render shaded region as black
			p.Color = clr_black
		end
		--]]

		p.CastShadow = false
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Material = Enum.Material.SmoothPlastic
		p.Shape = Enum.PartType.Ball
		p.Anchored = true
		p.Size = Vector3.one*2
		p.Position = pos
		p.Parent = wm
	end
	
	return wm
end

local module = {
	Draw = draw,
	Render = render,
}

return module
