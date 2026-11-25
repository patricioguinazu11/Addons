-- Simulación mínima de la API de WoW para ejecutar el addon fuera del juego
local frames = {}
local function noop() end
local Obj = {}
local function new(kind, name)
  local o = { __kind = kind, __scripts = {}, __events = {}, __shown = true, __text = "", __children = {} }
  setmetatable(o, Obj)
  if name then _G[name] = o end
  table.insert(frames, o)
  return o
end
local methods = {}
Obj.__index = function(t, k)
  if methods[k] then return methods[k] end
  return function() return nil end
end
function methods:CreateFontString() local f = new("FontString"); return f end
function methods:CreateTexture() return new("Texture") end
function methods:SetScript(e, f) self.__scripts[e] = f end
function methods:GetScript(e) return self.__scripts[e] end
function methods:HookScript(e, f) self.__scripts[e] = f end
function methods:RegisterEvent(e) self.__events[e] = true end
function methods:SetText(t) self.__text = t == nil and "" or tostring(t) end
function methods:GetText() return self.__text end
function methods:GetStringHeight() local n = 1; for _ in tostring(self.__text):gmatch("\n") do n = n + 1 end; return 14 * n end
function methods:GetStringWidth() return #tostring(self.__text) * 6 end
function methods:Show() self.__shown = true end
function methods:Hide() self.__shown = false end
function methods:SetShown(v) self.__shown = v and true or false end
function methods:IsShown() return self.__shown end
function methods:GetWidth() return 300 end
function methods:GetHeight() return 20 end
function methods:GetNumber() return 0 end
function methods:GetItem() return "Item", nil end
function methods:SetFont() return true end
function methods:GetEffectiveScale() return 1 end
function methods:GetCenter() return 0, 0 end
function methods:NumLines() return 0 end
function methods:StartMoving() end
_G.__frames = frames
_G.__fire = function(event, ...)
  for _, f in ipairs(frames) do
    if f.__events[event] and f.__scripts.OnEvent then f.__scripts.OnEvent(f, event, ...) end
  end
end
_G.CreateFrame = function(kind, name, parent, template) return new(kind, name) end
UIParent = new("Frame"); Minimap = new("Frame"); WorldFrame = new("Frame")
GameTooltip = new("GameTooltip"); ItemRefTooltip = new("GameTooltip"); DEFAULT_CHAT_FRAME = new("Frame")
DEFAULT_CHAT_FRAME.AddMessage = function(self, m) table.insert(_G.__chat, m) end
_G.__chat = {}
GameTooltip_Hide = noop; UISpecialFrames = {}; tinsert = table.insert; wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
strsplit = function(sep, s) return s end
BackdropTemplateMixin = {}; SOUNDKIT = {}; PlaySound = noop; SetPortraitTexture = noop
CLASS_ICON_TCOORDS = { SHAMAN = { 0.25, 0.49, 0.25, 0.5 } }
CreateColor = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end
C_Timer = { After = function(t, f) table.insert(_G.__timers, f) end, NewTicker = function(t, f) return { Cancel = noop } end }
_G.__timers = {}
time = os.time; GetTime = os.clock
UnitLevel = function() return 24 end; UnitName = function() return "Piolin" end; UnitClass = function() return "Chamán", "SHAMAN" end
UnitXP = function() return 6200 end; UnitXPMax = function() return 14000 end; GetXPExhaustion = function() return 3000 end
UnitCharacterPoints = function() return 1 end; GetMoney = function() return 234112 end
GetInventoryItemID = function(u, s) if s == 2 or s == 14 or s == 18 then return nil end return 1000 + s end
GetInventoryItemTexture = function(u, s) if GetInventoryItemID(u, s) then return "tex" end end
GetInventoryItemLink = function() return nil end
GetInventoryItemDurability = function(s) return 31, 50 end
local SK = { { "Pesca", 147, 150 }, { "Cocina", 132, 150 }, { "Desuello", 150, 150 }, { "Peletería", 118, 150 } }
GetNumSkillLines = function() return #SK end
GetSkillLineInfo = function(i) local s = SK[i]; return s[1], false, nil, s[2], nil, nil, s[3] end
GetItemCount = function(id) return id == 4233 and 12 or 4 end
GetItemInfo = function(x) return "Objeto", "|cff|Hitem:" .. tostring(x) .. "|h[x]|h|r", 1, 10, 1, "", "", 20, "INVTYPE_HEAD", "", 25, 4, 2 end
GetItemIcon = function() return "tex" end
GetCoinTextureString = function(c) return tostring(c) .. "c" end
GetSpellInfo = function() return "Escudo de relámpagos" end
C_QuestLog = { IsQuestFlaggedCompleted = function(id) return id == 168 end }
GetWeaponEnchantInfo = function() return false end
UnitBuff = function() return nil end
GetCursorPosition = function() return 0, 0 end
GetNumAuctionItems = function() return 0, 0 end
CanSendAuctionQuery = function() return true end
InCombatLockdown = function() return false end
GetMacroIndexByName = function() return 0 end
CreateMacro = noop
SlashCmdList = {}
IsTradeskillTrainer = function() return false end
GetRepairAllCost = function() return 500, true end
CanMerchantRepair = function() return true end
RepairAllItems = noop
C_Container = { GetContainerNumSlots = function() return 0 end }
unpack = table.unpack; select = select; math.atan2 = math.atan2 or math.atan
GetInventorySlotInfo = function(n) return 1, "Interface\\PaperDoll\\UI-PaperDoll-Slot-" .. n end
GetInventoryItemQuality = function() return 2 end
GetItemQualityColor = function() return 0.1, 1, 0, "ff1eff00" end
local QL = { { "Minas de la Muerte", 0, nil, true }, { "La Hermandad Defias", 22, nil, false, nil, 1, nil, 166 }, { "Recolección de recuerdos", 18, nil, false, nil, nil, nil, 168 }, { "Ratas de la granja", 9, nil, false, nil, nil, nil, 999 } }
GetNumQuestLogEntries = function() return #QL end
GetQuestLogTitle = function(i) local q = QL[i]; return q[1], q[2], q[3], q[4], nil, q[6], nil, q[8] end
GetQuestGreenRange = function() return 8 end
hooksecurefunc = function(t, k, f) end
WorldMapFrame = CreateFrame("Frame"); WorldMapFrame.ScrollContainer = { Child = CreateFrame("Frame") }
WorldMapFrame.GetMapID = function() return 1433 end
local V = { GetXY = function() return 0.30, 0.60 end }
C_Map = { GetPlayerMapPosition = function() return V end, GetMapWorldSize = function() return 2170, 1447 end, GetMapInfo = function() return { name = "Crestagrana" } end, GetBestMapForUnit = function() return 1433 end }
GetPlayerFacing = function() return 1.2 end
InterfaceOptions_AddCategory = function() end
InterfaceOptionsFrame_OpenToCategory = function() end
StaticPopupDialogs = {}; StaticPopup_Show = function() end
local bound
GetBindingKey = function() return bound end
SetBinding = function(k, a) bound = a and k or nil; return true end
SaveBindings = function() end; GetCurrentBindingSet = function() return 1 end
IsAltKeyDown = function() return false end; IsControlKeyDown = function() return false end; IsShiftKeyDown = function() return true end
__dd = {}
UIDropDownMenu_SetWidth = function() end
UIDropDownMenu_Initialize = function(f, fn) table.insert(__dd, { f = f, fn = fn }) end
UIDropDownMenu_CreateInfo = function() return {} end
UIDropDownMenu_AddButton = function(info) __lastInfo = info end
UIDropDownMenu_SetText = function(f, t) f.__ddtext = t end
local cv = { Sound_DialogVolume = "0.8" }
__cv = cv
GetCVar = function(k) return cv[k] end
SetCVar = function(k, v) cv[k] = tostring(v) end
__played = {}
PlaySound = function(id, ch) table.insert(__played, tostring(id) .. ":" .. tostring(ch)) end
function methods:GetMinMaxValues() return 0, 1 end
function methods:IsVisible() return true end
function methods:GetEffectiveScale() return 1 end
function methods:GetFrameLevel() return 1 end
function methods:CreateAnimationGroup() return CreateFrame("AnimationGroup") end
