--!strict

--[[
	Vector graphics for characters.
	Each character is an array of points. Lines are drawn between a point and the point after it.
	"complements" is a blacklist to discriminate against potentially look-alike characters to avoid confusion in challenges.
	The transform function is self-explanatory.
]]

local main = script.Parent.Parent
local T = require(main:WaitForChild('Types'))

local n = { --common points stored here so it's easier to write out
	tl = Vector3.new(-1, 2),
	tm = Vector3.new(0, 2),
	tr = Vector3.new(1, 2),
	ml = Vector3.new(-1, 0),
	mm = Vector3.new(0, 0),
	mr = Vector3.new(1, 0),
	bl = Vector3.new(-1, -2),
	bm = Vector3.new(0, -2),
	br = Vector3.new(1, -2),
}

local charMap: {[T.Char]: {Vector3}} = {
	['0'] = {n.tl, n.tr, n.br, n.bl, n.tl},
	['1'] = {n.tm, n.bm},
	['2'] = {n.tl, n.tr, n.mm, n.ml, n.bl, n.br},
	['3'] = {n.tl, n.tr, n.mm, n.mr, n.br, n.bl},
	['4'] = {n.mr, n.ml, n.tr, n.br},
	['5'] = {n.tr, n.tl, n.ml, n.mr, n.br, n.bl},
	['6'] = {n.tm, n.ml, n.bl, n.br, n.mr, n.ml},
	['7'] = {Vector3.new(-1, 1), n.tl, n.tr, n.bm},
	['8'] = {n.mr, n.tr, n.tl, n.ml, n.mr, n.br, n.bl, n.ml},
	['9'] = {n.mr, n.ml, n.tl, n.tr, n.br, n.bl},
}

local complements: {[T.Char]: {T.Char}} = {
	['0'] = {'8'},
	['8'] = {'0'},
	--['2'] = {'5'},
	--['5'] = {'2'},
	['1'] = {'7'},
	['7'] = {'1'},
	--['6'] = {'9'},
	--['9'] = {'6', '4'},
	['9'] = {'4'},
	['4'] = {'9'},
}

local function transform(cf: CFrame, vecs: {Vector3}, scale: number?): {Vector3}
	local new: {Vector3} = table.create(#vecs)
	local scale: number = scale or 1
	for i, v in vecs do
		new[i] = cf:PointToWorldSpace(v) * scale
	end
	return new
end

local module = {
	CharMap = charMap,
	Complements = complements,
	Transform = transform,
}

return module
