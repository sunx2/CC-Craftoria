print("hunter drone program started")
d = peripheral.wrap("right")

local dx, dy, dz = -66.5, 152.5, -3473.5

local ACTION_TIMEOUT = 20      -- seconds per action
local MAX_RETRIES    = 3       -- retries before skipping step
local RETRY_DELAY    = 2       -- wait before retrying

-- =========================
-- Debug printer
-- =========================
local function debug(msg)
    print("[" .. textutils.formatTime(os.time(), true) .. "] " .. msg)
end

-- =========================
-- Wait for action with timeout
-- =========================
local function waitForAction(actionName)
    local timer = os.startTimer(ACTION_TIMEOUT)

    while true do
        if d.getAction() == nil then
            debug("✓ Completed: " .. actionName)
            return true
        end

        local event, id = os.pullEvent()

        if event == "timer" and id == timer then
            debug("✗ TIMEOUT: " .. actionName)
            return false
        end
    end
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

    -- ENTITY IMPORT
    runAction("entity_import", function()
        d.addArea(dx, dy, dz-10, dx, dy, dz+10, "sphere")
        d.addBlacklistText("@player")
        d.addWhitelistText("@mob")
    end)

    -- GOTO EXPORT
    runAction("goto", function()
        d.addArea(-76, 143, -3488)
    end)

    -- ENTITY EXPORT
    runAction("entity_export", function()
        -- no area needed if already at target
    end)

    -- RETURN HOME
    runAction("goto", function()
        d.addArea(dx, dy, dz)
    end)

    debug("=== Cycle complete ===")
end
