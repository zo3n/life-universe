local CGame = {
    dimension = 69,
    active = true,
    postgui = false,
    counter = 0,
    speed = 1, -- gamespeed

}

local sw, sh = guiGetScreenSize()
strf = string.format
local function output(msg, lvl)
    return outputDebugString(string.format("CGame: %s", tostring(msg)), lvl or 3)
end

function CGame.toggleGTABinds(bool)
local controlTable = { "fire", "aim_weapon", "next_weapon", "previous_weapon", "forwards", "backwards", "left", "right", "zoom_in", "zoom_out",
 "change_camera", "jump", "sprint", "look_behind", "crouch", "action", "walk", "conversation_yes", "conversation_no",
 "group_control_forwards", "group_control_back", "enter_exit", "vehicle_fire", "vehicle_secondary_fire", "vehicle_left", "vehicle_right",
 "steer_forward", "steer_back", "accelerate", "brake_reverse", "radio_next", "radio_previous", "radio_user_track_skip", "horn", "sub_mission",
 "handbrake", "vehicle_look_left", "vehicle_look_right", "vehicle_look_behind", "vehicle_mouse_look", "special_control_left", "special_control_right",
 "special_control_down", "special_control_up" }
    for _, control in pairs(controlTable) do
        toggleControl(control, bool)
    end
    output(string.format("Turned all GTA binds %s", bool and "on" or "off"))
end



function CGame.unloadGTAWorld()
    localPlayer:setDimension(CGame.dimension)
    localPlayer:setAlpha(0)
    setElementCollisionsEnabled(localPlayer, false)
    setCloudsEnabled(false)
    setFarClipDistance(0)
    setFogDistance(0)
    setGravity(0)
    setColorFilter (0, 0, 0, 0, 0, 0, 0, 0)
    setMoonSize(0)
    setSunSize(0)
    setGameSpeed(0)
    setTimeFrozen(true)
    setPlayerHudComponentVisible("all", false)
    showChat(false)
    removeGameWorld()
    output("Unloaded GTA World and its properties and physics")
end

function CGame.loadGTAWorld()
    localPlayer:setDimension(0)
    localPlayer:setAlpha(255)
    setElementCollisionsEnabled(localPlayer, true)
    setCloudsEnabled(true)
    resetFarClipDistance()
    resetFogDistance()
    setGravity(0.008)
    resetColorFilter()
    resetMoonSize()
    resetSunSize()
    setGameSpeed(1)
    setTimeFrozen(false)
    setPlayerHudComponentVisible("all", true)
    showChat(true)
    restoreGameWorld()
    output("Restored GTA World and its properties and physics")
end

function CGame.createBackground()
    CGame.rtBackground = DxRenderTarget(1, 1, false)
    dxSetRenderTarget(CGame.rtBackground, true)
    dxDrawRectangle(0, 0, 1, 1, tocolor(0, 0, 0, 255))
    dxSetRenderTarget()
end

function CGame.drawBackground()
    --dxDrawRectangle(sw - 70, sh - 20, 70, 20, tocolor(0, 0, 0, 255), true) -- hide mta watermark
    dxDrawImage(0, 0, sw, sh, CGame.rtBackground, 0, 0, 0, tocolor(255, 255, 255, 255), CGame.postgui)
    local i = 1
    CLife.statistics.fps = getElementData(localPlayer, "p_fps") or 0
    CLife.statistics.time = getTickCount() - CLife.startTick
    for statistic, value in pairs(CLife.statistics) do
        local yPos = i * 20 - 20
        dxDrawText(strf("%s: %d", statistic, value), 10, yPos)
        i = i + 1
    end
end

function CGame.processBehaviour()
    local fps = getElementData(localPlayer, "p_fps") and tonumber(getElementData(localPlayer, "p_fps"))
    if (fps and fps < 25) then
        CLife.populationControl = true
    else
        CLife.populationControl = false
    end
end

function CGame.drawScene()
    CLife.attempt(math.random(0, sw), math.random(0, sh))
    for i, life in pairs(CLife.instances) do
        if (life.alive) then
            life:move()
        end
        dxDrawRectangle(life.x, life.y, life.traits.width, life.traits.height, tocolor(life.traits.color[1], life.traits.color[2], life.traits.color[3], life.traits.color[4]), CGame.postgui)
        if (life.alive) then
            dxDrawText(life.name, life.x, life.y)
        end
    end
    CLife.expireDead()
end

function CGame.tick()
    --if (CMenu:isRendering()) then
        --CMenu.render()
    --end
    CGame.drawBackground()
    CGame.processBehaviour()
    CGame.drawScene()
end

function CGame.onStart()
    CGame.toggleGTABinds(false)
    CGame.unloadGTAWorld()
    CGame.createBackground()
    CGame.startTick = getTickCount()
    addEventHandler("onClientRender", root, CGame.tick)
    --CMenu:setRendering(true)
end
addEventHandler("onClientResourceStart", resourceRoot, CGame.onStart)

function CGame.onStop()
    removeEventHandler("onClientRender", root, CGame.tick)
    CGame.toggleGTABinds(true)
    CGame.loadGTAWorld()
end
addEventHandler("onClientResourceStop", resourceRoot, CGame.onStop)