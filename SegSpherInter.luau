--!strict
--!native

--[[
	Algorithm to determine if a line segment intersects a sphere.
	The parameter "sphere" is the location of the origin of the sphere.
]]

local function segmentIntersectsSphere(from: Vector3, to: Vector3, sphere: Vector3, radius: number): boolean
	local onto: Vector3 = to - from
	local origin: Vector3 = sphere - from
	
	local originDotOnto: number = origin:Dot(onto)
	local ontoLenSq: number = onto:Dot(onto)
	local project: Vector3 = originDotOnto/ontoLenSq * onto
	local radiusSq: number = radius*radius
	
	if originDotOnto < 0 or project:Dot(project) >= ontoLenSq then
		local ontoDisp: Vector3 = onto - origin
		return origin:Dot(origin) <= radiusSq or ontoDisp:Dot(ontoDisp) <= radiusSq
	end
	
	local disp: Vector3 = project - origin
	return disp:Dot(disp) <= radiusSq
end

return segmentIntersectsSphere
