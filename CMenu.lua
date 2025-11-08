sw, sh = guiGetScreenSize()

CMenu = {
    rendering = true,
    options = {
        ["New"] = {text = "New Game"},
        ["Load"] = {text = "Load Game"},
        ["Settings"] = {text = "Settings"},
        ["Quit"] = {text = "Quit"},
    },
    xPos = sw * 0.8,
    yPos = sh * 0.3,
    optionSpacing = 50,
}



function CMenu:isRendering()
    return CMenu.rendering
end

function CMenu:setRendering(bool)
    if (bool) then
        if (not CMenu:isRendering()) then
            CMenu.rendering = true
            showCursor(true)
        end
    else
        if (CMenu:isRendering()) then
            CMenu.rendering = false
            showCursor(false)
        end
    end
end

function CMenu.render()
    local i = 0
    for option, optionData in pairs(CMenu.options) do
        i = i + 1
        local yPos = CMenu.yPos + i*CMenu.optionSpacing - CMenu.optionSpacing
        dxDrawText(optionData.text, CMenu.xPos, yPos, 0, 0, tocolor(255, 255, 255, 255), 2, "bankgothic", "left", "top")
    end
end