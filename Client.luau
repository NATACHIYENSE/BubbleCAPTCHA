--!strict

--[[
	This one localscript handles everything on the clientside.
	
	Just as the prophecy predicts, the UI code is a huge mess.
	I've tried my best to label things to make everything understandable.
]]

local main = script.Parent
local T = require(main:WaitForChild('Types'))
local Image = require(main:WaitForChild('Image'))
local relayRemote = main:WaitForChild('Relay')

local promptUI = script:WaitForChild('BubbleCAPTCHAPrompt')
local promptChoiceButton = script:WaitForChild('Choice')

local pgui = game:GetService('Players').LocalPlayer.PlayerGui
local captchaContainer = script:WaitForChild('BubbleCAPTCHA'):WaitForChild('Container')
local tws = game:GetService('TweenService')
local twiGeneric = TweenInfo.new(.25, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)

type PromptUI = typeof(promptUI)

type Prompt = { --for client record. The structure is different from T.Challenge.
	Active: boolean,
	ChallengeId: number,
	Life: number,
	UI: PromptUI,
	Message: string?,
	Thread: thread,
}

local registry: {[number]: Prompt} = {} --number is ChallengeId

local function delete(id: number, saveThread: boolean?): boolean --boolean result is if the removal was successful
	local exists: Prompt? = registry[id]
	if exists and exists.Active then
		exists.Active = false
		exists.UI:Destroy()
		
		--this exists because you cannot cancel a thread from within itself.
		if not saveThread then --usually not needed anyways because the thread will expire on its own
			task.cancel(exists.Thread) 
		end
		
		registry[id] = nil
		return true
	end
	return false
end

--function for creating and handling the Challenge prompts.
--it does not return the Prompt itself because it's kept and managed internally
local function new(relay: T.Relay)
	assert(relay.ChallengeId and relay.Options and relay.Image, 'BubbleCAPTCHA: wrong relay format')

	local ui: PromptUI = promptUI:Clone()
	local f = ui:WaitForChild('Frame')
	local vf = f:WaitForChild('ViewportFrame')
	local timerTL = f:WaitForChild('Timer')
	local choicesF = f:WaitForChild('Choices')
	local choicesUIGL = choicesF:WaitForChild('UIGridLayout')
	ui:SetAttribute('ChallengeId', relay.ChallengeId)

	local cam: Camera = Instance.new('Camera')
	cam.CFrame = CFrame.lookAt(Vector3.yAxis*20, Vector3.zero, -Vector3.zAxis) --look straight down
	vf.CurrentCamera = cam
	
	local prompt: Prompt

	local thread: thread = task.defer(function() --runs on a Heartbeat loop for the duration of the prompt
		while prompt.Active and prompt.Life > 0 do
			local dt: number = task.wait()
			prompt.Life -= dt
			timerTL.Text = prompt.Message or string.format('Time left: <b>%.01f</b>', prompt.Life)
			if prompt.Life <= 1 then --fade out the Prompt when its life is almost up
				ui.GroupTransparency = (1 - prompt.Life)^3
			end
		end
		delete(relay.ChallengeId, true) --expires when the time is up
	end)

	Image.Render(relay.Image).Parent = vf
	
	for i, v: T.Char in relay.Options do --create the choices
		local choice: TextButton = promptChoiceButton:Clone()
		choice.Text = v
		choice.MouseButton1Click:Connect(function()
			local reply: T.Reply = {
				ChallengeId = relay.ChallengeId,
				Answer = v,
			}
			prompt.Life = 2 --extend the life of the prompt to allow the server time to process
			prompt.Message = 'Answering...'
			relayRemote:FireServer(reply)
		end)
		choice.LayoutOrder = i
		choice.Visible = false
		choice.Parent = choicesF
	end
	
	--to make botting just a bit harder, require the player to click to reveal the image and the choices.
	--by default the image and the choices are hidden.
	choicesUIGL.CellPadding = UDim2.fromOffset(1, 8)
	choicesUIGL.CellSize = UDim2.fromOffset(0, 0)
	local reveal: RBXScriptConnection reveal = vf.InputBegan:Connect(function(i: InputObject)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			for _, v: ImageButton in choicesF:GetChildren() do
				if v ~= choicesUIGL then
					v.Visible = true
				end
			end
			tws:Create(vf, twiGeneric, {ImageColor3=Color3.new(1,1,1),BackgroundTransparency=.5,BackgroundColor3=Color3.new(1,1,1)}):Play()
			tws:Create(choicesUIGL, twiGeneric, {CellPadding=UDim2.fromOffset(8, 8), CellSize=UDim2.fromOffset(40, 40)}):Play()
			reveal:Disconnect() --probably not even necessary because the Prompt will be :Destroy()ed
		end
	end)

	prompt = {
		Active = true,
		ChallengeId = relay.ChallengeId,
		Life = relay.Duration,
		UI = ui,
		Thread = thread,
	}
	
	ui.GroupTransparency = 1
	ui.Parent = captchaContainer
	tws:Create(ui, twiGeneric, {GroupTransparency=0}):Play() --fade in animation
	
	registry[relay.ChallengeId] = prompt
end

--garbage collection function. Not used by default.
--just in case there's some stray Challenge prompts still showing on screen, this can clean them up.
local function gc()
	local count: number = 0
	for _, v: PromptUI in captchaContainer:GetChildren() do
		if v.Name == 'BubbleCAPTCHAPrompt' and not registry[v:GetAttribute('ChallengeId')] then
			count += 1
			v:Destroy()
		end
	end
	print(`BubbleCAPTCHA: Prompt gc() removed {count} item(s)`)
end

--listens for new Challenges and also the results for them.
relayRemote.OnClientEvent:Connect(function(relay: T.Relay) 
	if type(relay.Pass) == 'boolean' then --if it's a result
		local exists: Prompt? = registry[relay.ChallengeId]
		if exists then
			exists.Life = 1
			exists.Message = if relay.Pass then
				'<font color="#0F0"><b>Pass</b></font>'
				else '<font color="#F00"><b>Fail</b></font>'
			exists.UI.GroupColor3 = if relay.Pass then Color3.new(0,1,0) else Color3.new(1,0,0)
			tws:Create(exists.UI.Frame.Choices.UIGridLayout, twiGeneric, {CellSize=UDim2.fromOffset(40,0)}):Play()
		end
	else --if it's a new Challenge that needs to be solved
		new(relay)
	end
end)

captchaContainer.Parent.Parent = pgui
