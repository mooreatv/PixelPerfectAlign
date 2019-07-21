--[[
   PixelPerfectAlign by MooreaTV moorea@ymail.com (c) 2019 All rights reserved
   Licensed under LGPLv3 - No Warranty
   (contact the author if you need a different license)

   Demonstrates pixel perfect handling from MoLib

   Feel free to embed/use MoLib according to the license but not
   just copy paste what you want from it into your addon.
   https://github.com/mooreatv/MoLib

   Please contact the author if you're interested in doing more/using it.
   ]] --
--
-- our name, our empty default (and unused) anonymous ns
local addon, _ns = ...

-- Table and base functions created by MoLib
local PPA = _G[addon]
-- localization
PPA.L = PPA:GetLocalization()
local L = PPA.L

-- PPA.debug = 9 -- to debug before saved variables are loaded

function PPA:ShowGrid()
  PPA:Debug(2, "Show grid called")
  if not PPA.grid then
    PPA:Debug(1, "Creating the grid")
    PPA.grid = PPA:FineGrid(12, 12)
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
  local showAndHideGrid = not PPA.gridShown
  if showAndHideGrid then
    PPA:ShowGrid()
  end
  PPA:WipeFrame(PPA.displayInfo)
  PPA.displayInfo = PPA:DisplayInfo(-100, -100, 2)
  C_Timer.After(seconds, function()
    if showAndHideGrid then
      PPA:HideGrid()
    end
    PPA.displayInfo:Hide()
  end)
end

PPA.EventHdlrs = {

  PLAYER_ENTERING_WORLD = function(_self, ...)
    PPA:Debug("OnPlayerEnteringWorld " .. PPA:Dump(...))
    PPA:CreateOptionsPanel()
  end,

  UPDATE_BINDINGS = function(_self, ...)
    PPA:DebugEvCall(1, ...)
  end,

  DISPLAY_SIZE_CHANGED = function(_self, ...)
    PPA:DebugEvCall(1, ...)
  end,

  UI_SCALE_CHANGED = function(_self, ...)
    PPA:DebugEvCall(1, ...)
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

function PPA:SetSaved(name, value)
  self[name] = value
  pixelPerfectAlignSaved[name] = value
  PPA:Debug(5, "(Saved) Setting % set to % - pixelPerfectAlignSaved=%", name, value, pixelPerfectAlignSaved)
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
  elseif cmd == "s" then
    PPA:HideGrid()
  elseif cmd == "t" then
    PPA:ToggleGrid()
  elseif cmd == "i" then
    PPA:ShowDisplayInfo(5)
  elseif cmd == "v" then
    -- version
    PPA:PrintDefault("PixelPerfectAlign " .. PPA.manifestVersion ..
                       " (@project-abbreviated-hash@) by MooreaTv (moorea@ymail.com)")
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

  p:addButton(L["Toggle Grid"],
              L["Toggles the grid between shown and hidden"] .. "\n|cFF99E5FF/ppa toggle|r " .. L["or Key Binding"],
              "toggle"):Place()

  p:addButton(L["Display Info"],
              L["Displays screen/resolution information for a few seconds"] .. "\n|cFF99E5FF/ppa info|r", "info")
    :Place()

  p:addText(L["Development, troubleshooting and advanced options:"]):Place(40, 20)

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
  end

  function p:HandleOk()
    PPA:Debug(1, "PPA.optionsPanel.okay() internal")
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
_G.BINDING_HEADER_PPA = L["Pixel Perfect Align addon key bindings"]
_G.BINDING_NAME_PPA_TOGGLE = L["Toggle grid"] .. " |cFF99E5FF/ppa toggle|r"

-- PPA.debug = 2
PPA:Debug("ppa main file loaded")
