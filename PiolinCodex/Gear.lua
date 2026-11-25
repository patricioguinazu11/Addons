-- Códice de Piolin: comparador de equipo, durabilidad, objetivos y ayudante de subasta
local ADDON, NS = ...
local C = NS.colors

local function DB() return PiolinCodexDB end
local function Print(m) NS.Print(m) end
local function Money(c) return NS.Money(math.floor(c + 0.5)) end
local function IdFromLink(link) return link and tonumber(link:match("item:(%d+)")) end

----------------------------------------------------------------------
-- Objetivos de equipo (los que te fui recomendando)
-- names: nombres posibles (español o inglés); id: si se conoce
----------------------------------------------------------------------
NS.GEAR_GOALS = {
  { lvl = 22, names = { "Camorrista", "Brawler" }, t = "Piezas de Camorrista (Daniel Hilvanante, Tres Esquinas)" },
  { lvl = 26, names = { "Heavehammer" }, t = "Heavehammer (excavación, Los Humedales)" },
  { lvl = 28, names = { "Dalaran" }, t = "Defensor de Dalaran (Ciudad de Dalaran)" },
  { lvl = 29, names = { "Corpsemaker", "Hacedor de cadáveres" }, t = "Corpsemaker (Horado Rajacieno)" },
  { lvl = 30, id = 9449, names = { "Crowd Pummeler", "Aporreamultitudes" }, t = "Manual Crowd Pummeler (Gnomeregan)" },
  { lvl = 42, names = { "Bigger Rock", "Bigger Stick" }, t = "Bigger Rock on Bigger Stick (Fortaleza Krol'dok)" },
  { lvl = 50, names = { "Beastslayer", "Matabestias" }, t = "Beastslayer (Un'Goro)" },
  { lvl = 60, names = { "Clarividente", "Clairvoyant" }, t = "Ira del Clarividente" },
}

----------------------------------------------------------------------
-- Peso de cada estadística para un chamán Mejora que sube de nivel
----------------------------------------------------------------------
local WEIGHTS = {
  ITEM_MOD_STRENGTH_SHORT = 1.0,
  ITEM_MOD_AGILITY_SHORT = 0.75,
  ITEM_MOD_ATTACK_POWER_SHORT = 0.5,
  ITEM_MOD_STAMINA_SHORT = 0.35,
  ITEM_MOD_INTELLECT_SHORT = 0.15,
  ITEM_MOD_SPIRIT_SHORT = 0.05,
  RESISTANCE0_NAME = 0.02,
  ITEM_MOD_CRIT_RATING_SHORT = 10,
  ITEM_MOD_HIT_RATING_SHORT = 8,
}
local SHORT = {
  ITEM_MOD_STRENGTH_SHORT = "Fue", ITEM_MOD_AGILITY_SHORT = "Agi", ITEM_MOD_STAMINA_SHORT = "Agu",
  ITEM_MOD_INTELLECT_SHORT = "Int", ITEM_MOD_SPIRIT_SHORT = "Esp", ITEM_MOD_ATTACK_POWER_SHORT = "PA",
  ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "DPS", RESISTANCE0_NAME = "Arm",
}
local ORDER = { "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_AGILITY_SHORT",
  "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_SPIRIT_SHORT", "RESISTANCE0_NAME" }

local SLOTS = {
  INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 },
  INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 },
  INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
  INVTYPE_WEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_2HWEAPON = { 16 },
  INVTYPE_SHIELD = { 17 }, INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_HOLDABLE = { 17 }, INVTYPE_RELIC = { 18 },
}
-- Armas que puede usar un chamán (clase 2): hachas 1M/2M, mazas 1M/2M, bastón, puño, daga
local SHAMAN_WEAPONS = { [0] = true, [1] = true, [4] = true, [5] = true, [10] = true, [13] = true, [15] = true }

local scanTip = CreateFrame("GameTooltip", "PiolinCodexScanTip", UIParent, "GameTooltipTemplate")
local speedCache = {}
local function WeaponSpeed(link)
  if speedCache[link] ~= nil then return speedCache[link] or nil end
  scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
  scanTip:SetHyperlink(link)
  local speed
  for i = 1, scanTip:NumLines() do
    local r = _G["PiolinCodexScanTipTextRight" .. i]
    local txt = r and r:GetText()
    if txt then
      local n = txt:match("(%d+[%.,]%d+)")
      if n and (txt:find("elocidad") or txt:find("Speed")) then speed = tonumber((n:gsub(",", "."))) break end
    end
  end
  scanTip:Hide()
  speedCache[link] = speed or false
  return speed
end

local function GetStats(link)
  local f = (C_Item and C_Item.GetItemStats) or GetItemStats
  local ok, t = pcall(f, link)
  return ok and t or {}
end

local scoreCache = {}
local function Score(link)
  if not link then return 0, {} end
  if scoreCache[link] then return scoreCache[link][1], scoreCache[link][2] end
  local st = GetStats(link)
  local s = 0
  for k, w in pairs(WEIGHTS) do s = s + (st[k] or 0) * w end
  local dps = st.ITEM_MOD_DAMAGE_PER_SECOND_SHORT
  if dps and dps > 0 then
    s = s + dps * 6
    local equipLoc = select(9, GetItemInfo(link))
    if equipLoc ~= "INVTYPE_WEAPONOFFHAND" then
      local sp = WeaponSpeed(link)
      if sp and sp > 2.6 then s = s + (sp - 2.6) * 6 end -- Golpe de tormenta y Viento furioso rinden más con armas lentas
    end
  end
  scoreCache[link] = { s, st }
  return s, st
end

local function CanUse(link)
  local _, _, _, _, _, _, _, _, equipLoc, _, _, classID, subID = GetItemInfo(link)
  if classID == 4 then
    if subID == 4 then return false, "placas: un chamán no las puede usar" end
    if subID == 3 and (UnitLevel("player") or 0) < 40 then return false, "malla: la podés usar desde el nivel 40" end
    if subID == 5 or subID == 7 or subID == 8 or subID == 9 or subID == 10 then return false, "esta reliquia no es de chamán" end
  elseif classID == 2 then
    if not SHAMAN_WEAPONS[subID] then return false, "un chamán no puede usar este tipo de arma" end
  end
  return true
end

local function Compare(tt)
  if not PiolinCodexDB or DB().noGear then return end
  local link = NS.TipLink(tt)
  if not link then return end
  local equipLoc = select(9, GetItemInfo(link))
  local slots = equipLoc and SLOTS[equipLoc]
  if not slots then return end
  local ok, why = CanUse(link)
  if not ok then
    tt:AddLine("|cffd9a93fCódice|r · |cffff6060No te sirve:|r " .. why)
    tt:Show()
    return
  end
  local new, newStats = Score(link)
  -- lo equipado en esa ranura (en anillos y abalorios, el peor de los dos)
  local old, oldStats, oldLink = nil, {}, nil
  for _, slot in ipairs(slots) do
    local l = GetInventoryItemLink("player", slot)
    if l == link then
      tt:AddLine("|cffd9a93fCódice|r · Lo tenés equipado", 0.7, 0.7, 0.7)
      tt:Show()
      return
    end
    local s, st = Score(l)
    if not l then s, st = 0, {} end
    if old == nil or s < old then old, oldStats, oldLink = s, st, l end
  end
  -- arma de dos manos contra arma + escudo
  if equipLoc == "INVTYPE_2HWEAPON" then
    local oh = GetInventoryItemLink("player", 17)
    if oh then
      local s2, st2 = Score(oh)
      old = old + s2
      local merged = {}
      for k, v in pairs(oldStats) do merged[k] = v end
      for k, v in pairs(st2) do merged[k] = (merged[k] or 0) + v end
      oldStats = merged
    end
  end
  local diff = new - (old or 0)
  local line
  if not oldLink and (old or 0) == 0 then
    line = "|cff7fd16aMejora: ranura vacía, equipalo|r"
  elseif math.abs(diff) < 0.5 then
    line = "|cffffd96aMás o menos igual a lo que tenés|r"
  elseif diff > 0 then
    local pct = old > 0 and (" (+" .. math.floor(diff / old * 100 + 0.5) .. "%)") or ""
    line = "|cff7fd16aMejora para Mejora: +" .. string.format("%.1f", diff) .. pct .. "|r"
  else
    line = "|cffff6060Peor que lo tuyo: " .. string.format("%.1f", diff) .. "|r"
  end
  tt:AddLine(" ")
  tt:AddLine("|cffd9a93fCódice|r · " .. line)
  local parts = {}
  for _, k in ipairs(ORDER) do
    local d = (newStats[k] or 0) - (oldStats[k] or 0)
    if math.abs(d) >= 0.1 then
      local txt = (k == "ITEM_MOD_DAMAGE_PER_SECOND_SHORT") and string.format("%+.1f", d) or string.format("%+d", d)
      local col = d > 0 and "|cff7fd16a" or "|cffff6060"
      table.insert(parts, SHORT[k] .. " " .. col .. txt .. "|r")
    end
  end
  if #parts > 0 then tt:AddLine(table.concat(parts, "  "), 1, 1, 1) end
  if equipLoc == "INVTYPE_2HWEAPON" and GetInventoryItemLink("player", 17) then
    tt:AddLine("(comparado contra tu arma + escudo)", 0.55, 0.5, 0.42)
  end
  tt:Show()
end

NS.HookItemTooltip(Compare)

----------------------------------------------------------------------
-- Durabilidad y reparación
----------------------------------------------------------------------
local function Durability()
  local low = 1
  for slot = 1, 18 do
    local cur, max = GetInventoryItemDurability(slot)
    if cur and max and max > 0 then low = math.min(low, cur / max) end
  end
  return math.floor(low * 100 + 0.5)
end

local function CheckDurability()
  local pct = Durability()
  if pct <= 0 then
    NS.Alert("dur0", "¡Tenés equipo roto! Andá a reparar", "Interface\\Icons\\Trade_BlackSmithing", 1, 0.35, 0.3, 120)
  elseif pct <= 25 and not DB().durWarned then
    DB().durWarned = true
    NS.Alert("dur", "Durabilidad al " .. pct .. "%: repará antes de la próxima mazmorra", "Interface\\Icons\\Trade_BlackSmithing", 1, 0.6, 0.25, 60)
  elseif pct > 50 then
    DB().durWarned = nil
  end
end

local function AutoRepair()
  if DB().noRepair or not (CanMerchantRepair and CanMerchantRepair()) then return end
  local cost, can = GetRepairAllCost()
  if not can or not cost or cost <= 0 then return end
  if GetMoney() < cost then
    Print("reparar todo cuesta " .. Money(cost) .. " y no te alcanza.")
    return
  end
  RepairAllItems()
  Print("reparaste todo por " .. Money(cost) .. ".")
end

----------------------------------------------------------------------
-- Texto extra para la pestaña Personaje
----------------------------------------------------------------------
local function OwnedNames()
  local owned, ids = {}, {}
  local function add(link)
    if not link then return end
    local id = IdFromLink(link)
    if id then ids[id] = true end
    local name = GetItemInfo(link)
    if name then owned[#owned + 1] = name:lower() end
  end
  for slot = 1, 19 do add(GetInventoryItemLink("player", slot)) end
  local CC = C_Container
  for bag = 0, 4 do
    local n = (CC and CC.GetContainerNumSlots or GetContainerNumSlots)(bag) or 0
    for s = 1, n do add((CC and CC.GetContainerItemLink or GetContainerItemLink)(bag, s)) end
  end
  return owned, ids
end

local function HasGoal(g, owned, ids)
  if g.id and (ids[g.id] or (GetItemCount(g.id, true) or 0) > 0) then return true end
  for _, pat in ipairs(g.names or {}) do
    local p = pat:lower()
    for _, n in ipairs(owned) do if n:find(p, 1, true) then return true end end
  end
  return false
end

NS.Durability = Durability
function NS.GoalStatus()
  local owned, ids = OwnedNames()
  local level = UnitLevel("player") or 0
  local out = {}
  for _, g in ipairs(NS.GEAR_GOALS) do
    if g.lvl >= level - 4 then table.insert(out, { lvl = g.lvl, t = g.t, have = HasGoal(g, owned, ids) }) end
  end
  for id in pairs(DB().goals or {}) do
    table.insert(out, 1, { lvl = 0, t = (GetItemInfo(id) or ("objeto " .. id)), have = HasGoal({ id = id }, owned, ids), id = id })
  end
  return out
end

function NS.CharExtra()
  local lines = {}
  local pct = Durability()
  local col = pct <= 25 and "|cffff6060" or (pct <= 50 and "|cffff9a40" or "|cff7fd16a")
  table.insert(lines, "Durabilidad: " .. col .. pct .. "%|r" .. (DB().noRepair and "" or "  |cff8c806b(se repara sola en el vendedor)|r"))
  local owned, ids = OwnedNames()
  local level = UnitLevel("player") or 0
  local goals = {}
  for _, g in ipairs(NS.GEAR_GOALS) do table.insert(goals, g) end
  for id in pairs(DB().goals or {}) do
    local name = GetItemInfo(id) or ("objeto " .. id)
    table.insert(goals, { lvl = 0, id = id, t = name .. " (agregado por vos)" })
  end
  local shown = {}
  for _, g in ipairs(goals) do
    if #shown >= 4 then break end
    if g.lvl == 0 or g.lvl >= level - 4 then
      local have = HasGoal(g, owned, ids)
      local mark = have and "|cff7fd16a✔|r " or "|cffd9a93f·|r "
      local lv = g.lvl > 0 and ("|cff69ccf0" .. g.lvl .. "|r ") or ""
      table.insert(shown, "  " .. mark .. lv .. (have and ("|cff8c806b" .. g.t .. "|r") or g.t))
    end
  end
  if #shown > 0 then
    table.insert(lines, C.G .. "Objetivos de equipo:" .. C.E)
    for _, l in ipairs(shown) do table.insert(lines, l) end
  end
  return table.concat(lines, "\n")
end

----------------------------------------------------------------------
-- Ayudante para vender en la subasta
----------------------------------------------------------------------
local sellLabel, sellBtn, pendingLookup

local function SellInfo()
  local name, _, count, _, _, _, _, _, _, itemID = GetAuctionSellItemInfo()
  if not name then return nil end
  if not itemID then
    local _, link = GetItemInfo(name)
    itemID = IdFromLink(link)
  end
  return name, count or 1, itemID
end

local function ApplySellPrice()
  if not sellLabel then return end
  local name, count, id = SellInfo()
  if not name or DB().noSellHelper then sellLabel:SetText(""); sellBtn:Hide(); return end
  local unit, rec = NS.Price(id)
  sellBtn:Show()
  if not unit then
    sellLabel:SetText("|cffd9a93fCódice:|r sin precio guardado para esto.\nTocá \"Buscar precio\".")
    sellBtn:SetText("Buscar precio")
    return
  end
  sellBtn:SetText("Precio Códice")
  local buy = unit >= 100 and math.floor(unit * 0.98) or math.max(1, unit - 1)
  local stack = (AuctionsStackSizeEntry and AuctionsStackSizeEntry:GetNumber()) or 0
  if stack == 0 then stack = count end
  local perUnit = AuctionFrameAuctions and AuctionFrameAuctions.priceType == 1
  local mult = perUnit and 1 or stack
  MoneyInputFrame_SetCopper(StartPrice, math.floor(buy * 0.9) * mult)
  MoneyInputFrame_SetCopper(BuyoutPrice, buy * mult)
  local src = rec.seed and ("wowauctions " .. NS.SEED_DATE) or ("escaneo de hace " .. (function(t)
    local d = time() - t
    if d < 3600 then return math.max(1, math.floor(d / 60)) .. " min" end
    if d < 86400 then return math.floor(d / 3600) .. " h" end
    return math.floor(d / 86400) .. " d"
  end)(rec.t))
  local txt = "|cffd9a93fCódice:|r " .. Money(buy) .. " c/u, un poco menos que el más barato (" .. Money(unit) .. ", " .. src .. ")"
  local vendor = select(11, GetItemInfo(id)) or 0
  if vendor > 0 and buy * 0.95 < vendor * 1.25 then
    txt = txt .. "\n|cffffd96aOjo: al vendedor te pagan " .. Money(vendor) .. " c/u sin riesgo.|r"
  end
  sellLabel:SetText(txt)
end

local function LookupPrice()
  local name, _, id = SellInfo()
  if not name then return end
  if NS.Price(id) and sellBtn:GetText() == "Precio Códice" then ApplySellPrice(); return end
  if not CanSendAuctionQuery() then Print("la casa de subastas está ocupada, probá en un segundo."); return end
  NS.scanStamp = time()
  pendingLookup = id
  QueryAuctionItems(name, nil, nil, 0, false, nil, false, true)
end

NS.OnPricesRead = function()
  if pendingLookup then
    pendingLookup = nil
    C_Timer.After(0.1, ApplySellPrice)
  end
end

local function BuildSellHelper()
  if sellLabel or not AuctionFrameAuctions or not BuyoutPrice then return end
  sellLabel = AuctionFrameAuctions:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sellLabel:SetPoint("TOPLEFT", BuyoutPrice, "BOTTOMLEFT", -4, -10)
  sellLabel:SetWidth(200)
  sellLabel:SetJustifyH("LEFT")
  sellBtn = CreateFrame("Button", nil, AuctionFrameAuctions, "UIPanelButtonTemplate")
  sellBtn:SetSize(110, 20)
  sellBtn:SetPoint("TOPLEFT", sellLabel, "BOTTOMLEFT", 0, -4)
  sellBtn:SetScript("OnClick", LookupPrice)
  sellBtn:Hide()
  if AuctionsStackSizeEntry then
    AuctionsStackSizeEntry:HookScript("OnTextChanged", function(_, user) if user then C_Timer.After(0.05, ApplySellPrice) end end)
  end
end

----------------------------------------------------------------------
-- Eventos
----------------------------------------------------------------------
local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "UPDATE_INVENTORY_DURABILITY", "MERCHANT_SHOW", "AUCTION_HOUSE_SHOW",
  "NEW_AUCTION_UPDATE", "PLAYER_EQUIPMENT_CHANGED", "GET_ITEM_INFO_RECEIVED" }) do
  pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    C_Timer.After(6, CheckDurability)
  elseif event == "UPDATE_INVENTORY_DURABILITY" then
    CheckDurability()
  elseif event == "MERCHANT_SHOW" then
    C_Timer.After(0.1, AutoRepair)
  elseif event == "AUCTION_HOUSE_SHOW" then
    BuildSellHelper()
  elseif event == "NEW_AUCTION_UPDATE" then
    C_Timer.After(0.15, ApplySellPrice) -- después de que el juego ponga su propio precio
  elseif event == "PLAYER_EQUIPMENT_CHANGED" then
    wipe(scoreCache)
  elseif event == "GET_ITEM_INFO_RECEIVED" then
    -- nada: los tooltips se recalculan solos la próxima vez
  end
end)

----------------------------------------------------------------------
-- Comandos
----------------------------------------------------------------------
local prevSlash = NS.TradeSlash
NS.TradeSlash = function(msg)
  if msg == "ayuda" then
    Print("comandos: /piolin (abrir), opciones, instructor [oficio], rastreo, misiones, ir X Y, macros, tienda, probar, avisos, equipo, reparar, ayudante, vender, compras, precios, minimapa, reset, basura [objeto], objetivo [objeto].")
    return true
  elseif msg == "equipo" then
    DB().noGear = not DB().noGear
    Print(DB().noGear and "comparador de equipo apagado." or "comparador de equipo prendido.")
    return true
  elseif msg == "reparar" then
    DB().noRepair = not DB().noRepair
    Print(DB().noRepair and "reparación automática apagada." or "reparación automática prendida.")
    return true
  elseif msg == "ayudante" then
    DB().noSellHelper = not DB().noSellHelper
    Print(DB().noSellHelper and "ayudante de subasta apagado." or "ayudante de subasta prendido.")
    return true
  elseif msg:find("^objetivo") then
    local id = IdFromLink(msg)
    if not id then Print("usá /piolin objetivo y hacé shift-clic en el objeto para enlazarlo."); return true end
    DB().goals = DB().goals or {}
    DB().goals[id] = not DB().goals[id] or nil
    local name = GetItemInfo(id) or ("objeto " .. id)
    Print(DB().goals[id] and (name .. " agregado a tus objetivos de equipo.") or (name .. " quitado de tus objetivos."))
    if NS.RefreshLive then NS.RefreshLive() end
    return true
  end
  return prevSlash and prevSlash(msg) or false
end
