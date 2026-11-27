-- Códice de Piolin: casa de subastas moderna (la que usa WoW Forever)
-- Materiales = "mercancías": se compran por cantidad y el comprador siempre se lleva lo más barato.
local ADDON, NS = ...
if not C_AuctionHouse then return end   -- en Classic sigue funcionando la versión de Trade.lua y Gear.lua

local function DB() return NS.db end
local function Print(m) NS.Print(m) end
local function Money(c) return NS.Money(math.floor(c + 0.5)) end

local SORT = { { sortOrder = (Enum and Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Price) or 0, reverseSort = false } }

local function Key(id) return C_AuctionHouse.MakeItemKey(id) end

-- Guarda el precio más barato que muestran los resultados
local function ReadCommodity(id)
  local n = C_AuctionHouse.GetNumCommoditySearchResults and C_AuctionHouse.GetNumCommoditySearchResults(id) or 0
  if n > 0 then
    local r = C_AuctionHouse.GetCommoditySearchResultInfo(id, 1)
    if r and r.unitPrice and not NS.IsSecret(r.unitPrice) then
      local qty = C_AuctionHouse.GetCommoditySearchResultsQuantity and C_AuctionHouse.GetCommoditySearchResultsQuantity(id) or r.quantity
      NS.RecordPrice(id, r.unitPrice, qty)
      return true
    end
  end
end
local function ReadItem(itemKey)
  local n = C_AuctionHouse.GetNumItemSearchResults and C_AuctionHouse.GetNumItemSearchResults(itemKey) or 0
  if n > 0 then
    local r = C_AuctionHouse.GetItemSearchResultInfo(itemKey, 1)
    if r and r.buyoutAmount and not NS.IsSecret(r.buyoutAmount) then
      NS.RecordPrice(itemKey.itemID, r.buyoutAmount / math.max(1, r.quantity or 1), n)
      return true
    end
  end
end

----------------------------------------------------------------------
-- Búsqueda de un objeto (desde la lista de compras)
----------------------------------------------------------------------
function NS.AHSearch(id)
  local name = GetItemInfo(id)
  local bar = AuctionHouseFrame and AuctionHouseFrame.SearchBar
  if type(bar) ~= "table" then bar = nil end
  if bar and name then
    pcall(function()
      if bar.SearchBox and bar.SearchBox.SetText then bar.SearchBox:SetText(name) end
      if bar.StartSearch then bar:StartSearch() end
    end)
  end
  NS.scanStamp = time()
  if C_AuctionHouse.IsThrottledMessageSystemReady == nil or C_AuctionHouse.IsThrottledMessageSystemReady() then
    pcall(C_AuctionHouse.SendSearchQuery, Key(id), SORT, false)
  end
end

----------------------------------------------------------------------
-- Escaneo de materiales
----------------------------------------------------------------------
local scan, scanBtn
local function ScanFinish()
  if not scan then return end
  local got = 0
  for _, it in ipairs(NS.SCAN_ITEMS) do
    local p = DB().prices and DB().prices[it[1]]
    if p and p.scan == NS.scanStamp then got = got + 1 end
  end
  if scan.ticker then scan.ticker:Cancel() end
  scan = nil
  if scanBtn then scanBtn:SetText("Escanear materiales"); scanBtn:Enable() end
  Print("escaneo terminado: precio de " .. got .. " de " .. #NS.SCAN_ITEMS .. " materiales.")
  if NS.RefreshShopping then NS.RefreshShopping() end
end

local function ScanStep()
  if not scan then return end
  if scan.waiting and GetTime() - scan.sent < 4 then return end
  scan.waiting = false
  if scan.idx > #NS.SCAN_ITEMS then ScanFinish(); return end
  if C_AuctionHouse.IsThrottledMessageSystemReady and not C_AuctionHouse.IsThrottledMessageSystemReady() then return end
  local it = NS.SCAN_ITEMS[scan.idx]
  scan.current = it[1]
  scan.waiting, scan.sent = true, GetTime()
  pcall(C_AuctionHouse.SendSearchQuery, Key(it[1]), SORT, false)
  if scanBtn then scanBtn:SetText("Escaneando " .. scan.idx .. "/" .. #NS.SCAN_ITEMS) end
  scan.idx = scan.idx + 1
end

local function StartScan()
  if scan then return end
  NS.scanStamp = time()
  scan = { idx = 1, waiting = false, sent = 0 }
  if scanBtn then scanBtn:Disable() end
  scan.ticker = C_Timer.NewTicker(0.25, ScanStep)
end

----------------------------------------------------------------------
-- Ayudante para vender
----------------------------------------------------------------------
local helpers = {}
local function SellHelper(sellFrame, isCommodity)
  if not sellFrame or helpers[sellFrame] then return helpers[sellFrame] end
  local h = {}
  h.label = sellFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  h.label:SetWidth(260)
  h.label:SetJustifyH("LEFT")
  local anchor = sellFrame.PriceInput or sellFrame
  h.label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -26)
  h.btn = CreateFrame("Button", nil, sellFrame, "UIPanelButtonTemplate")
  h.btn:SetSize(150, 20)
  h.btn:SetPoint("TOPLEFT", h.label, "BOTTOMLEFT", 0, -4)
  h.btn:SetText("Usar precio Códice")
  h.btn:Hide()
  helpers[sellFrame] = h
  return h
end

local function ItemIdOf(sellFrame)
  local ok, loc = pcall(sellFrame.GetItem, sellFrame)
  if ok and loc then
    if type(loc) == "table" and C_Item.GetItemID then
      local ok2, id = pcall(C_Item.GetItemID, loc)
      if ok2 then return id end
    elseif type(loc) == "number" then
      return loc
    end
  end
end

local function UpdateHelper(sellFrame, isCommodity)
  if not NS.db or DB().noSellHelper then return end
  local h = SellHelper(sellFrame, isCommodity)
  local id = ItemIdOf(sellFrame)
  if not id then h.label:SetText(""); h.btn:Hide(); return end
  local unit, rec = NS.Price(id)
  local vendor = select(11, GetItemInfo(id)) or 0
  if not unit then
    h.label:SetText("|cffd9a93fCódice:|r sin precio guardado. Buscalo en la subasta o tocá Escanear materiales.")
    h.btn:Hide()
    return
  end
  -- en mercancías no sirve bajar: el comprador se lleva siempre lo más barato
  local suggest = isCommodity and unit or (unit >= 100 and math.floor(unit * 0.98) or math.max(1, unit - 1))
  local src = rec.seed and ("wowauctions " .. NS.SEED_DATE) or "tu último escaneo"
  local txt = "|cffd9a93fCódice:|r lo más barato hoy " .. Money(unit) .. " c/u (" .. src .. ")."
  if isCommodity then
    txt = txt .. "\nEn materiales no conviene bajar el precio: igualalo."
  else
    txt = txt .. "\nSugerido: " .. Money(suggest) .. " c/u."
  end
  if vendor > 0 and suggest * 0.95 < vendor * 1.25 then
    txt = txt .. "\n|cffffd96aOjo: al vendedor te pagan " .. Money(vendor) .. " c/u sin riesgo.|r"
  end
  h.label:SetText(txt)
  h.btn:Show()
  h.btn:SetScript("OnClick", function()
    local input = sellFrame.PriceInput
    local ok = input and input.SetAmount and pcall(input.SetAmount, input, suggest)
    if not ok and sellFrame.SetPrice then ok = pcall(sellFrame.SetPrice, sellFrame, suggest) end
    if not ok then Print("no pude poner el precio solo; escribilo vos: " .. Money(suggest) .. " c/u.") end
  end)
end

local hooked = false
local function HookSellFrames()
  if hooked or not AuctionHouseFrame then return end
  hooked = true
  local cf, itf = AuctionHouseFrame.CommoditiesSellFrame, AuctionHouseFrame.ItemSellFrame
  if type(cf) == "table" and cf.SetItem then hooksecurefunc(cf, "SetItem", function() C_Timer.After(0.2, function() UpdateHelper(cf, true) end) end) end
  if type(itf) == "table" and itf.SetItem then hooksecurefunc(itf, "SetItem", function() C_Timer.After(0.2, function() UpdateHelper(itf, false) end) end) end
end

----------------------------------------------------------------------
-- Eventos
----------------------------------------------------------------------
local ev = CreateFrame("Frame")
NS.SafeEvents(ev, { "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "COMMODITY_SEARCH_RESULTS_UPDATED", "ITEM_SEARCH_RESULTS_UPDATED" })
ev:SetScript("OnEvent", function(self, event, a1)
  if event == "AUCTION_HOUSE_SHOW" then
    NS.scanStamp = time()
    local f = AuctionHouseFrame
    if f and not scanBtn then
      scanBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
      scanBtn:SetSize(160, 22)
      scanBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -30, -28)
      scanBtn:SetText("Escanear materiales")
      scanBtn:SetScript("OnClick", StartScan)
      scanBtn:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Códice de Piolin", 0.85, 0.66, 0.25)
        GameTooltip:AddLine("Busca el precio de " .. #NS.SCAN_ITEMS .. " materiales y lo guarda para los tooltips y la lista de compras.", 1, 1, 1, true)
        GameTooltip:Show()
      end)
      scanBtn:SetScript("OnLeave", GameTooltip_Hide)
    end
    HookSellFrames()
    if f and NS.ShowShop then NS.ShowShop("auction", f) end
  elseif event == "AUCTION_HOUSE_CLOSED" then
    if scan then ScanFinish() end
  elseif event == "COMMODITY_SEARCH_RESULTS_UPDATED" then
    if ReadCommodity(a1) and scan and scan.current == a1 then scan.waiting = false end
    if NS.RefreshShopping then NS.RefreshShopping() end
  elseif event == "ITEM_SEARCH_RESULTS_UPDATED" then
    if type(a1) == "table" and ReadItem(a1) and scan and scan.current == a1.itemID then scan.waiting = false end
  end
end)
