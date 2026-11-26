-- Simula el motor moderno (Midnight / Forever): sin funciones de Classic
local legacy = { "GetSpellInfo", "GetItemInfo", "GetItemIcon", "GetItemCount", "UnitBuff", "GetNumSkillLines", "GetSkillLineInfo",
  "GetNumQuestLogEntries", "GetQuestLogTitle", "GetQuestGreenRange", "UnitCharacterPoints", "InterfaceOptions_AddCategory",
  "InterfaceOptionsFrame_OpenToCategory", "UIDropDownMenu_SetWidth", "UIDropDownMenu_Initialize", "UIDropDownMenu_CreateInfo",
  "UIDropDownMenu_AddButton", "UIDropDownMenu_SetText", "GetItemQualityColor", "GetContainerNumSlots" }
for _, n in ipairs(legacy) do _G[n] = nil end
C_Spell = { GetSpellInfo = function() return { name = "Escudo de relámpagos", iconID = 1 } end }
C_Item = { GetItemInfo = function(x) return "Objeto", "|cff|Hitem:" .. tostring(x) .. "|h[x]|h|r", 1, 10, 1, "", "", 20, "INVTYPE_HEAD", "", 25, 4, 2 end,
  GetItemIconByID = function() return 1 end, GetItemCount = function(id) return id == 4233 and 12 or 4 end, GetItemStats = function() return {} end,
  GetItemQualityColor = function() return 0.1, 1, 0 end }
C_UnitAuras = { GetAuraDataByIndex = function() return nil end }
local PR = { { "Peletería", 118, 150 }, { "Desuello", 150, 150 }, nil, { "Pesca", 147, 150 }, { "Cocina", 132, 150 } }
GetProfessions = function() return 1, 2, nil, 4, 5 end
GetProfessionInfo = function(i) local p = PR[i]; return p[1], 1, p[2], p[3] end
local QL = { { title = "Minas", isHeader = true }, { title = "La Hermandad Defias", level = 22, questID = 166 }, { title = "Ratas", level = 9, questID = 999 } }
C_QuestLog.GetNumQuestLogEntries = function() return #QL end
C_QuestLog.GetInfo = function(i) return QL[i] end
C_QuestLog.IsComplete = function(id) return id == 166 end
UnitQuestTrivialLevelRange = function() return 8 end
Enum = { TooltipDataType = { Item = 0 }, UIMapType = { Zone = 3 } }
__tdp = {}
TooltipDataProcessor = { AddTooltipPostCall = function(t, f) table.insert(__tdp, f) end }
local reg = {}
Settings = { RegisterCanvasLayoutCategory = function(p, n) return { ID = n, GetID = function() return n end } end,
  RegisterAddOnCategory = function() end, RegisterCanvasLayoutSubcategory = function() end, OpenToCategory = function() end }
-- eventos que no existen en el motor moderno
local bad = { CHARACTER_POINTS_CHANGED = true, AUCTION_ITEM_LIST_UPDATE = true, NEW_AUCTION_UPDATE = true }
local mt = getmetatable(UIParent)
local idx = mt.__index
local oldReg = idx(UIParent, "RegisterEvent")
local methods = {}
mt.__index = function(t, k)
  if k == "RegisterEvent" then return function(self, e) if bad[e] then error("Attempt to register unknown event \"" .. e .. "\"") end self.__events[e] = true end end
  if k == "HookScript" then return function(self, s, f) if s == "OnTooltipSetItem" then error("does not have a \"OnTooltipSetItem\" script") end self.__scripts[s] = f end end
  return idx(t, k)
end
local oldCF = CreateFrame
CreateFrame = function(kind, name, parent, tpl)
  if tpl == "OptionsSliderTemplate" or tpl == "UIDropDownMenuTemplate" then error("Couldn't find inherited node \"" .. tpl .. "\"") end
  return oldCF(kind, name, parent, tpl)
end
C_Map.GetMapInfo = function(id) if id == 49 then return { name = "Montañas Crestagrana", mapType = 3 } end if id == 1433 then return nil end return nil end
WOW_PROJECT_CAMELOT = 99; WOW_PROJECT_ID = 99
local SK2 = { { name = "Profesiones", isHeader = true, isCollapsed = true }, { name = "Peletería", rank = 118, maxRank = 150 }, { name = "Desuello", rank = 150, maxRank = 150 }, { name = "Pesca", rank = 147, maxRank = 150 } }
C_SkillInfo = { GetNumSkillLines = function() return #SK2 end, GetSkillLineInfo = function(i) return SK2[i] end, ExpandSkillHeader = function(i) SK2[i].isCollapsed = false end }
C_Secrets = { ShouldAurasBeSecret = function() return __inCombat == true end }
C_QuestLog.GetTrivialRange = function() return 9 end
-- talentos del motor moderno: sin GetNumTalentTabs, con C_ClassTalents / C_Traits
GetNumTalentTabs = nil; GetNumTalents = nil; GetTalentInfo = nil
local TN = { [101] = { def = 1, rank = 5 }, [102] = { def = 2, rank = 0 } }
C_ClassTalents = { GetActiveConfigID = function() return 7 end }
C_Traits = {
  GetConfigInfo = function(id) return { treeIDs = { 70, 71 } } end,
  -- los dos árboles informan la misma moneda: se tiene que contar una sola vez
  GetTreeCurrencyInfo = function() return { { traitCurrencyID = 9, quantity = 6, spent = 5 } } end,
  GetTreeNodes = function(tree) return tree == 70 and { 101, 102 } or {} end,
  GetNodeInfo = function(cfg, node) local n = TN[node]; return { activeRank = n.rank, entryIDs = { node * 10 } } end,
  GetEntryInfo = function(cfg, entry) return { definitionID = entry / 10 } end,
  GetDefinitionInfo = function(def) return { spellID = def } end,
}
C_Spell.GetSpellName = function(id) return ({ [101] = "Golpes de trueno", [102] = "Anticipación" })[id] end
UnitExists = function() return true end; UnitCanAttack = function() return true end; UnitIsDead = function() return false end
local results = {}
C_AuctionHouse = { MakeItemKey = function(id) return { itemID = id } end, IsThrottledMessageSystemReady = function() return true end,
  SendSearchQuery = function(key) table.insert(results, key.itemID) end,
  GetNumCommoditySearchResults = function() return 1 end, GetCommoditySearchResultInfo = function(id) return { unitPrice = 123, quantity = 50 } end,
  GetCommoditySearchResultsQuantity = function() return 500 end, GetNumItemSearchResults = function() return 0 end }
__ahq = results
AuctionHouseFrame = CreateFrame("Frame")
AuctionHouseFrame.SearchBar = { SearchBox = { SetText = function() end }, StartSearch = function() end }
local cf = CreateFrame("Frame"); cf.SetItem = function() end; cf.GetItem = function() return { loc = 1 } end; cf.PriceInput = CreateFrame("Frame")
cf.PriceInput.SetAmount = function(self, v) __priceSet = v end
AuctionHouseFrame.CommoditiesSellFrame = cf
C_Item.GetItemID = function() return 4235 end
__hooks = {}
hooksecurefunc = function(t, k, f) if type(t) == "table" and type(k) == "string" then table.insert(__hooks, f) end end
__tickers = {}
C_Timer.NewTicker = function(t, f) local tk = { f = f, Cancel = function(self) self.dead = true end }; table.insert(__tickers, tk); return tk end
Enum.TooltipDataType.Unit = 2
UnitIsPlayer = function() return false end
UnitCreatureType = function() return "Bestia" end
local origUL = UnitLevel
UnitLevel = function(u) if u == "player" or u == nil then return 20 end return 16 end
function GameTooltip.GetUnit() return "Lobo", "mouseover" end
CreateVector2D = function(x, y) return { GetXY = function() return x, y end } end
C_Map.GetWorldPosFromMapPos = function(map, v) local x, y = v:GetXY(); return 0, CreateVector2D(map * 10 + x * 1000, y * 1000) end
C_Map.GetMapInfo = function(id) local n = ({ [49] = "Montañas Crestagrana", [87] = "Forjaz", [27] = "Dun Morogh" })[id]; if n then return { name = n, mapType = 3 } end end
C_Map.GetBestMapForUnit = function() return 87 end
local TR = { { name = "Buscar hierbas", active = false }, { name = "Instructor de clase", active = false }, { name = "Instructor de profesiones", active = false } }
C_Minimap = { GetNumTrackingTypes = function() return #TR end, GetTrackingInfo = function(i) return TR[i] end, SetTracking = function(i, on) TR[i].active = on end }
__TR = TR
