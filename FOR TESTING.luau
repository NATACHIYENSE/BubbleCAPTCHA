--!strict

--[[
	This script is just for the demo. It will create and send prompt whenever the client asks for it.
]]

local main = script.Parent
local T = require(main:WaitForChild('Types'))
local Challenge = require(main.Challenge)
local Image = require(main.Image)

--this part is for benchmarking the image generator
--[[
local begin: number = os.clock() 
for i = 0, 99 do
	Image.Draw(tostring(i%10)::T.Char)
end
print(`time took: {os.clock() - begin}`)
--]]

--this part is for measuring the Fill buffer size, i.e. amount of bubbles that is part of the imprinted number
--this is used to calibrate the bubble amount quota
--[[
local begin: number = os.clock()
for i = 0, 9 do
	print(buffer.len(Image.Draw(tostring(i)::T.Char).Fill)//2)
end
print(`time took: {os.clock()-begin}`)
--]]

local challengeRandom: Random = Random.new(tick()-1234567)

local registry: {[number]: true} = {} --number is UserId

local function examinePlayer(p: Player)
	if registry[p.UserId] then return end
	registry[p.UserId] = true
	
	local attempt: number = 0
	local passedExam: boolean = false
	local callback: T.Callback callback = function(userId: number, pass: boolean, reason: T.FailReason?)
		attempt += 1
	
		warn(`attempt {attempt}, result: {pass}, reason: {reason or "did not fail"}`)
		if pass then
			warn(`{p.Name} passed at attempt #{attempt}`)
			registry[p.UserId] = nil
			return
		end		
		if attempt < 3 then
			Challenge.Challenge(p, callback, challengeRandom)
		else
			warn(`{p.Name} failed all 3 attempts`)
			registry[p.UserId] = nil
		end
	end
	
	Challenge.Challenge(p, callback, challengeRandom)
end

script.RemoteEvent.OnServerEvent:Connect(examinePlayer)
