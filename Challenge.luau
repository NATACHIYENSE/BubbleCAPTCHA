--!strict

--[[
	**Can only be required from the server!

	The heart of BubbleCAPTCHA.
	Functions for creating and monitoring CAPTCHA challenges.
]]

local main = script.Parent
local T = require(main:WaitForChild('Types'))
local Image = require(main:WaitForChild('Image'))
local CharMap = require(main.Image:WaitForChild('CharMap'))
local relayRemote = main:WaitForChild('Relay')

local idCounter: number = 0
local registry: {[number]: T.Challenge} = {} --key is ChallengeId

--update() is called every so often on Challenges to check their status and do things.
--Challenges are automatically removed from the registry whenever a conclusion is reached.
local function update(id: number): boolean? --returns a boolean as a "quick result"; true if pass, false if not, nil if pending
	local c: T.Challenge? = registry[id]
	if c then
		local now: number = os.clock()
		if now > c.Date+c.Duration then --if Challenge expired
			c.Callback(c.UserId, false, 'TimedOut')
			registry[c.ChallengeId] = nil
			return false
		end	
		if c.Response and now < c.Date+c.MinTime then --if it was answered too fast
			c.Callback(c.UserId, false, 'TooFast')
			registry[c.ChallengeId] = nil
			return false
		end
		if c.Response and c.Response ~= c.Answer then --if answer was incorrect
			c.Callback(c.UserId, false, 'Incorrect')
			registry[c.ChallengeId] = nil
			return false
		end
		if c.Response == c.Answer then --if correctly answered
			c.Callback(c.UserId, true)
			registry[c.ChallengeId] = nil
			return true
		end
	end
	return nil
end

--function for handling the Challenge replies.
--you can make it do something extra if the reply is invalid, e.g. kicking the player.
local function onReply(p: Player, reply: T.Reply)
	if --sanity checking
		type(reply) ~= 'table'
		or type(reply.ChallengeId) ~= 'number'
		or type(reply.Answer) ~= 'string'
		or reply.ChallengeId ~= reply.ChallengeId
	then
		return --p:Kick(`BubbleCAPTCHA: invalid reply`)
	end
	local exists: T.Challenge? = registry[reply.ChallengeId]
	if not exists or exists.UserId ~= p.UserId then --does the Challenge exist? Was the Challenge for this player?
		return --p:Kick(`BubbleCAPTCHA: unknown/illegal reply`)
	end
	if exists.Response then --in case the player answers twice. It shouldn't happen, but it's handled here.
		exists.Callback(exists.UserId, false, 'AlreadyAnswered')
		registry[reply.ChallengeId] = nil
		return
	end
	exists.Response = reply.Answer
	local quickResult: boolean? = update(reply.ChallengeId)
	if quickResult ~= nil then 
		local relay: T.Relay = { --inform the player the result of the Challenge
			ChallengeId = exists.ChallengeId,
			Pass = quickResult,
		}
		relayRemote:FireClient(p, relay)
	end
end

relayRemote.OnServerEvent:Connect(onReply)

--function for initiating a new Challenge to a player.
--callback is a function called when the Challenge is concluded.
--duration is the maximum time allowed to the player to answer.
--minTime isn't that useful but exists to further help combat with botting I guess
local function challenge(p: Player, callback: T.Callback, random: Random, duration: number?, minTime: number?)
	idCounter += 1
	local id: number = idCounter
	local char: T.Char = tostring(random:NextInteger(0, 9))::T.Char
	local image: T.Image = Image.Draw(char, Random.new(random:NextInteger(10_000, 100_000)))
	
	--it's very important that the sort order is unpredictable.
	--otherwise anyone reverse-engineering this can find the answer without guessing.
	
	local options: {T.Char} = {} do --randomize the choices the player can choose. This part is a mess.
		local i: number = 0
		local comp: {T.Char} = CharMap.Complements[char]
		for choose in CharMap.CharMap do
			if choose ~= char and not (comp and table.find(comp, choose)) then
				i += 1
				table.insert(options, choose)
			end
			if i >= 5 then
				break
			end
		end
		table.insert(options, char)
		
		--shuffle the choices; very important!!
		random:Shuffle(options)
	end

	local new: T.Challenge = { --for server record
		ChallengeId = id,
		UserId = p.UserId,
		Answer = char,
		MinTime = minTime or 1,
		Duration = duration or 15,
		Date = os.clock(),
		Image = image,
		Callback = callback,
	}
	local relay: T.Relay = { --for client record
		ChallengeId = id,
		Image = image,
		Duration = new.Duration,
		Options = options,
	}
	registry[id] = new
	relayRemote:FireClient(p, relay)
	
	print(`New challenge to {p.Name}, Answer: {char}`)
	
	task.delay(new.Duration + 1, update, id) --automatically check the Challenge status when the time is up
end

local module = {
	Registry = registry,
	Check = update,
	Challenge = challenge,
}

return module
