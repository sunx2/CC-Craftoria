print("Hunter drone program started")

local d = peripheral.wrap("right")

-- HOME POSITION
local dx, dy, dz = -66.5, 152.5, -3473.5
local dropX, dropY, dropZ = -76, 143, -3488

-- SETTINGS
local ACTION_TIMEOUT = 40      -- increased timeout
local MAX_RETRIES    = 3
local RETRY_DELAY    = 2

-- =========================
-- Debug printer
-- =========================
local function debug(msg)
    print("[" .. textutils.formatTime(os.time(), true) .. "] " .. msg)
end

-- =========================
-- Wait for action to finish
-- =========================
local function waitForAction(actionName)
    local timeout = os.clock() + ACTION_TIMEOUT

    while os.clock() < timeout do
        if d.getCurrentAction() == "" then
            debug(actionName .. " complete")
            return true
        end
        sleep(0.2)
    end

    debug("Timeout waiting for: " .. actionName)
    return false
end

-- =========================
-- Execute action with retry
-- =========================
local function runAction(actionName, setupFunction)
    for attempt = 1, MAX_RETRIES do
        debug("Starting: " .. actionName .. " (Attempt " .. attempt .. ")")

        d.clearArea()
        setupFunction()
        d.setAction(actionName)

        if waitForAction(actionName) then
            return true
        end

        debug("Retrying in " .. RETRY_DELAY .. "s...")
        sleep(RETRY_DELAY)
    end

    debug("!! FAILED after " .. MAX_RETRIES .. " attempts: " .. actionName)
    return false
end

-- =========================
-- Main Loop
-- =========================
while true do
    sleep(3)

    -- =========================
    -- ENTITY IMPORT (large 3D area)
    -- =========================
    runAction("entity_import", function()
        d.addArea(dx-10, dy-5, dz-10, dx+10, dy+5, dz+10,"sphere")
        d.addBlacklistText("@player")
        d.addWhitelistText("@mob")
    end)

    sleep(1)

    -- =========================
    -- MOVE TO DROP LOCATION
    -- =========================
    runAction("goto", function()
        d.addArea(dropX, dropY, dropZ)
    end)

    sleep(1)

    -- =========================
    -- ENTITY EXPORT
    -- =========================
    runAction("entity_export", function()
        d.addArea(dropX, dropY, dropZ)
    end)

    sleep(1)

    -- =========================
    -- RETURN HOME
    -- =========================
    runAction("goto", function()
        d.addArea(dx, dy, dz)
    end)

    debug("=== Cycle complete ===")
end
