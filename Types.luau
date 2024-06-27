--!strict

--[[
	Types storage for BubbleCAPTCHA
]]

export type Char =  '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'

export type Image = {
	Grid: buffer,
	Fill: buffer,
}

export type FailReason = 'TimedOut' | 'Incorrect' | 'TooFast' | 'AlreadyAnswered' | 'BadData'
export type Callback = (UserId: number, pass: boolean, failReason: FailReason?) -> ()

export type Challenge = {
	ChallengeId: number,
	UserId: number,
	Response: string?,
	Answer: Char,
	MinTime: number,
	Duration: number,
	Date: number,
	Image: Image,
	Callback: Callback,
}

export type Relay = {
	ChallengeId: number,
	Pass: boolean,
	Image: nil,
	Options: nil,
} | {
	ChallengeId: number,
	Pass: nil,
	Duration: number,
	Image: Image,
	Options: {Char},
}

export type Reply = {
	ChallengeId: number,
	Answer: Char,
}

local module = {}

return module
