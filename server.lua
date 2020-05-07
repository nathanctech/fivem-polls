--[[
    MIT License

Copyright (c) 2020 nathanctech

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

FiveM Voting

Enables the ability to conduct polls on just about any topic.
]]

voteTimer = 30000 -- in milliseconds, defaulted to 30 seconds

currentPoll = nil

Option = {
    text = nil,
    voteCount = nil,
    voteList = nil
}

function Option.Create(text)
    local self = shallowcopy(Option)
    self.text = text
    self.voteCount = 0
    self.voteList = {}
    return self
end

function Option:Increment(voter)
    self.voteCount = self.voteCount + 1
    table.insert(self.voteList, voter)
    return self
end

function Option:GetText()
    return self.text
end

function Option:GetVoteCount()
    return self.voteCount
end

Poll = {
    question = nil,
    startedBy = nil,
    timeStarted = nil,
    options = nil,
    voted = nil,
    event = nil
}

function Poll.Create(question, options, event)
    local self = shallowcopy(Poll)
    self.question = question
    self.options = options
    self.voted = {}
    self.event = event
    return self
end

function Poll:Start()
    self.timeStarted = os.time()
    SendPollMessage(-1, self)
    currentPoll = self
    SetTimeout(voteTimer, endPoll)
    return self
end

function endPoll()
    -- tally votes
    local highest = 0
    local highOption = nil
    for idx, option in pairs(currentPoll:GetOptions()) do
        if option:GetVoteCount() > highest then
            highest = option:GetVoteCount()
            highOption = currentPoll.options[idx]
        end
    end
    if highOption == nil or highest == 0 then
        sendNotify(-1, "Vote Cancelled", "No one voted, no winners!")
    else
        TriggerEvent(currentPoll.event, highOption:GetText(), highOption:GetVoteCount())
        sendNotify(-1, "Vote Result", string.format("Winning vote is: ^3%s^0 with ^3%s^0 votes.",highOption:GetText(), highOption:GetVoteCount()))
    end
    currentPoll = nil
end

function Poll:GetOptions()
    return self.options
end

function Poll:ProcessVote(index, player)
    for k, v in pairs(self.voted) do
        if v == player then
            sendNotify(player, "Error", "You have already voted!")
            return
        end
    end
    if self.options[index] ~= nil then
        self.options[index]:Increment(player)
        table.insert(self.voted, player)
        TriggerClientEvent("pNotify:SendNotification", player, {
            text = "Thanks for voting!",
            type = "info",
            layout = "bottomcenter",
            killer = true,
            timeout = 2000
        })
        sendNotify(player, "Success", "Your vote has been recorded!")
    else
        print("error processing vote")
    end
end

AddEventHandler("Polls:StartPoll", function(question, options, eventTrigger)
    local opts = {}
    for _, o in pairs(options) do
        local op = Option.Create(o)
        table.insert(opts, op)
    end
    local poll = Poll.Create(question, opts, eventTrigger)
    currentPoll = nil
    poll:Start()
end)



RegisterCommand("vote", function(source, args, rawCommand)
    if currentPoll == nil then
        sendNotify(source, "Error", "No poll in progress!")
        return
    end
    if #args > 0 then
        -- parse
        local options = currentPoll:GetOptions()
        local selected = tonumber(args[1])
        if options[selected] ~= nil then
            currentPoll:ProcessVote(selected, source)
            
        else
            sendNotify(source, "Error", "Invalid option.")
        end
    else
        sendNotify(source, "Error", "An option is required.")
    end
end)

RegisterCommand("voted", function(source, args, rawCommand)
    if currentPoll ~= nil then
        TriggerClientEvent("pNotify:SendNotification", source, {
            text = "Vote dismissed.",
            type = "info",
            layout = "bottomcenter",
            killer = true,
            timeout = 500
        })
    end
end)

function SendPollMessage(target, poll)
    local optionText = ""
    for index, opt in pairs(poll:GetOptions()) do
        optionText = optionText..string.format("%s: %s<br/>", index, opt.text)
    end
    TriggerClientEvent("pNotify:SendNotification", target, {
        text = string.format("<h3>New Poll!</h3><p>%s</p><hr /><p>%s</p>Use /vote <number> to vote! Dismiss with /voted",poll.question, optionText),
        type = "info",
        layout = "bottomcenter",
        timeout = voteTimer,
        killer = true
    })
end

function sendNotify(target, prefix, message)
    TriggerClientEvent("chat:addMessage", target, {args = {string.format("^0[ %s ^0] ",prefix), message}})
end

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
