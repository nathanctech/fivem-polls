local function DoAopVote()
    if currentPoll ~= nil then
        print("Vote already in progress.")
        return
    end
    local question = "Time to select a new AOP. Which AOP would you like?"
    local answers = {"Paleto Bay", "Blaine County", "Los Santos", "East Los Santos", "South Los Santos", "Rockford Hills", "Vespuucci and Del Perro", "Vinewood", "Mirror Park", "San Andreas"}
    TriggerEvent("Polls:StartPoll", question, answers, "Poll:AopVote")
end

-- this command forces the poll to start even if the timer isn't up
RegisterCommand("aopvote", function(source, args, rawCommand)
    DoAopVote()
end, true)

AddEventHandler("Poll:AopVote", function(aop, count)
    -- set aop command here
end)

local PollInterval = 1000*60*60*2 -- 2 hours

CreateThread(function()
    while true do
        Wait(PollInterval)
        DoAopVote()
    end
end)