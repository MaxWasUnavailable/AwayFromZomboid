---
--- Created by Max
--- Created on: 10/05/2024
---

-- Mod class
---@class AFKTools
AFKTools = {}

-- Mod info
AFKTools.modName = "AFKTools"
AFKTools.modVersion = "1.0.0"
AFKTools.modAuthor = "Max"
AFKTools.modDescription = "AFK Tools is a mod that adds AFK detection & management systems."

-- Mod variables

--- The AFK timer in seconds.
AFKTools.AFKTimer = 0
AFKTools.previousCheckTime = nil
AFKTools.isAFK = false

-- Misc methods

--- Log a message.
---@param message string
---@return void
AFKTools.log = function(message)
    print(AFKTools.modName .. ": " .. message)
end

--- Check whether we're a client on a multiplayer server.
---@return boolean
AFKTools.isMultiplayerClient = function()
    if isServer() then
        AFKTools.log("Multiplayer client check returning false. Server detected.")
        return false
    end
    return getCore():getGameMode() == "Multiplayer" and isClient()
end

--- Get the total AFK time before a player is kicked.
---@return number
AFKTools.totalAFKKickTime = function()
    return AFKTools.getAFKTimeout() + AFKTools.getAFKKickTimeout()
end

--- Send a chat notification.
---@param message string
---@return void
AFKTools.sendChatNotification = function(message)
    processGeneralMessage(message)
end

-- Fetch sandbox vars

--- Get the AFK timeout value in seconds.
---@return number
AFKTools.getAFKTimeout = function()
    local value = SandboxVars.AFKTools.AFKTimeout
    if value == nil then
        value = 300
        AFKTools.log("AFK timeout value not found in sandbox variables. Using default value of " .. value .. " seconds.")
    end
    return value
end

--- Get the AFK kick timeout value in seconds.
---@return number
AFKTools.getAFKKickTimeout = function()
    local value = SandboxVars.AFKTools.AFKKickTimeout
    if value == nil then
        value = 600
        AFKTools.log("AFK kick timeout value not found in sandbox variables. Using default value of " .. value .. " seconds.")
    end
    return value
end

--- Get the AFK Popup message when a player goes AFK.
---@return string
AFKTools.getAFKOnPopupMessage = function()
    local value = SandboxVars.AFKTools.AFKOnPopupMessage
    if value == nil then
        value = "You are now AFK."
        AFKTools.log("AFK On Popup message not found in sandbox variables. Using default message.")
    end
    return value
end

--- Get the AFK Popup message when a player is no longer AFK.
---@return string
AFKTools.getAFKOffPopupMessage = function()
    local value = SandboxVars.AFKTools.AFKOffPopupMessage
    if value == nil then
        value = "You are no longer AFK."
        AFKTools.log("AFK Off Popup message not found in sandbox variables. Using default message.")
    end
    return value
end

--- Get whether to enable the AFK popup system.
---@return boolean
AFKTools.getDoPopup = function()
    local value = SandboxVars.AFKTools.DoPopup
    if value == nil then
        value = true
        AFKTools.log("AFK Do Popup value not found in sandbox variables. Using default value of " .. tostring(value) .. ".")
    end
    return value
end

--- Get whether to enable the AFK kick system.
---@return boolean
AFKTools.getDoKick = function()
    local value = SandboxVars.AFKTools.DoKick
    if value == nil then
        value = true
        AFKTools.log("AFK Do Kick value not found in sandbox variables. Using default value of " .. tostring(value) .. ".")
    end
    return value
end

--- Get whether to enable the AFK zombies no attack system.
---@return boolean
AFKTools.getAFKZombiesNoAttack = function()
    local value = SandboxVars.AFKTools.AFKZombiesNoAttack
    if value == nil then
        value = true
        AFKTools.log("AFK Zombies No Attack value not found in sandbox variables. Using default value of " .. tostring(value) .. ".")
    end
    return value
end

--- Get whether to enable manual AFK.
---@return boolean
AFKTools.getAllowManualAFK = function()
    local value = SandboxVars.AFKTools.AllowManualAFK
    if value == nil then
        value = true
        AFKTools.log("Allow Manual AFK value not found in sandbox variables. Using default value of " .. tostring(value) .. ".")
    end
    return value
end

--- Get the manual AFK delay value in seconds.
---@return number
AFKTools.getManualAFKDelay = function()
    local value = SandboxVars.AFKTools.ManualAFKDelay
    if value == nil then
        value = 60
        AFKTools.log("Manual AFK Delay value not found in sandbox variables. Using default value of " .. value .. " seconds.")
    end
    return value
end

--- Get whether to ignore staff.
---@return boolean
AFKTools.getIgnoreStaff = function()
    local value = SandboxVars.AFKTools.DoIgnoreStaff
    if value == nil then
        value = true
        AFKTools.log("Ignore Staff value not found in sandbox variables. Using default value of " .. tostring(value) .. ".")
    end
    return value
end

-- Mod core functions

--- Check whether the player has been AFK for longer than the timeout value
---@return boolean
AFKTools.isAFKTimedOut = function()
    return AFKTools.AFKTimer >= AFKTools.getAFKTimeout()
end

--- Check whether the player should be kicked.
---@return boolean
AFKTools.shouldKick = function()
    return AFKTools.AFKTimer >= AFKTools.totalAFKKickTime()
end

--- Reset the AFK timer.
AFKTools.resetAFKTimer = function()
    AFKTools.AFKTimer = 0
end

--- Increment the AFK timer.
AFKTools.incrementAFKTimer = function(delta)
    delta = delta or 1
    AFKTools.AFKTimer = AFKTools.AFKTimer + delta

    if AFKTools.isAFKTimedOut() then
        if AFKTools.isAFK == false then
            AFKTools.becomeAFK()
        end
        if AFKTools.getDoKick() then
            if AFKTools.shouldKick() then
                AFKTools.disconnectPlayer()
            end
        end
    else
        if AFKTools.isAFK == true then
            -- Failsafe in case the player is not AFK but the mod thinks they are
            AFKTools.log("Failsafe: Player is not AFK but the mod thinks they are.")
            AFKTools.becomeNotAFK()
        end
    end
end

--- Disconnect player.
AFKTools.disconnectPlayer = function()
    if AFKTools.isMultiplayerClient() then
        getCore():exitToMenu()
    end
end

--- Popup the AFK message.
---@return void
AFKTools.AFKOnPopup = function()
    HaloTextHelper.addText(getPlayer(), AFKTools.getAFKOnPopupMessage(), HaloTextHelper.getColorRed())
    local message = AFKTools.getAFKOnPopupMessage()
    if AFKTools.getDoKick() then
        message = message .. " (Kick in " .. AFKTools.getAFKKickTimeout() .. " seconds)"
    end
    AFKTools.sendChatNotification(message)
end

--- Popup the not AFK message.
---@return void
AFKTools.AFKOffPopup = function()
    HaloTextHelper.addText(getPlayer(), AFKTools.getAFKOffPopupMessage(), HaloTextHelper.getColorGreen())
    AFKTools.sendChatNotification(AFKTools.getAFKOffPopupMessage())
end

--- Handle becoming AFK.
---@return void
AFKTools.becomeAFK = function()
    AFKTools.isAFK = true

    if AFKTools.getDoPopup() then
        AFKTools.AFKOnPopup()
    end

    if AFKTools.getAFKZombiesNoAttack() then
        getPlayer():setZombiesDontAttack(true)
    end
end

--- Handle becoming not AFK.
---@return void
AFKTools.becomeNotAFK = function()
    AFKTools.isAFK = false

    if AFKTools.getDoPopup() then
        AFKTools.AFKOffPopup()
    end

    if AFKTools.getAFKZombiesNoAttack() then
        getPlayer():setZombiesDontAttack(false)
    end

    AFKTools.resetAFKTimer()
end

AFKTools.incrementAFKHook = function()
    if AFKTools.getIgnoreStaff() then
        local access_level = getAccessLevel()
        if access_level ~= nil and access_level ~= "" and access_level ~= "none" then   -- Access level for none seems atypical compared to other access levels
            AFKTools.resetAFKTimer()
            return
        end
    end

    if AFKTools.isMultiplayerClient() == false then
        AFKTools.log("Skipping check since isMultiplayerClient is " .. AFKTools.isMultiplayerClient())
        AFKTools.resetAFKTimer()
        return
    end

    local currentTime = os.time()

    if AFKTools.previousCheckTime ~= nil then
        AFKTools.incrementAFKTimer(currentTime - AFKTools.previousCheckTime)
    end

    AFKTools.previousCheckTime = currentTime
end

-- Init

--- Initialize the mod and add event hooks.
---@return void
AFKTools.init = function()
    AFKTools.resetAFKTimer()
    AFKTools.previousCheckTime = os.time()
    AFKTools.isAFK = false

    Events.OnKeyPressed.Add(AFKTools.resetAFKTimer)
    Events.OnMouseDown.Add(AFKTools.resetAFKTimer)
    Events.OnMouseUp.Add(AFKTools.resetAFKTimer)
    Events.OnCustomUIKeyPressed.Add(AFKTools.resetAFKTimer)

    Events.EveryOneMinute.Add(AFKTools.incrementAFKHook)

    AFKTools.log(AFKTools.modVersion .. " initialized.")
end

-- Init hook

Events.OnConnected.Add(AFKTools.init)