--[[
   PixelPerfectAlign by MooreaTV moorea@ymail.com (c) 2019 All rights reserved
   Licensed under LGPLv3 - No Warranty
   (contact the author if you need a different license)

   Demonstrates pixel perfect handling from MoLib

   Feel free to embed/use MoLib according to the license but not
   just copy paste what you want from it into your addon.
   https://github.com/mooreatv/MoLib

   Please contact the author if you're interested in doing more/using it.

   Get this addon binary release using curse/twitch client or on wowinterface
   The source of the addon resides on https://github.com/mooreatv/PixelPerfectAlign
   (and the MoLib library at https://github.com/mooreatv/MoLib)

   Releases detail/changes are on https://github.com/mooreatv/PixelPerfectAlign/releases 
   ]] --
--
-- our name, our empty default (and unused) anonymous ns
local addon, _ns = ...

-- Table and base functions created by MoLib
local PPA = _G[addon]
-- localization
PPA.L = PPA:GetLocalization()
local L = PPA.L

PPA.showSplash = 0 -- how long to show splash at start
PPA.startWithGridOn = false -- start with grid showing?
PPA.lineLength = 16
PPA.numX = 16 -- 0 is auto is 16 / aspect ratio
PPA.numY = 0 -- 0 is auto / aspect ratio

-- PPA.debug = 9 -- to debug before saved variables are loaded

function PPA:ShowGrid()
  PPA:Debug(2, "Show grid called")
  if not PPA.grid then
    PPA:Debug(1, "Creating the grid")
    local nX = PPA.numX
    local nY = PPA.numY
    if nY == 0 then
      nY = PPA:AspectRatio(nX)
    end
    PPA.grid = PPA:FineGrid(nX, nY, PPA.lineLength, "PPA_Grid", UIParent)
  end
  PPA.grid:Show()
  PPA.gridShown = true
end

function PPA:HideGrid()
  PPA:Debug(2, "Hide grid called")
  if PPA.gridShown and PPA.grid then
    PPA:Debug(1, "Hiding the grid")
    PPA.grid:Hide()
  end
  PPA.gridShown = false
end

function PPA:ToggleGrid()
  if PPA.gridShown then
    PPA:HideGrid()
  else
    PPA:ShowGrid()
  end
end

function PPA:ShowDisplayInfo(seconds)
  PPA:WipeFrame(PPA.displayInfo)
  PPA.displayInfo = PPA:DisplayInfo(-250, -300, 1.5)
  C_Timer.After(seconds, function()
    PPA.displayInfo:Hide()
  end)
end

function PPA:SetupMenu()
  PPA:WipeFrame(PPA.mmb)
  local b = PPA:minimapButton(PPA.buttonPos)
  local s, w, h = PPA:PixelPerfectSnap(b)
  self:Debug("new w % h %", w, h)
  local icon = CreateFrame("Frame", nil, b)
  -- set scale to be pixels
  icon:SetScale(s / icon:GetEffectiveScale())
  PPA:Debug("Scale is now % es % ppf es %", icon:GetScale(), icon:GetEffectiveScale(), s)
  local delta = math.floor((w - 32) / 2)
  icon:SetPoint("BOTTOMLEFT", delta, delta)
  icon:SetFlattensRenderLayers(true)
  icon:SetSize(48, 48)
  icon:SetIgnoreParentAlpha(true)
  -- based on 32x32
  local start = 11.5
  local off = 4
  self:Debug("off is %", off)
  if delta >= 1 then
    off = off + PPA:round((w - 32) / 4)
  end
  local len = .75
  local width = .75
  local other = start + 2 * off
  PPA:DrawCross(icon, start, start, len, 0, width, PPA.gold)
  PPA:DrawCross(icon, start, other, len, 0, width, PPA.gold)
  PPA:DrawCross(icon, start + off, start + off, len, 0, width, PPA.red) -- 1 red pixel
  PPA:DrawCross(icon, other, start, len, 0, width, PPA.gold)
  PPA:DrawCross(icon, other, other, len, 0, width, PPA.gold)
  b:SetScript("OnClick", function(_w, button, _down)
    if button == "RightButton" then
      PPA.Slash("config")
    else
      if IsShiftKeyDown() then
        PPA.Slash("info")
      else
        PPA.Slash("toggle")
      end
    end
  end)
  b.tooltipText = "|cFFF2D80CPixel Perfect Align|r:\n" ..
                    L["|cFF99E5FFLeft|r click to toggle grid\n|cFF99E5FFShift left|r click for info display\n" ..
                      "|cFF99E5FFRight|r click for options\n\n" ..
                      "Hold |cFF99E5FFControl|r starting from here,\nor |cFF99E5FF/ppa coords|r or the key binding,\n" ..
                      "for cursor/screen coordinates\n\n" .. "Drag to move this button."]
  b:SetScript("OnEnter", function()
    PPA:ShowToolTip(b, "ANCHOR_LEFT")
    PPA.inButton = true
  end)
  b:SetScript("OnLeave", function()
    GameTooltip:Hide()
    PPA.inButton = false
    PPA:Debug("Hide tool tip...")
  end)
  PPA:MakeMoveable(b, PPA.SavePositionCB)
  PPA.mmb = b
  PPA.mmb.icon = icon
end

function PPA.SavePositionCB(_f, pos, _scale)
  PPA:SetSaved("buttonPos", pos)
end

function PPA:ShowCoordinates(keep)
  if PPA.coordinateShown then
    return -- already shown, nothing to do
  end
  PPA.coordinateShown = true
  PPA.coordinateKeep = keep
  local f = PPA.coordinateFrame
  local pad = 1 / 32
  if not f then
    f = PPA:Frame()
    PPA.coordinateFrame = f
    f:SetFrameStrata("FULLSCREEN")
    f:SetMovable(true)
    local r, g, b, alpha = 1, .8, .4, 0.95
    f.txt = f:addText("Pixel XXXX , YYYY\nUI xxxx.xx , yyyy.yy", "NumberFont_Outline_Large")
    f.txt:SetPoint("BOTTOMRIGHT", -4, 4)
    f.txt:SetJustifyH("RIGHT")
    f.txt:SetJustifyV("BOTTOM")
    f.txt:SetTextColor(r, g, b, alpha)
    local thickness = 1
    local layer = "BACKGROUND"
    local len = 10 + pad
    f:SetSize(2 * len, 2 * len) -- just for having something to debug/see with dbg level 8
    local bottom = f:addLine(thickness, r, g, b, alpha, layer, true)
    bottom:SetStartPoint("BOTTOMRIGHT", -1 - pad, pad)
    bottom:SetEndPoint("BOTTOMRIGHT", -len, pad)
    local right = f:addLine(thickness, r, g, b, alpha, layer, true)
    right:SetStartPoint("BOTTOMRIGHT", -pad, 1 + pad)
    right:SetEndPoint("BOTTOMRIGHT", -pad, len)
  end
  f:SetScript("OnUpdate", function(_w)
    f.txt:SetText(string.format("Pixel %d , %d\nUI %.2f , %.2f", PPA:GetCursorCoordinates()))
  end)
  local uiScale, x, y = f:GetParent():GetEffectiveScale(), GetCursorPosition()
  f:SetPoint("BOTTOMRIGHT", nil, "BOTTOMLEFT", x / uiScale, y / uiScale) -- opposite side of std cursor
  f:Show()
  f:StartMoving()
  PPA:Debug("Showing coordinates")
end

function PPA:HideCoordinates()
  if not PPA.coordinateShown then
    return -- already hidden, nothing to do
  end
  PPA.coordinateFrame:StopMovingOrSizing()
  PPA.coordinateFrame:SetScript("OnUpdate", nil)
  C_Timer.After(5, function()
    PPA.coordinateShown = nil
    PPA.coordinateFrame:ClearAllPoints()
    PPA.coordinateFrame:Hide()
  end)
  PPA:Debug("Hiding coordinates (in 4 sec)")
end

PPA.EventHdlrs = {

  MODIFIER_STATE_CHANGED = function(_self, ...)
    PPA:DebugEvCall(1, ...)
    if IsControlKeyDown() then
      if PPA.inButton then
        GameTooltip:Hide()
        PPA:ShowCoordinates()
      end
    else
      if not PPA.coordinateKeep then
        PPA:HideCoordinates()
      end
    end
  end,

  PLAYER_ENTERING_WORLD = function(_self, ...)
    PPA:Debug("OnPlayerEnteringWorld " .. PPA:Dump(...))
    PPA:CreateOptionsPanel()
    if PPA.startWithGridOn then
      PPA:ShowGrid()
    end
    if PPA.showSplash > 0 then
      PPA:ShowDisplayInfo(PPA.showSplash)
    end
    PPA:SetupMenu()
  end,

  UPDATE_BINDINGS = function(_self, ...)
    PPA:DebugEvCall(1, ...)
  end,

  DISPLAY_SIZE_CHANGED = function(_self)
    -- Always wipe (fast the 2nd time) so when showing again next it's built correctly.
    PPA.grid = PPA:WipeFrame(PPA.grid)
    if PPA.gridShown then
      PPA:Debug("Grid is shown and we are resizing so re-drawing the grid")
      -- TODO consider buffering as there is often 2+ events, or checking for actual change
      PPA:ShowGrid()
    end
    if PPA.mmb then
      PPA:SetupMenu() -- should be able to just RestorePosition() but...
    end
  end,

  UI_SCALE_CHANGED = function(_self, ...)
    PPA:DebugEvCall(1, ...)
    if PPA.mmb then
      PPA:SetupMenu() -- buffer with the one above?
    end
  end,

  ADDON_LOADED = function(_self, _event, name)
    PPA:Debug(9, "Addon % loaded", name)
    if name ~= addon then
      return -- not us, return
    end
    -- check for dev version (need to split the tags or they get substituted)
    if PPA.manifestVersion == "@" .. "project-version" .. "@" then
      PPA.manifestVersion = "vX.YY.ZZ"
    end
    PPA:PrintDefault("PixelPerfectAlign " .. PPA.manifestVersion .. " by MooreaTv: type /ppa for command list/help.")
    if pixelPerfectAlignSaved == nil then
      PPA:Debug("Initialized empty saved vars")
      pixelPerfectAlignSaved = {}
    end
    pixelPerfectAlignSaved.addonVersion = PPA.manifestVersion
    pixelPerfectAlignSaved.addonHash = "@project-abbreviated-hash@"
    PPA:deepmerge(PPA, nil, pixelPerfectAlignSaved)
    PPA:Debug(3, "Merged in saved variables.")
  end
}

function PPA:OnEvent(event, first, ...)
  PPA:Debug(8, "OnEvent called for % e=% %", self:GetName(), event, first)
  local handler = PPA.EventHdlrs[event]
  if handler then
    return handler(self, event, first, ...)
  end
  PPA:Error("Unexpected event without handler %", event)
end

function PPA:Help(msg)
  PPA:PrintDefault("PixelPerfectAlign: " .. msg .. "\n" .. "/ppa show -- shows the grid\n" ..
                     "/ppa hide -- hides the grid\n" .. "/ppa toggle -- toggles show/hide\n" ..
                     "/ppa info -- displays info about screen and resolution for a few seconds\n" ..
                     "/ppa config -- open addon config\n" ..
                     "/ppa debug on/off/level -- for debugging on at level or off.\n" ..
                     "/ppa version -- shows addon version")
end

-- returns 1 if changed, 0 if same as live value
-- number instead of boolean so we can add them in handleOk
-- (saved var isn't checked/always set)
function PPA:SetSaved(name, value)
  local changed = (value ~= self[name])
  self[name] = value
  pixelPerfectAlignSaved[name] = value
  PPA:Debug(8, "(Saved) Setting % set to % - pixelPerfectAlignSaved=%", name, value, pixelPerfectAlignSaved)
  if changed then
    return 1
  else
    return 0
  end
end

function PPA.Slash(arg) -- can't be a : because used directly as slash command
  PPA:Debug("Got slash cmd: %", arg)
  if #arg == 0 then
    PPA:Help("commands, you can use the first letter of each:")
    return
  end
  local cmd = string.lower(string.sub(arg, 1, 1))
  local posRest = string.find(arg, " ")
  local rest = ""
  if not (posRest == nil) then
    rest = string.sub(arg, posRest + 1)
  end
  if cmd == "s" then
    -- show
    PPA:ShowGrid()
  elseif cmd == "h" then
    PPA:HideGrid()
  elseif cmd == "t" then
    PPA:ToggleGrid()
  elseif cmd == "i" then
    local sec = 8
    PPA:PrintDefault("PixelPerfectAlign showing display (debug) info for % seconds", sec)
    PPA:ShowDisplayInfo(sec)
  elseif cmd == "v" then
    -- version
    PPA:PrintDefault("PixelPerfectAlign " .. PPA.manifestVersion ..
                       " (@project-abbreviated-hash@) by MooreaTv (moorea@ymail.com)")
  elseif PPA:StartsWith(arg, "coord") then
    if PPA.coordinateShown then
      PPA:PrintDefault("PixelPerfectAlign coordinates update OFF, keeping visible for a few seconds.")
      PPA:HideCoordinates()
    else
      PPA:PrintDefault("PixelPerfectAlign coordinates ON.")
      PPA:ShowCoordinates(true)
    end
  elseif cmd == "c" then
    -- Show config panel
    -- InterfaceOptionsList_DisplayPanel(PPA.optionsPanel)
    InterfaceOptionsFrame:Show() -- onshow will clear the category if not already displayed
    InterfaceOptionsFrame_OpenToCategory(PPA.optionsPanel) -- gets our name selected
  elseif cmd == "e" then
    -- copied from PixelPerfectAlign, as augment on event trace
    UIParentLoadAddOn("Blizzard_DebugTools")
    -- hook our code, only once/if there are no other hooks
    if EventTraceFrame:GetScript("OnShow") == EventTraceFrame_OnShow then
      EventTraceFrame:HookScript("OnShow", function()
        EventTraceFrame.ignoredEvents = PPA:CloneTable(PPA.etraceIgnored)
        PPA:PrintDefault("Restored ignored etrace events: %", PPA.etraceIgnored)
      end)
    else
      PPA:Debug(3, "EventTraceFrame:OnShow already hooked, hopefully to ours")
    end
    -- save or anything starting with s that isn't the start/stop commands of actual eventtrace
    if PPA:StartsWith(rest, "s") and rest ~= "start" and rest ~= "stop" then
      PPA:SetSaved("etraceIgnored", PPA:CloneTable(EventTraceFrame.ignoredEvents))
      PPA:PrintDefault("Saved ignored etrace events: %", PPA.etraceIgnored)
    elseif PPA:StartsWith(rest, "c") then
      EventTraceFrame.ignoredEvents = {}
      PPA:PrintDefault("Cleared the current event filters")
    else -- leave the other sub commands unchanged, like start/stop and n
      PPA:Debug("Calling  EventTraceFrame_HandleSlashCmd(%)", rest)
      EventTraceFrame_HandleSlashCmd(rest)
    end
  elseif PPA:StartsWith(arg, "debug") then
    -- debug
    if rest == "on" then
      PPA:SetSaved("debug", 1)
    elseif rest == "off" then
      PPA:SetSaved("debug", nil)
    else
      PPA:SetSaved("debug", tonumber(rest))
    end
    PPA:PrintDefault("DynBoxer debug now %", PPA.debug)
  else
    PPA:Help('unknown command "' .. arg .. '", usage:')
  end
end

-- Run/set at load time:

-- Slash

SlashCmdList["PixelPerfectAlign_Slash_Command"] = PPA.Slash

SLASH_PixelPerfectAlign_Slash_Command1 = "/ppa"
SLASH_PixelPerfectAlign_Slash_Command2 = "/align"

-- Events handling
PPA.frame = CreateFrame("Frame")

PPA.frame:SetScript("OnEvent", PPA.OnEvent)
for k, _ in pairs(PPA.EventHdlrs) do
  PPA.frame:RegisterEvent(k)
end

-- Options panel

function PPA:CreateOptionsPanel()
  if PPA.optionsPanel then
    PPA:Debug("Options Panel already setup")
    return
  end
  PPA:Debug("Creating Options Panel")

  local p = PPA:Frame(L["PixelPerfectAlign"])
  PPA.optionsPanel = p
  p:addText(L["PixelPerfectAlign options"], "GameFontNormalLarge"):Place()
  p:addText(L["These options let you control the behavior of PixelPerfectAlign"] .. " " .. PPA.manifestVersion ..
              " @project-abbreviated-hash@"):Place()

  local lineLengthSlider = p:addSlider(L["Grid line length"], L["How many pixels for the lines/crosses drawn"], 1, 128,
                                       1):Place(8, 24)

  local startWithGrid = p:addCheckBox(L["Show Grid from start"], L["Whether we should start with the Grid shown"])
                          :Place(4, 12)

  -- we can't put more than 16k textures at a time in our frame so limit the sliders accordingly
  local numXSlider = p:addSlider(L["Horizontal grid intervals"], L["How many intervals horizontally."], 2, 92, 1):Place(
                       8, 24)

  local numYSlider = p:addSlider(L["Vertical grid intervals"],
                                 L["How many intervals vertically.\nWill be based on aspect ratio when set to Auto"], 0,
                                 84, 1, L["Auto"])
  numYSlider:Place(8, 24)

  p:addButton(L["Toggle Grid"],
              L["Toggles the grid between shown and hidden"] .. "\n|cFF99E5FF/ppa toggle|r " .. L["or Key Binding"],
              "toggle"):Place(4, 20)

  p:addButton(L["Display Info"], L["Displays screen/resolution information for a few seconds"] ..
                "\n|cFF99E5FF/ppa info|r " .. L["or Key Binding"], "info"):PlaceRight()

  local showSplash = p:addSlider(L["Show Info at login"],
                                 L["How long if at all to show the grid and information at login"], 0, 9, 3, L["Off"],
                                 L["9 seconds"], {[3] = "3 s", [6] = "6 s", [9] = "9 s"}):Place(8, 24)

  p:addText(L["Development, troubleshooting and advanced options:"]):Place(40, 20)

  p:addButton(L["Reset minimap button"], L["Resets the minimap button to back to initial default location"], function()
    PPA:SetSaved("buttonPos", nil)
    PPA:SetupMenu()
  end):Place(4, 20)

  local debugLevel = p:addSlider(L["Debug level"], L["Sets the debug level"] .. "\n|cFF99E5FF/ppa debug X|r", 0, 9, 1,
                                 "Off"):Place(16, 30)

  p:addButton(L["Event Trace"], L["Starts the blizzard Event Trace with saved filters"] .. "\n|cFF99E5FF/ppa event|r",
              "event"):Place(0, 20)

  p:addButton(L["Save Filters"], L["Saves the set of currently filtered Events"] .. "\n|cFF99E5FF/ppa event save|r",
              "event save"):PlaceRight()

  p:addButton(L["Clear Filters"], L["Clear saved filtered Events"] .. "\n|cFF99E5FF/ppa event clear|r", "event clear")
    :PlaceRight()

  function p:refresh()
    PPA:Debug("Options Panel refresh!")
    if PPA.debug then
      -- expose errors
      xpcall(function()
        self:HandleRefresh()
      end, geterrorhandler())
    else
      -- normal behavior for interface option panel: errors swallowed by caller
      self:HandleRefresh()
    end
  end

  function p:HandleRefresh()
    p:Init()
    debugLevel:SetValue(PPA.debug or 0)
    showSplash:SetValue(PPA.showSplash)
    startWithGrid:SetChecked(PPA.startWithGridOn)
    lineLengthSlider:SetValue(PPA.lineLength)
    numXSlider:SetValue(PPA.numX)
    numYSlider:SetValue(PPA.numY)
    p.oldStart = PPA.startWithGridOn
  end

  function p:HandleOk()
    PPA:Debug(1, "PPA.optionsPanel.okay() internal")
    local changes = 0
    changes = changes + PPA:SetSaved("lineLength", lineLengthSlider:GetValue())
    changes = changes + PPA:SetSaved("numX", numXSlider:GetValue())
    changes = changes + PPA:SetSaved("numY", numYSlider:GetValue())
    if changes > 0 then
      PPA:PrintDefault("PPA: % change(s) made to grid config", changes)
      PPA.grid = PPA:WipeFrame(PPA.grid) -- be ready for next show
      if PPA.gridShown then
        PPA:ShowGrid()
      end
    end
    local sliderVal = debugLevel:GetValue()
    if sliderVal == 0 then
      sliderVal = nil
      if PPA.debug then
        PPA:PrintDefault("Options setting debug level changed from % to OFF.", PPA.debug)
      end
    else
      if PPA.debug ~= sliderVal then
        PPA:PrintDefault("Options setting debug level changed from % to %.", PPA.debug, sliderVal)
      end
    end
    PPA:SetSaved("debug", sliderVal)
    PPA:SetSaved("showSplash", showSplash:GetValue())
    PPA:SetSaved("startWithGridOn", startWithGrid:GetChecked())
    if p.oldStart ~= PPA.startWithGridOn then
      PPA:PrintDefault("PPA: Changed start with grid to " .. (PPA.startWithGridOn and "ON" or "OFF"))
      if PPA.startWithGridOn then
        PPA:ShowGrid()
      else
        PPA:HideGrid()
      end
    end
  end

  function p:cancel()
    PPA:Warning("Options screen cancelled, not making any changes.")
  end

  function p:okay()
    PPA:Debug(3, "PPA.optionsPanel.okay() wrapper")
    if PPA.debug then
      -- expose errors
      xpcall(function()
        self:HandleOk()
      end, geterrorhandler())
    else
      -- normal behavior for interface option panel: errors swallowed by caller
      self:HandleOk()
    end
  end
  -- Add the panel to the Interface Options
  InterfaceOptions_AddCategory(PPA.optionsPanel)
end

-- bindings / localization
_G.PIXELPERFECTALIGN = "PixelPerfectAlign"
_G.BINDING_HEADER_PPA = L["Pixel Perfect Align addon key bindings"]
_G.BINDING_NAME_PPA_TOGGLE = L["Toggle Grid"] .. " |cFF99E5FF/ppa toggle|r"
_G.BINDING_NAME_PPA_INFO = L["Show Display Info"] .. " |cFF99E5FF/ppa info|r"
_G.BINDING_NAME_PPA_COORDS = L["Toogle screen coordinates"] .. " |cFF99E5FF/ppa coords|r"

-- PPA.debug = 2
PPA:Debug("ppa main file loaded")
