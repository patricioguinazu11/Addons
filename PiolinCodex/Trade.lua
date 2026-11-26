-- Códice de Piolin: precios de subasta, limpieza de bolsas y ayudas de oficios
local ADDON, NS = ...
local C = NS.colors

local function DB() return PiolinCodexDB end
local function Print(m) NS.Print(m) end
local function Money(c) return NS.Money(math.floor(c + 0.5)) end

local function IdFromLink(link)
  if not link then return nil end
  return tonumber(link:match("item:(%d+)"))
end

local function Ago(t)
  local d = time() - t
  if d < 3600 then return math.max(1, math.floor(d / 60)) .. " min" end
  if d < 86400 then return math.floor(d / 3600) .. " h" end
  return math.floor(d / 86400) .. " d"
end

----------------------------------------------------------------------
-- Bolsas (API nueva y vieja)
----------------------------------------------------------------------
local CC = C_Container
local function NumSlots(bag)
  if CC and CC.GetContainerNumSlots then return CC.GetContainerNumSlots(bag) end
  return GetContainerNumSlots(bag)
end
local function SlotInfo(bag, slot)
  if CC and CC.GetContainerItemInfo then
    local i = CC.GetContainerItemInfo(bag, slot)
    if not i then return nil end
    return i.hyperlink, i.stackCount, i.quality, i.hasNoValue, i.itemID
  end
  local _, count, _, quality, _, _, link, _, noValue, id = GetContainerItemInfo(bag, slot)
  return link, count, quality, noValue, id
end
local function UseSlot(bag, slot)
  if CC and CC.UseContainerItem then CC.UseContainerItem(bag, slot) else UseContainerItem(bag, slot) end
end

----------------------------------------------------------------------
-- Precios
----------------------------------------------------------------------
local function Price(id)
  local p = DB().prices and DB().prices[id]
  if p then return p.p, p end
  local seed = NS.SEED_PRICES and NS.SEED_PRICES[id]
  if seed then return seed[2], { p = seed[2], n = seed[3], t = NS.SEED_TIME, seed = true } end
  return nil
end
NS.Price = Price

local function Record(id, unit, listed)
  if not id or not unit or unit <= 0 then return end
  DB().prices = DB().prices or {}
  local cur = DB().prices[id]
  -- dentro de un mismo escaneo (o de la misma búsqueda) se queda con el más barato
  if cur and cur.scan == NS.scanStamp and cur.p <= unit then
    cur.n = (cur.n or 0) + (listed or 0)
    return
  end
  if cur and cur.scan == NS.scanStamp then
    cur.p = unit; cur.n = (cur.n or 0) + (listed or 0); cur.t = time()
    return
  end
  DB().prices[id] = { p = unit, n = listed or 0, t = time(), scan = NS.scanStamp }
end

-- Lee la página de resultados que está mostrando la casa de subastas
local function ReadAuctionPage()
  local n = GetNumAuctionItems("list")
  local best = {}
  for i = 1, n do
    local _, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemId = GetAuctionItemInfo("list", i)
    if buyout and buyout > 0 and count and count > 0 and itemId then
      local unit = buyout / count
      local b = best[itemId]
      if not b then best[itemId] = { unit, 1 } else
        b[2] = b[2] + 1
        if unit < b[1] then b[1] = unit end
      end
    end
  end
  for id, b in pairs(best) do Record(id, b[1], b[2]) end
  return n
end

-- Recomendación subasta vs. vendedor
local function Verdict(id, vendor)
  local ah = Price(id)
  if not ah then return nil end
  local net = ah * 0.95 -- la subasta se queda con el 5%
  if vendor and vendor > 0 and net < vendor * 1.25 then
    return "|cffffd96aConviene: vendedor|r"
  end
  return "|cff7fd16aConviene: subasta|r"
end
NS.Verdict = Verdict

local function AddTooltip(tt)
  if not PiolinCodexDB or DB().noPrices then return end
  local link = NS.TipLink(tt)
  local id = IdFromLink(link)
  if not id then return end
  local vendor = select(11, GetItemInfo(link))
  local ah, rec = Price(id)
  if not ah and not (vendor and vendor > 0) then return end
  tt:AddLine(" ")
  if ah then
    tt:AddDoubleLine("|cffd9a93fCódice|r · Subasta (c/u)", Money(ah) .. "  |cff8c806b" .. (rec.seed and ("wowauctions " .. NS.SEED_DATE) or Ago(rec.t)) .. "|r", 1, 1, 1, 1, 1, 1)
  else
    tt:AddLine("|cffd9a93fCódice|r · Subasta: sin datos (escaneá en la casa de subastas)", 0.7, 0.7, 0.7)
  end
  if vendor and vendor > 0 then tt:AddDoubleLine("Vendedor (c/u)", Money(vendor), 1, 1, 1, 1, 1, 1) end
  local v = Verdict(id, vendor)
  if v then tt:AddLine(v) end
  tt:Show()
end

NS.HookItemTooltip(AddTooltip)

----------------------------------------------------------------------
-- Para qué sirve el material: en qué tramo de Peletería lo usás
----------------------------------------------------------------------
-- Materiales que no van directo a un tramo pero se convierten en uno que sí
local DERIVED = {
  [783] = { 4231, "Curado con sal da Piel ligera curada" },
  [2934] = { 2318, "3 restos hacen 1 Cuero ligero" },
}

local function UsesOf(id)
  local out = {}
  for _, t in ipairs(NS.LW_TIERS or {}) do
    for _, m in ipairs(t.mats) do
      if m[1] == id then table.insert(out, { t = t, n = m[2], name = m[3] }) end
    end
  end
  return out
end
NS.MatUses = UsesOf

local function AddMatUse(tt)
  if not PiolinCodexDB or DB().noMatUse then return end
  local id = IdFromLink(NS.TipLink(tt))
  if not id then return end
  local uses, via = UsesOf(id), nil
  if #uses == 0 and DERIVED[id] then via = DERIVED[id]; uses = UsesOf(via[1]) end
  if #uses == 0 then return end
  local rank = NS.Skill("Peletería")
  tt:AddLine(" ")
  tt:AddLine("|cffd9a93fCódice|r · Para Peletería" .. (rank and ("  |cff8c806b(vas por " .. rank .. ")|r") or ""), 1, 1, 1)
  if via then tt:AddLine(via[2], 0.6, 0.75, 0.9) end
  local shown = 0
  for _, u in ipairs(uses) do
    local t = u.t
    if not (rank and rank >= t.max) and shown < 3 then
      shown = shown + 1
      local now = rank and rank >= t.min
      local amount = via and (u.n .. " " .. u.name) or tostring(u.n)
      local line = (now and "|cff7fd16aAhora|r · " or "") .. t.min .. "-" .. t.max .. "  " .. t.recipe .. ": " .. amount
      if now and not via then
        local have = GetItemCount(id, true) or 0
        line = line .. (have >= u.n and "  |cff7fd16a(tenés " .. have .. ")|r" or "  |cffffd96a(tenés " .. have .. ")|r")
      end
      tt:AddLine(line, 0.86, 0.89, 0.93)
    end
  end
  if shown == 0 then tt:AddLine("Ya pasaste los tramos que lo usan: lo podés vender.", 0.55, 0.5, 0.42) end
  tt:Show()
end

NS.HookItemTooltip(AddMatUse)

----------------------------------------------------------------------
-- Escaneo de materiales
----------------------------------------------------------------------
local scan = { queue = nil, idx = 0, waiting = false, page = 0, item = nil }
local scanBtn, scanTicker

local function ScanDone()
  if scanTicker then scanTicker:Cancel(); scanTicker = nil end
  local count = 0
  for _, it in ipairs(NS.SCAN_ITEMS) do if Price(it[1]) and DB().prices[it[1]].scan == NS.scanStamp then count = count + 1 end end
  Print("escaneo terminado: precio de " .. count .. " de " .. #NS.SCAN_ITEMS .. " materiales.")
  scan.queue = nil
  if scanBtn then scanBtn:SetText("Escanear materiales"); scanBtn:Enable() end
  if NS.RefreshShopping then NS.RefreshShopping() end
end

local function ScanStep()
  if not scan.queue or scan.waiting then return end
  if not CanSendAuctionQuery() then return end
  scan.item = scan.queue[scan.idx]
  if not scan.item then ScanDone(); return end
  local name = GetItemInfo(scan.item[1]) or scan.item[2]
  scan.waiting = true
  scan.sent = GetTime()
  QueryAuctionItems(name, nil, nil, scan.page, false, nil, false, true)
  if scanBtn then scanBtn:SetText("Escaneando " .. scan.idx .. "/" .. #scan.queue) end
end

local function StartScan()
  if scan.queue then return end
  NS.scanStamp = time()
  scan.queue, scan.idx, scan.page, scan.waiting = NS.SCAN_ITEMS, 1, 0, false
  if scanBtn then scanBtn:Disable() end
  scanTicker = C_Timer.NewTicker(0.3, function()
    -- si el servidor no responde en 6 s, sigue con el siguiente
    if scan.waiting and GetTime() - (scan.sent or 0) > 6 then scan.waiting = false; scan.idx = scan.idx + 1; scan.page = 0 end
    ScanStep()
  end)
end

local function OnAuctionList()
  local n = ReadAuctionPage()
  if NS.OnPricesRead then NS.OnPricesRead() end
  if scan.queue and scan.waiting then
    local _, total = GetNumAuctionItems("list")
    scan.waiting = false
    if total and (scan.page + 1) * 50 < total and scan.page < 2 then
      scan.page = scan.page + 1
    else
      scan.page = 0
      scan.idx = scan.idx + 1
    end
  end
end

----------------------------------------------------------------------
-- Lista de compras (vendedor y subasta)
----------------------------------------------------------------------
local shop

local function CurrentTier()
  local rank = NS.Skill("Peletería")
  if not rank then return nil end
  for _, t in ipairs(NS.LW_TIERS) do
    if rank >= t.min and rank < t.max then return t, rank end
  end
end

local function Missing(onlyVendor)
  local tier = CurrentTier()
  if not tier then return nil end
  local list = {}
  for _, m in ipairs(tier.mats) do
    local have = GetItemCount(m[1], true) or 0
    if have < m[2] then
      local isVendor = NS.VENDOR_MATS[m[1]]
      if onlyVendor == nil or onlyVendor == (isVendor and true or false) then
        table.insert(list, { id = m[1], name = m[3], need = m[2] - have, vendor = isVendor })
      end
    end
  end
  return list, tier
end

NS.CurrentTier = CurrentTier
NS.RecordPrice = function(id, unit, listed) Record(id, unit, listed) end
NS.Missing = Missing

local function BuildShop()
  local S = NS.Style
  shop = CreateFrame("Frame", "PiolinCodexShop", UIParent, "BasicFrameTemplateWithInset")
  if S then S.SkinWindow(shop) end
  shop:SetSize(260, 120)
  shop:SetFrameStrata("HIGH")
  shop.title = S.Font(shop:CreateFontString(nil, "OVERLAY"), 12.5, S.K.title, true)
  shop.title:SetPoint("TOPLEFT", 12, -8)
  shop.title:SetText("Lista de compras")
  shop.sub = S.Font(shop:CreateFontString(nil, "OVERLAY"), 11, S.K.mute)
  shop.sub:SetPoint("TOPLEFT", 12, -34)
  shop.sub:SetWidth(236)
  shop.sub:SetJustifyH("LEFT")
  shop.lines = {}
  shop.total = S.Font(shop:CreateFontString(nil, "OVERLAY"), 11, S.K.parch)
  shop.total:SetJustifyH("LEFT")
  shop:Hide()
end

local function ShopLine(i)
  local b = shop.lines[i]
  if b then return b end
  b = CreateFrame("Button", nil, shop)
  b:SetSize(236, 18)
  b.text = NS.Style.Font(b:CreateFontString(nil, "OVERLAY"), 11.5, NS.Style.K.parch)
  b.text:SetAllPoints()
  b.text:SetJustifyH("LEFT")
  local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.05)
  shop.lines[i] = b
  return b
end

function NS.RefreshShopping()
  if not shop or not shop:IsShown() or not shop.mode then return end
  local list, tier = Missing(shop.mode == "vendor")
  for _, b in ipairs(shop.lines) do b:Hide() end
  if not list or #list == 0 then shop:Hide(); return end
  shop.sub:SetText("Peletería · " .. tier.recipe)
  local y, total, unknown = -54, 0, false
  for i, it in ipairs(list) do
    local b = ShopLine(i)
    b:SetAlpha(1)
    b:SetPoint("TOPLEFT", 12, y)
    local p = Price(it.id)
    local cost = p and (" · ~" .. Money(p * it.need)) or ""
    if p then total = total + p * it.need else unknown = true end
    b.text:SetText("|cffff9a40" .. it.need .. "x|r " .. it.name .. "|cff8c806b" .. cost .. "|r")
    b:SetScript("OnClick", function()
      if shop.mode == "auction" and NS.AHSearch and C_AuctionHouse then
        NS.AHSearch(it.id)
      elseif shop.mode == "auction" and CanSendAuctionQuery and CanSendAuctionQuery() then
        local name = GetItemInfo(it.id) or it.name
        if BrowseName then BrowseName:SetText(name) end
        QueryAuctionItems(name, nil, nil, 0, false, nil, false, true)
      elseif shop.mode == "vendor" then
        for j = 1, GetMerchantNumItems() do
          if IdFromLink(GetMerchantItemLink(j)) == it.id then
            local stack = select(8, GetItemInfo(it.id)) or it.need
            local left = it.need
            while left > 0 do
              local q = math.min(left, stack)
              BuyMerchantItem(j, q)
              left = left - q
            end
            Print("compraste " .. it.need .. "x " .. it.name .. ".")
            -- la línea comprada se desvanece y después la lista se reacomoda
            if NS.Tween and not DB().noAnim then NS.Tween(0.3, function(p) b:SetAlpha(1 - p) end, 0, nil, NS.OutCubic) end
            C_Timer.After(0.5, NS.RefreshShopping)
            return
          end
        end
        Print("este vendedor no tiene " .. it.name .. ".")
      end
    end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine(it.name, 0.85, 0.66, 0.25)
      GameTooltip:AddLine(shop.mode == "vendor" and "Clic: comprar lo que falta" or "Clic: buscarlo en la subasta", 1, 1, 1)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    b:Show()
    y = y - 19
  end
  shop.total:ClearAllPoints()
  shop.total:SetPoint("TOPLEFT", 12, y - 6)
  if total > 0 then
    shop.total:SetText("Total estimado: " .. Money(total) .. (unknown and " |cff8c806b(faltan precios)|r" or ""))
  else
    shop.total:SetText("|cff8c806bClic en cada línea para " .. (shop.mode == "vendor" and "comprarla" or "buscarla") .. "|r")
  end
  shop:SetHeight(-y + 30)
end

local function ShowShop(mode, anchor)
  NS.lastShopAnchor = anchor
  if DB().noShop or not anchor then return end
  local first = not shop
  if not shop then BuildShop() end
  local wasShown = not first and shop:IsShown()
  shop.mode = mode
  shop:ClearAllPoints()
  shop:SetPoint("TOPLEFT", anchor, "TOPRIGHT", mode == "vendor" and -30 or 4, mode == "vendor" and -12 or -12)
  shop:Show()
  NS.RefreshShopping()
  -- entra deslizándose desde el borde de la ventana del vendedor o la subasta
  if not wasShown and shop:IsShown() and NS.Appear then NS.Appear(shop, -14, 0, 0.25) end
end

----------------------------------------------------------------------
-- Limpieza de bolsas
----------------------------------------------------------------------
local selling
local function SellJunk(manual)
  if selling then return end
  local queue, total = {}, 0
  for bag = 0, 4 do
    for slot = 1, (NumSlots(bag) or 0) do
      local link, count, quality, noValue, id = SlotInfo(bag, slot)
      if link then
        if quality == nil or quality < 0 then quality = select(3, GetItemInfo(link)) end
        local price = select(11, GetItemInfo(link)) or 0
        local junk = quality == 0 or (DB().junk and id and DB().junk[id])
        if junk and not noValue and price > 0 then
          table.insert(queue, { bag, slot })
          total = total + price * (count or 1)
        end
      end
    end
  end
  if #queue == 0 then
    if manual then Print("no hay basura para vender.") end
    return
  end
  selling = true
  local i = 0
  local ticker
  ticker = C_Timer.NewTicker(0.2, function()
    i = i + 1
    local s = queue[i]
    if not s or not (MerchantFrame and MerchantFrame:IsShown()) then
      ticker:Cancel()
      selling = nil
      if not s then Print("vendiste " .. #queue .. " objeto(s) de basura por " .. Money(total) .. ".") end
      return
    end
    UseSlot(s[1], s[2])
  end)
end

local sellBtn
local function MerchantButton()
  if sellBtn or not MerchantFrame then return end
  sellBtn = CreateFrame("Button", nil, MerchantFrame, "UIPanelButtonTemplate")
  sellBtn:SetSize(110, 22)
  sellBtn:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", -44, -42)
  sellBtn:SetText("Vender basura")
  sellBtn:SetScript("OnClick", function() SellJunk(true) end)
  sellBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Códice de Piolin", 0.85, 0.66, 0.25)
    GameTooltip:AddLine("Vende todo lo gris y lo que marcaste con /piolin basura.", 1, 1, 1, true)
    GameTooltip:AddLine(DB().noAutoSell and "Venta automática: apagada" or "Venta automática: prendida", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  sellBtn:SetScript("OnLeave", GameTooltip_Hide)
end

----------------------------------------------------------------------
-- Pesca: contador de la sesión
----------------------------------------------------------------------
NS.fish = { casts = 0, items = {}, order = {} }

local function OnLoot()
  if not (IsFishingLoot and IsFishingLoot()) then return end
  NS.fish.casts = NS.fish.casts + 1
  for i = 1, GetNumLootItems() do
    local link = GetLootSlotLink(i)
    local id = IdFromLink(link)
    if id then
      local _, _, qty = GetLootSlotInfo(i)
      if NS.SetFlag then NS.SetFlag("caught" .. id) end
      if not NS.fish.items[id] then NS.fish.items[id] = { link = link, n = 0 }; table.insert(NS.fish.order, id) end
      NS.fish.items[id].n = NS.fish.items[id].n + (qty or 1)
    end
  end
  DB().fishTotal = (DB().fishTotal or 0) + 1
end

function NS.FishText()
  local f = NS.fish
  local lines = {}
  local rank, maxRank = NS.Skill("Pesca")
  if rank then table.insert(lines, "Pesca " .. C.B .. rank .. "/" .. maxRank .. C.E .. " · pescas en esta sesión: " .. C.B .. f.casts .. C.E .. " · en total: " .. (DB().fishTotal or 0)) end
  if f.casts == 0 then
    table.insert(lines, "|cff8c806bTodavía no pescaste en esta sesión.|r")
  else
    local value = 0
    for _, id in ipairs(f.order) do
      local it = f.items[id]
      local p = Price(id) or select(11, GetItemInfo(id)) or 0
      value = value + p * it.n
      table.insert(lines, "  " .. it.n .. "x " .. (it.link or id))
    end
    table.insert(lines, "Valor estimado: " .. Money(value) .. " |cff8c806b(subasta, o vendedor si no hay precio)|r")
  end
  return table.concat(lines, "\n")
end

----------------------------------------------------------------------
-- Desuello y avisos de tope
----------------------------------------------------------------------
function NS.MatsExtra()
  local lines = {}
  local skin = NS.Skill("Desuello")
  if skin then
    for _, z in ipairs(NS.SKIN_ZONES) do
      if skin < z.max then
        table.insert(lines, "\n" .. C.G .. "Dónde desollar (" .. skin .. "):" .. C.E .. " " .. z.t)
        break
      end
    end
  end
  local list = Missing()
  if list and #list > 0 then
    local total, n = 0, 0
    for _, it in ipairs(list) do
      local p = Price(it.id)
      if p then total = total + p * it.need; n = n + 1 end
    end
    if n > 0 then table.insert(lines, C.G .. "Comprar lo que falta:" .. C.E .. " ~" .. Money(total) .. (n < #list and " |cff8c806b(sin precio para " .. (#list - n) .. ")|r" or "")) end
  end
  return table.concat(lines, "\n")
end

local function CheckCaps()
  DB().capWarned = DB().capWarned or {}
  for prof, tips in pairs(NS.CAP_TIPS) do
    local rank, maxRank = NS.Skill(prof)
    if rank and tips[maxRank] and rank >= maxRank - 5 then
      local key = prof .. maxRank
      if not DB().capWarned[key] then
        DB().capWarned[key] = true
        NS.Alert("cap" .. key, prof .. " " .. rank .. "/" .. maxRank .. ": " .. tips[maxRank], "Interface\\Icons\\INV_Misc_Book_09", 0.41, 0.8, 0.94, 5)
        Print(C.H .. prof .. " cerca del tope:" .. C.E .. " " .. tips[maxRank])
      end
    end
  end
end

----------------------------------------------------------------------
-- Eventos
----------------------------------------------------------------------
local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "AUCTION_ITEM_LIST_UPDATE",
  "MERCHANT_SHOW", "MERCHANT_CLOSED", "LOOT_OPENED", "SKILL_LINES_CHANGED", "BAG_UPDATE_DELAYED" }) do
  pcall(ev.RegisterEvent, ev, e)
end

ev:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    DB().prices = DB().prices or {}
    C_Timer.After(5, CheckCaps)
  elseif event == "AUCTION_HOUSE_SHOW" then
    NS.scanStamp = time()
    if AuctionFrame and not scanBtn then
      scanBtn = CreateFrame("Button", nil, AuctionFrame, "UIPanelButtonTemplate")
      scanBtn:SetSize(150, 22)
      scanBtn:SetPoint("TOPRIGHT", AuctionFrame, "TOPRIGHT", -60, -14)
      scanBtn:SetText("Escanear materiales")
      scanBtn:SetScript("OnClick", StartScan)
      scanBtn:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Códice de Piolin", 0.85, 0.66, 0.25)
        GameTooltip:AddLine("Busca el precio de " .. #NS.SCAN_ITEMS .. " materiales (cueros, pieles, hilos, pescados, paños) y lo guarda para los tooltips. Tarda menos de un minuto.", 1, 1, 1, true)
        GameTooltip:Show()
      end)
      scanBtn:SetScript("OnLeave", GameTooltip_Hide)
    end
    if AuctionFrame then ShowShop("auction", AuctionFrame) end
  elseif event == "AUCTION_HOUSE_CLOSED" then
    if scan.queue then ScanDone() end
    if shop and shop.mode == "auction" then shop:Hide() end
  elseif event == "AUCTION_ITEM_LIST_UPDATE" then
    OnAuctionList()
  elseif event == "MERCHANT_SHOW" then
    MerchantButton()
    if not DB().noAutoSell then C_Timer.After(0.3, function() SellJunk(false) end) end
    ShowShop("vendor", MerchantFrame)
  elseif event == "MERCHANT_CLOSED" then
    if shop and shop.mode == "vendor" then shop:Hide() end
  elseif event == "LOOT_OPENED" then
    OnLoot()
  elseif event == "SKILL_LINES_CHANGED" then
    C_Timer.After(1, CheckCaps)
  elseif event == "BAG_UPDATE_DELAYED" then
    if shop and shop:IsShown() then NS.RefreshShopping() end
  end
end)

----------------------------------------------------------------------
-- Comandos nuevos
----------------------------------------------------------------------
function NS.TradeSlash(msg)
  if msg == "vender" then
    DB().noAutoSell = not DB().noAutoSell
    Print(DB().noAutoSell and "venta automática de basura apagada (queda el botón en el vendedor)." or "venta automática de basura prendida.")
    return true
  elseif msg == "precios" then
    DB().noPrices = not DB().noPrices
    Print(DB().noPrices and "precios en los tooltips ocultos." or "precios en los tooltips visibles.")
    return true
  elseif msg == "compras" then
    DB().noShop = not DB().noShop
    Print(DB().noShop and "lista de compras apagada." or "lista de compras prendida.")
    return true
  elseif msg:find("^basura") then
    -- acepta /piolin basura [objeto enlazado con shift-clic]
    local id = IdFromLink(msg)
    if not id then Print("usá /piolin basura y hacé shift-clic en el objeto para enlazarlo."); return true end
    DB().junk = DB().junk or {}
    DB().junk[id] = not DB().junk[id] or nil
    local name = GetItemInfo(id) or ("objeto " .. id)
    Print(DB().junk[id] and (name .. " se va a vender como basura.") or (name .. " ya no se vende como basura."))
    return true
  end
  return false
end

NS.ShowShop = function(mode, anchor) ShowShop(mode, anchor) end
