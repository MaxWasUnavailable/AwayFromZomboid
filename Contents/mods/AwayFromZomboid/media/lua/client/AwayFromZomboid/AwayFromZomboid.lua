---
--- Created by Max
--- Created on: 10/05/2024
---

-- Mod class
---@class AwayFromZomboid
AwayFromZomboid = {}

-- Mod info
AwayFromZomboid.modName = "AwayFromZomboid"
AwayFromZomboid.modVersion = "1.0.0"
AwayFromZomboid.modAuthor = "Max"
AwayFromZomboid.additionalCredits = {"Vorshim92"}
AwayFromZomboid.modDescription = "AwayFromZomboid is a mod that adds AFK detection & management systems."

-- Mod variables

--- The AFK timer in seconds.
AwayFromZomboid.AFKTimer = 0
--- The previous check time.
AwayFromZomboid.previousCheckTime = nil
--- Whether the player is AFK.
AwayFromZomboid.isAFK = false
--- Late addition to the AFKTimer to prevent reset on manual AFK.
AwayFromZomboid.lateTimerAddition = 0

-- Misc methods

--- Log a message.
---@param message string
---@return void
AwayFromZomboid.log = function(message)
    print(AwayFromZomboid.modName .. ": " .. message)
end

--- Check whether we're a client on a multiplayer server.
---@return boolean
AwayFromZomboid.isMultiplayerClient = function()
    if isServer() then
        AwayFromZomboid.log("Multiplayer client check returning false. Server detected.")
        return false
    end
    return getCore():getGameMode() == "Multiplayer" and isClient()
end

--- Get the total AFK time before a player is kicked.
---@return number
AwayFromZomboid.totalAFKKickTime = function()
    return AwayFromZomboid.getAFKTimeout() + AwayFromZomboid.getAFKKickTimeout()
end

--- Send a chat notification.
---@param message string
---@return void
AwayFromZomboid.sendChatNotification = function(message)
    -- processGeneralMessage(message)
    getPlayer():Say(message)
end

-- Fetch sandbox vars

--- Get the AFK timeout value in seconds.
---@return number
AwayFromZomboid.getAFKTimeout = function()
    local value = SandboxVars.AwayFromZomboid.AFKTimeout
    if value == nil then
        value = 300
        AwayFromZomboid.log("AFK timeout value not found in sandbox variables. Using default value of " .. value .. " seconds.")
    end
    return value
end

--- Get the AFK kick timeout value in seconds.
---@return number
AwayFromZomboid.getAFKKickTimeout = function()
    local value = SandboxVars.AwayFromZomboid.AFKKickTimeout
    if value == nil then
        value = 600
        AwayFromZomboid.log("AFK kick timeout value not found in sandbox variables. Using default value of " .. value .. " seconds.")
    end
    return value
end

--- Get the AFK Popup message when a player goes AFK.
---@return string
AwayFromZomboid.getAFKOnPopupMessage = function()
    local value = SandboxVars.AwayFromZomboid.AFKOnPopupMessage
    if value == nil then
        value = "You are now AFK."
        AwayFromZomboid.log("AFK On Popup message not found in sandbox variables. Using default message.")
    end
    return value
end

--- Get the AFK Popup message when a player is no longer AFK.
---@return string
AwayFromZomboid.getAFKOffPopupMessage = function()
    local value = SandboxVars.AwayFromZomboid.AFKOffPopupMessage
    if value == nil then
        value = "You are no longer AFK."
        AwayFromZomboid.log("AFK Off Popup message not found in sandbox variables. Using default message.")
    end
    return value
end

--- Get whether to enable the AFK popup system.
---@return boolean
AwayFromZomboid.getDoPopup = function()
    local value = SandboxVars.AwayFromZomboid.DoPopup
    if value == nil then
        value = true
        AwayFromZomboid.log("AFK Do Popup value not found in sandbox variables. Using default value of " .. tostring(value) .. ".")
    end
    return value
end

--- Get whether to enable the AFK kick system.
---@return boolean
AwayFromZomboid.getDoKick = function()
    local value = SandboxVars.AwayFromZomboid.DoKick
    if value == nil then
        value = true
        AwayFromZomboid.log("AFK Do Kick value not found in sandbox variables. Using default value of " .. tostring(value) .. ".")
    end
    return value
end

--- Get whether to enable the AFK zombies no attack system.
---@return boolean
AwayFromZomboid.getAFKZombiesNoAttack = function()
    local value = SandboxVars.AwayFromZomboid.AFKZombiesNoAttack
    if value == nil then
        value = true
        AwayFromZomboid.log("AFK Zombies No Attack value not found in sandbox variables. Using default value of " .. tostring(value) .. ".")
    end
    return value
end

--- Get whether to enable manual AFK.
---@return boolean
AwayFromZomboid.getAllowManualAFK = function()
    local value = SandboxVars.AwayFromZomboid.AllowManualAFK
    if value == nil then
        value = true
        AwayFromZomboid.log("Allow Manual AFK value not found in sandbox variables. Using default value of " .. tostring(value) .. ".")
    end
    return value
end

--- Get the manual AFK delay value in seconds.
---@return number
AwayFromZomboid.getManualAFKDelay = function()
    local value = SandboxVars.AwayFromZomboid.ManualAFKDelay
    if value == nil then
        value = 60
        AwayFromZomboid.log("Manual AFK Delay value not found in sandbox variables. Using default value of " .. value .. " seconds.")
    end
    return value
end

--- Get whether to ignore staff.
---@return boolean
AwayFromZomboid.getIgnoreStaff = function()
    local value = SandboxVars.AwayFromZomboid.DoIgnoreStaff
    if value == nil then
        value = true
        AwayFromZomboid.log("Ignore Staff value not found in sandbox variables. Using default value of " .. tostring(value) .. ".")
    end
    return value
end

-- Mod core functions

--- Check whether the player has been AFK for longer than the timeout value
---@return boolean
AwayFromZomboid.isAFKTimedOut = function()
    return AwayFromZomboid.AFKTimer >= AwayFromZomboid.getAFKTimeout()
end

--- Check whether the player should be kicked.
---@return boolean
AwayFromZomboid.shouldKick = function()
    return AwayFromZomboid.AFKTimer >= AwayFromZomboid.totalAFKKickTime()
end

--- Reset the AFK timer.
---@return void
AwayFromZomboid.resetAFKTimer = function()
    AwayFromZomboid.AFKTimer = 0
    AwayFromZomboid.previousCheckTime = nil
end

--- Increment the AFK timer.
---@param delta number
---@return void
AwayFromZomboid.incrementAFKTimer = function(delta)
    delta = delta or 1
    AwayFromZomboid.AFKTimer = AwayFromZomboid.AFKTimer + delta

    if AwayFromZomboid.isAFKTimedOut() then
        if AwayFromZomboid.isAFK == false then
            AwayFromZomboid.becomeAFK()
        end
        if AwayFromZomboid.getDoKick() then
            if AwayFromZomboid.shouldKick() then
                AwayFromZomboid.disconnectPlayer()
            end
        end
    else
        if AwayFromZomboid.isAFK == true then
            AwayFromZomboid.becomeNotAFK()
        end
    end
end

--- Disconnect player.
---@return void
AwayFromZomboid.disconnectPlayer = function()
    if AwayFromZomboid.isMultiplayerClient() then
        getCore():exitToMenu()
    end
end

--- Popup the AFK message.
---@return void
AwayFromZomboid.AFKOnPopup = function()
    getPlayer():setHaloNote(AwayFromZomboid.getAFKOnPopupMessage(), 255, 0, 0, (SandboxVars.AwayFromZomboid.AFKKickTimeout*60)+500)
    local message = AwayFromZomboid.getAFKOnPopupMessage()
    if AwayFromZomboid.getDoKick() then
        message = message .. " (Kick in " .. AwayFromZomboid.getAFKKickTimeout() .. " seconds)"
    end
    AwayFromZomboid.sendChatNotification(message)
end

--- Popup the not AFK message.
---@return void
AwayFromZomboid.AFKOffPopup = function()
    getPlayer():setHaloNote(AwayFromZomboid.getAFKOffPopupMessage(), 0, 255, 0, 500)
    AwayFromZomboid.sendChatNotification(AwayFromZomboid.getAFKOffPopupMessage())
end

--- Handle becoming AFK.
---@return void
AwayFromZomboid.becomeAFK = function()
    AwayFromZomboid.isAFK = true

    if AwayFromZomboid.getDoPopup() then
        AwayFromZomboid.AFKOnPopup()
    end

    if AwayFromZomboid.getAFKZombiesNoAttack() then
        getPlayer():setZombiesDontAttack(true)
    end

    AwayFromZomboid.registerActivityHooks(AwayFromZomboid.becomeNotAFK)
end

--- Handle becoming not AFK.
---@return void
AwayFromZomboid.becomeNotAFK = function()
    AwayFromZomboid.isAFK = false

    AwayFromZomboid.deRegisterActivityHooks(AwayFromZomboid.becomeNotAFK)

    if AwayFromZomboid.getDoPopup() then
        AwayFromZomboid.AFKOffPopup()
    end

    if AwayFromZomboid.getAFKZombiesNoAttack() then
        getPlayer():setZombiesDontAttack(false)
    end

    AwayFromZomboid.resetAFKTimer()
end

--- Increment the AFK timer hook for every in-game minute.
---@return void
AwayFromZomboid.incrementAFKHook = function()
    if AwayFromZomboid.getIgnoreStaff() then
        local access_level = getAccessLevel()
        if access_level ~= nil and access_level ~= "" and access_level ~= "none" then
            -- Access level for none seems atypical compared to other access levels
            AwayFromZomboid.resetAFKTimer()
            return
        end
    end

    if AwayFromZomboid.isMultiplayerClient() == false then
        AwayFromZomboid.resetAFKTimer()
        return
    end

    local currentTime = os.time()

    if AwayFromZomboid.previousCheckTime ~= nil then
        local delta = currentTime - AwayFromZomboid.previousCheckTime or currentTime
        delta = delta + AwayFromZomboid.lateTimerAddition
        AwayFromZomboid.lateTimerAddition = 0
        AwayFromZomboid.incrementAFKTimer(delta)
    end

    AwayFromZomboid.previousCheckTime = currentTime
end

--- Handle manual AFK.
---@param chatMessage ChatMessage
---@param tabId number
---@return void
AwayFromZomboid.manualAFKHook = function(chatMessage, tabId)
    if AwayFromZomboid.getAllowManualAFK() then
        if chatMessage:getAuthor() == getPlayer():getUsername() then
            local fullMessage = chatMessage:getText()
            local extractedMessage = fullMessage:match('"(.-)"')
            if string.lower(extractedMessage) == "afk." then
                AwayFromZomboid.sendChatNotification("You will become AFK in ~" .. AwayFromZomboid.getManualAFKDelay() .. " seconds.")
                AwayFromZomboid.lateTimerAddition = AwayFromZomboid.getAFKTimeout() - AwayFromZomboid.getManualAFKDelay()
            end
        end
    end
end

--- Register the reset hooks.
---@param method function
---@return void
AwayFromZomboid.registerActivityHooks = function(method)
    Events.OnCustomUIKeyPressed.Add(method)
    Events.OnKeyPressed.Add(method)
    Events.OnMouseDown.Add(method)
    Events.OnMouseUp.Add(method)
end

--- Remove the reset hooks.
---@param method function
---@return void
AwayFromZomboid.deRegisterActivityHooks = function(method)
    Events.OnCustomUIKeyPressed.Remove(method)
    Events.OnKeyPressed.Remove(method)
    Events.OnMouseDown.Remove(method)
    Events.OnMouseUp.Remove(method)
end

-- Init

--- Initialize the mod and add event hooks.
---@return void
AwayFromZomboid.init = function()
    AwayFromZomboid.resetAFKTimer()
    AwayFromZomboid.isAFK = false

    AwayFromZomboid.registerActivityHooks(AwayFromZomboid.resetAFKTimer)

    Events.EveryOneMinute.Add(AwayFromZomboid.incrementAFKHook)

    Events.OnAddMessage.Add(AwayFromZomboid.manualAFKHook)

    AwayFromZomboid.log(AwayFromZomboid.modVersion .. " initialized.")
end

-- Init hook

Events.OnCreatePlayer.Add(AwayFromZomboid.init)
Events.OnPlayerDeath.Add(function (player)
    if getPlayer():isDead() then
        AwayFromZomboid.resetAFKTimer()
        AwayFromZomboid.isAFK = false
        Events.EveryOneMinute.Remove(AwayFromZomboid.incrementAFKHook)
        Events.OnAddMessage.Remove(AwayFromZomboid.manualAFKHook)
    end

end)