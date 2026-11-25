-- Códice de Piolin: instructores de tu clase y tus oficios
-- 1) rastreo de instructores del propio juego en el minimapa
-- 2) lista propia de Forever con el más cercano, los de tu zona y el botón "Ir"
-- Fuente de ubicaciones: Warcraft Tavern, guías de instructores de WoW Forever (noviembre 2026)
local ADDON, NS = ...

local function DB() return PiolinCodexDB end
local function Print(m) NS.Print(m) end

-- Zonas: nombres posibles en el cliente y número de mapa de Classic como respaldo
local Z = {
  dunmorogh = { 1426, { "Dun Morogh" } },
  forjaz = { 1455, { "Forjaz", "Ironforge" } },
  elwynn = { 1429, { "Bosque de Elwynn", "Elwynn Forest" } },
  ventormenta = { 1453, { "Ventormenta", "Ciudad de Ventormenta", "Stormwind City" } },
  teldrassil = { 1438, { "Teldrassil" } },
  darnassus = { 1457, { "Darnassus" } },
  lochmodan = { 1432, { "Loch Modan" } },
  crestagrana = { 1433, { "Montañas Crestagrana", "Redridge Mountains" } },
  humedales = { 1437, { "Los Humedales", "Humedales", "Wetlands" } },
  vallefresno = { 1440, { "Vallefresno", "Ashenvale" } },
  interior = { 1425, { "Tierras del Interior", "The Hinterlands" } },
  trabalomas = { 1424, { "Laderas de Trabalomas", "Hillsbrad Foothills" } },
  alterac = { 1416, { "Montañas de Alterac", "Alterac Mountains" } },
  tuercespina = { 1434, { "Vega de Tuercespina", "Stranglethorn Vale" } },
  feralas = { 1444, { "Feralas" } },
  zephras = { 0, { "Isla de Zephras", "Isla Zephras", "Zephras Isle" } },
}

-- { oficio, nombre, zona, x, y, lugar, rango }
NS.TRAINERS = {
  -- Chamán
  { "Chamán", "Eldrun Stormbreaker", "forjaz", 47.3, 13.5, "Caverna Desolada", "Todos los rangos" },
  { "Chamán", "Ingrid Dunwald", "dunmorogh", 47.5, 52.0, "Kharanos", "Todos los rangos" },
  { "Chamán", "Farseer Maret Firetend", "interior", 14.4, 42.6, "Nido Aquilino", "Todos los rangos" },
  { "Chamán", "Teo Hammerstorm", "dunmorogh", 28.9, 66.2, "Valle de Crestanevada", "Solo hasta nivel 6" },
  -- Peletería
  { "Peletería", "Fimble Finespindle", "forjaz", 39.8, 33.5, "La Gran Fundición", "Oficial (hasta 150)" },
  { "Peletería", "Gretta Finespindle", "forjaz", 39.6, 33.8, "La Gran Fundición", "Aprendiz (hasta 75)" },
  { "Peletería", "Simon Tanner", "ventormenta", 71.9, 62.7, "Casco Antiguo", "Oficial (hasta 150)" },
  { "Peletería", "Randal Worth", "ventormenta", 71.9, 62.6, "Casco Antiguo", "Aprendiz (hasta 75)" },
  { "Peletería", "Adele Fielder", "elwynn", 46.4, 62.1, "Villadorada", "Aprendiz (hasta 75)" },
  { "Peletería", "Telonis", "darnassus", 64.6, 21.5, "Bancal del Artesano", "Experto (hasta 225)" },
  { "Peletería", "Faldron", "darnassus", 64.4, 21.6, "Bancal del Artesano", "Oficial (hasta 150)" },
  { "Peletería", "Aayndia Floralwind", "vallefresno", 35.9, 52.1, "Astranaar", "Oficial (hasta 150)" },
  { "Peletería", "Drakk Stonehand", "interior", 13.4, 43.4, "Nido Aquilino", "Artesano (hasta 300)" },
  -- Desuello
  { "Desuello", "Balthus Stoneflayer", "forjaz", 39.6, 32.8, "La Gran Fundición", "Todos los rangos" },
  { "Desuello", "Maris Granger", "ventormenta", 72.3, 62.3, "Casco Antiguo", "Todos los rangos" },
  { "Desuello", "Helene Peltskinner", "elwynn", 46.3, 62.2, "Villadorada", "Todos los rangos" },
  { "Desuello", "Wilma Ranthal", "crestagrana", 83.6, 71.1, "Cañón Pizarra", "Todos los rangos" },
  { "Desuello", "Eladriel", "darnassus", 64.2, 21.7, "Bancal del Artesano", "Todos los rangos" },
  { "Desuello", "Jayla", "vallefresno", 50.1, 67.2, "Refugio Brisa de Plata", "Todos los rangos" },
  { "Desuello", "Brighid Stormflayer", "dunmorogh", 29.2, 67.7, "Valle de Crestanevada", "Aprendiz (hasta 75)" },
  -- Pesca (el experto se aprende con libro)
  { "Pesca", "Grimnur Stonebrand", "forjaz", 48.5, 6.2, "Caverna Desolada", "Oficial (hasta 150)" },
  { "Pesca", "Warg Deepwater", "lochmodan", 40.5, 39.4, "El Lago", "Oficial (hasta 150)" },
  { "Pesca", "Paxton Ganter", "dunmorogh", 35.6, 40.4, "Lago Corriente Helada", "Oficial (hasta 150)" },
  { "Pesca", "Matthew Hooper", "crestagrana", 21.5, 51.0, "Villa del Lago", "Oficial (hasta 150)" },
  { "Pesca", "Arnold Leland", "ventormenta", 55.1, 69.6, "Distrito de Mercaderes", "Oficial (hasta 150)" },
  { "Pesca", "Lee Brown", "elwynn", 47.6, 62.3, "Villadorada", "Oficial (hasta 150)" },
  { "Pesca", "Harold Riggs", "humedales", 8.2, 58.3, "Puerto de Menethil", "Oficial (hasta 150)" },
  { "Pesca", "Myizz Luckycatch", "tuercespina", 27.5, 77.2, "Bahía del Botín", "Oficial (hasta 150)" },
  -- Cocina (el experto se aprende con libro)
  { "Cocina", "Daryl Riknussun", "forjaz", 60.4, 38.1, "La Gran Fundición", "Oficial (hasta 150)" },
  { "Cocina", "Gremlock Pilsnor", "dunmorogh", 47.6, 52.4, "Kharanos", "Oficial (hasta 150)" },
  { "Cocina", "Cook Ghilm", "dunmorogh", 68.4, 54.5, "Cantera de Gol'Bolar", "Oficial (hasta 150)" },
  { "Cocina", "Crystal Boughman", "crestagrana", 17.7, 43.6, "Villa del Lago", "Oficial (hasta 150)" },
  { "Cocina", "Stephen Ryback", "ventormenta", 78.3, 53.1, "Casco Antiguo", "Oficial (hasta 150)" },
  { "Cocina", "Tomas", "elwynn", 44.3, 66.0, "Villadorada", "Oficial (hasta 150)" },
  -- Primeros auxilios
  { "Primeros auxilios", "Nissa Firestone", "forjaz", 54.8, 58.6, "La Gran Fundición", "Oficial (hasta 150)" },
  { "Primeros auxilios", "Thamner Pol", "dunmorogh", 47.2, 52.6, "Kharanos", "Oficial (hasta 150)" },
  { "Primeros auxilios", "Fremal Doohickey", "humedales", 10.8, 61.1, "Puerto de Menethil", "Oficial (hasta 150)" },
  { "Primeros auxilios", "Shaina Fuller", "ventormenta", 52.9, 44.9, "Plaza de la Catedral", "Oficial (hasta 150)" },
  { "Primeros auxilios", "Michelle Belle", "elwynn", 43.4, 65.7, "Villadorada", "Oficial (hasta 150)" },
}
NS.TRAINER_ZONES = Z
local PROFS = { "Chamán", "Peletería", "Desuello", "Pesca", "Cocina", "Primeros auxilios" }
local PROF_ICON = {
  ["Chamán"] = "Interface\\Icons\\Spell_Nature_BloodLust",
  ["Peletería"] = "Interface\\Icons\\Trade_LeatherWorking",
  ["Desuello"] = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
  ["Pesca"] = "Interface\\Icons\\Trade_Fishing",
  ["Cocina"] = "Interface\\Icons\\INV_Misc_Food_15",
  ["Primeros auxilios"] = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
}

----------------------------------------------------------------------
-- Ubicación y distancias
----------------------------------------------------------------------
local mapOf = {}
local function MapFor(zkey)
  if mapOf[zkey] then return mapOf[zkey] end
  local z = Z[zkey]
  local m = NS.ResolveMap(z[1], z[2])
  mapOf[zkey] = m
  return m
end

local function WorldPos(map, x, y)
  if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) or not map or map == 0 then return nil end
  local ok, inst, pos = pcall(C_Map.GetWorldPosFromMapPos, map, CreateVector2D(x, y))
  if ok and pos then
    local a, b = pos:GetXY()
    return inst, a, b
  end
end

local function PlayerWorld()
  local map = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  if not map then return nil end
  local p = C_Map.GetPlayerMapPosition(map, "player")
  if not p then return nil, nil, nil, map end
  local x, y = p:GetXY()
  local inst, a, b = WorldPos(map, x, y)
  return inst, a, b, map
end

-- Ordena los instructores de un oficio: primero los de tu zona, después por distancia
local function Ranked(prof)
  local inst, pa, pb, myMap = PlayerWorld()
  local list = {}
  local level = UnitLevel("player") or 1
  local rank = prof ~= "Chamán" and NS.Skill(prof) or nil
  for _, t in ipairs(NS.TRAINERS) do
    if t[1] == prof then
      local map = MapFor(t[3])
      local e = { t = t, map = map, same = (map == myMap) }
      -- los que ya no te pueden enseñar nada quedan al final
      if (t[7]:find("^Aprendiz") and (rank or 0) >= 50) or (t[7]:find("nivel 6") and level > 6) then e.useless = true end
      local ti, ta, tb = WorldPos(map, t[4] / 100, t[5] / 100)
      if inst and ti == inst and pa then
        e.dist = math.sqrt((ta - pa) ^ 2 + (tb - pb) ^ 2)
      end
      table.insert(list, e)
    end
  end
  table.sort(list, function(a, b)
    if (a.useless or false) ~= (b.useless or false) then return not a.useless end
    if a.same ~= b.same then return a.same end
    if a.dist and b.dist then return a.dist < b.dist end
    if a.dist then return true end
    if b.dist then return false end
    return false
  end)
  return list
end
NS.RankedTrainers = Ranked

local function ZoneName(zkey) return Z[zkey][2][1] end

local function GoTrainer(e)
  local t = e.t
  local map = MapFor(t[3])
  NS.SetWaypoint(map, t[4], t[5], t[2] .. " (" .. t[1] .. ")")
end

----------------------------------------------------------------------
-- 1) Rastreo de instructores del juego en el minimapa
----------------------------------------------------------------------
local function TrackingAPI()
  if C_Minimap and C_Minimap.GetNumTrackingTypes then
    return C_Minimap.GetNumTrackingTypes, function(i)
      local info = C_Minimap.GetTrackingInfo(i)
      if type(info) == "table" then return info.name, info.texture, info.active end
      return info
    end, C_Minimap.SetTracking
  end
  if GetNumTrackingTypes and GetTrackingInfo and SetTracking then return GetNumTrackingTypes, GetTrackingInfo, SetTracking end
end

local function TrainerTrackers()
  local num, info = TrackingAPI()
  local out = {}
  if not num then return out end
  for i = 1, num() do
    local name, tex, active = info(i)
    local n = type(name) == "string" and name:lower() or ""
    local t = type(tex) == "string" and tex:lower() or ""
    if n:find("instructor") or n:find("trainer") or t:find("tracking\\class") or t:find("tracking\\profession") then
      table.insert(out, { i = i, name = name, active = active })
    end
  end
  return out
end

function NS.SetTrainerTracking(on, quiet)
  local _, _, set = TrackingAPI()
  local list = TrainerTrackers()
  if not set or #list == 0 then
    if not quiet then Print("este cliente no ofrece el rastreo de instructores en el minimapa.") end
    return false
  end
  for _, tr in ipairs(list) do pcall(set, tr.i, on and true or false) end
  if not quiet then Print(on and "rastreo de instructores prendido: aparecen en el minimapa." or "rastreo de instructores apagado.") end
  return true
end

local function TrackingOn()
  for _, tr in ipairs(TrainerTrackers()) do if tr.active then return true end end
  return false
end

----------------------------------------------------------------------
-- 2) Tarjeta "Instructores" en la pestaña Oficios
----------------------------------------------------------------------
NS.PageExtras = NS.PageExtras or {}
NS.PageExtras.oficios = function(P, H)
  local K, CW = H.K, H.CW
  local card = P:Card("Instructores", "Interface\\Icons\\INV_Misc_Book_09", K.water)
  local track = CreateFrame("Button", nil, card.frame, "UIPanelButtonTemplate")
  if NS.Style then NS.Style.SkinButton(track) end
  track:SetSize(180, 22)
  track:SetPoint("TOPRIGHT", -12, -7)
  local function paintTrack() track:SetText(TrackingOn() and "Minimapa: rastreando" or "Rastrear en el minimapa") end
  track:SetScript("OnClick", function() NS.SetTrainerTracking(not TrackingOn()); C_Timer.After(0.2, paintTrack) end)
  track:SetScript("OnEnter", function(b)
    GameTooltip:SetOwner(b, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("Rastreo de instructores", 0.85, 0.66, 0.25)
    GameTooltip:AddLine("Prende el rastreo del propio juego: los instructores cercanos aparecen como íconos en el minimapa.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  track:SetScript("OnLeave", GameTooltip_Hide)
  local zoneLine = card:Text(" ", 11, K.mute)
  local rows = {}
  for i, prof in ipairs(PROFS) do
    local r = {}
    r.icon = H.Framed(card.frame, PROF_ICON[prof], 22)
    r.icon:SetPoint("TOPLEFT", 16, card.y - 2)
    r.name = H.Text(card.frame, 12, K.gold)
    r.name:SetPoint("TOPLEFT", 48, card.y)
    r.name:SetText(prof)
    r.info = H.Text(card.frame, 11, K.parch)
    r.info:SetPoint("TOPLEFT", 48, card.y - 15)
    r.info:SetWidth(CW - 48 - 110)
    r.go = CreateFrame("Button", nil, card.frame, "UIPanelButtonTemplate")
    if NS.Style then NS.Style.SkinButton(r.go) end
    r.go:SetSize(84, 22)
    r.go:SetPoint("TOPRIGHT", -14, card.y - 4)
    r.go:SetText("Ir")
    rows[i] = r
    card.y = card.y - 38
  end
  card:Text("Primero los de tu zona; si no hay, el más cercano. Pasá el mouse por “Ir” para ver otros.", 10, K.dim)
  card:Finish()

  table.insert(P.refreshers, function()
    paintTrack()
    local myMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local info = myMap and C_Map.GetMapInfo and C_Map.GetMapInfo(myMap)
    zoneLine:SetText("Estás en: |cffffd96a" .. (info and info.name or "?") .. "|r")
    for i, prof in ipairs(PROFS) do
      local r = rows[i]
      local list = Ranked(prof)
      local best = list[1]
      if best then
        local t = best.t
        local where = t[6] .. ", " .. ZoneName(t[3])
        local tag = best.same and "|cff7fd16aen tu zona|r" or (best.dist and ("a " .. math.floor(best.dist + 0.5) .. " m") or "en otra zona")
        r.info:SetText(t[2] .. " · " .. where .. " · " .. tag .. "\n|cff8899aa" .. t[7] .. "|r")
        r.go:SetScript("OnClick", function() GoTrainer(best) end)
        r.go:SetScript("OnEnter", function(b)
          GameTooltip:SetOwner(b, "ANCHOR_LEFT")
          GameTooltip:AddLine("Instructores de " .. prof, 0.85, 0.66, 0.25)
          for k = 1, math.min(5, #list) do
            local e = list[k]
            local d = e.same and "en tu zona" or (e.dist and (math.floor(e.dist + 0.5) .. " m") or ZoneName(e.t[3]))
            GameTooltip:AddDoubleLine(e.t[2] .. " (" .. e.t[6] .. ")", d, 1, 1, 1, 0.7, 0.7, 0.7)
          end
          GameTooltip:AddLine("Clic: flecha y marca hacia " .. t[2], 0.6, 0.6, 0.6)
          GameTooltip:Show()
        end)
        r.go:SetScript("OnLeave", GameTooltip_Hide)
      end
    end
  end)
end

----------------------------------------------------------------------
-- Eventos y comandos
----------------------------------------------------------------------
local CITIES = { forjaz = true, ventormenta = true, darnassus = true }
local autoTracked = false
local ev = CreateFrame("Frame")
NS.SafeEvents(ev, { "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD" })
ev:SetScript("OnEvent", function()
  C_Timer.After(1, function()
    if not PiolinCodexDB then return end
    if NS.frame and NS.frame:IsShown() then NS.RefreshLive() end
    if DB().noAutoTrack then return end
    local myMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local inCity = false
    for zkey in pairs(CITIES) do if myMap and MapFor(zkey) == myMap then inCity = true end end
    if inCity and not TrackingOn() then
      if NS.SetTrainerTracking(true, true) then autoTracked = true end
    elseif not inCity and autoTracked then
      NS.SetTrainerTracking(false, true)
      autoTracked = false
    end
  end)
end)

local prev = NS.TradeSlash
NS.TradeSlash = function(msg)
  local q = msg:match("^instructor%s*(.*)$")
  if q then
    local target
    for _, p in ipairs(PROFS) do if q ~= "" and p:lower():find(q, 1, true) then target = p end end
    if not target then
      Print("usá /piolin instructor y un oficio: chamán, peletería, desuello, pesca, cocina o primeros auxilios.")
      return true
    end
    local best = Ranked(target)[1]
    if best then GoTrainer(best) end
    return true
  elseif msg == "rastreo" then
    NS.SetTrainerTracking(not TrackingOn())
    return true
  end
  return prev and prev(msg) or false
end
