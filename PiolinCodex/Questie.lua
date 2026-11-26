-- Códice de Piolin: puente con Questie (opcional)
-- Si Questie está instalado, el Códice usa su base de datos para saber dónde está quien da o
-- entrega una misión y dónde están los objetivos. Sin Questie, todo sigue igual que antes.
-- Questie.API (isReady, RegisterOnReady, RegisterForQuestUpdates) es su parte pública y estable;
-- las ubicaciones salen de sus módulos internos (QuestieDB, ZoneDB), así que todo va con pcall:
-- si una versión nueva de Questie los cambia, el Códice no se rompe, solo deja de usarlos.
local ADDON, NS = ...

local function DB() return PiolinCodexDB end
local function Print(msg) print("|cffd9a93fCódice:|r " .. msg) end

-- ¿Está Questie instalado? (aunque todavía no haya terminado de cargar)
function NS.HasQuestie()
  return type(Questie) == "table" and type(QuestieLoader) == "table"
end

-- ¿Está listo para responder?
function NS.QuestieOn()
  return NS.HasQuestie() and type(Questie.API) == "table" and Questie.API.isReady == true
end

local mods
local function Mods()
  if mods then return mods end
  if not NS.QuestieOn() then return nil end
  local ok1, qdb = pcall(QuestieLoader.ImportModule, QuestieLoader, "QuestieDB")
  local ok2, zdb = pcall(QuestieLoader.ImportModule, QuestieLoader, "ZoneDB")
  if ok1 and ok2 and type(qdb) == "table" and type(zdb) == "table" then mods = { db = qdb, zone = zdb } end
  return mods
end

----------------------------------------------------------------------
-- Ubicaciones
----------------------------------------------------------------------
local function PlayerPos()
  if not (C_Map and C_Map.GetBestMapForUnit) then return nil end
  local map = C_Map.GetBestMapForUnit("player")
  if not map then return nil end
  local pos = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(map, "player")
  if not pos then return map end
  local x, y = pos.x, pos.y
  if pos.GetXY then x, y = pos:GetXY() end
  return map, (x or 0) * 100, (y or 0) * 100
end

-- Agrega los lugares de aparición { [zona] = { {x, y}, ... } } a la lista de candidatos
local function AddSpawns(list, spawns, name)
  if type(spawns) ~= "table" then return end
  local m = Mods()
  for areaId, points in pairs(spawns) do
    local ok, uiMap = pcall(m.zone.GetUiMapIdByAreaId, m.zone, areaId)
    if ok and uiMap and type(points) == "table" then
      for _, p in ipairs(points) do
        if type(p) == "table" and type(p[1]) == "number" and p[1] >= 0 and p[2] >= 0 then
          table.insert(list, { map = uiMap, x = p[1], y = p[2], name = name })
        end
      end
    end
  end
end

local function NpcSpots(list, id)
  local m = Mods()
  local ok, npc = pcall(m.db.GetNPC, m.db, id)
  if ok and type(npc) == "table" then AddSpawns(list, npc.spawns, npc.name) end
end

local function ObjectSpots(list, id)
  local m = Mods()
  local ok, obj = pcall(m.db.GetObject, m.db, id)
  if ok and type(obj) == "table" then AddSpawns(list, obj.spawns, obj.name) end
end

local function ItemSpots(list, id)
  local m = Mods()
  if type(m.db.QueryItemSingle) ~= "function" then return end
  local ok1, npcs = pcall(m.db.QueryItemSingle, id, "npcDrops")
  if ok1 and type(npcs) == "table" then
    for k, npcId in ipairs(npcs) do
      if k > 12 then break end   -- con los primeros alcanza para encontrar uno cerca
      NpcSpots(list, npcId)
    end
  end
  local ok2, objs = pcall(m.db.QueryItemSingle, id, "objectDrops")
  if ok2 and type(objs) == "table" then
    for k, objId in ipairs(objs) do
      if k > 12 then break end
      ObjectSpots(list, objId)
    end
  end
end

-- NPC y objetos que dan o entregan: { NPC = {ids}, GameObject = {ids} }
local function PeopleSpots(list, who)
  if type(who) ~= "table" then return end
  for _, id in ipairs(who.NPC or {}) do NpcSpots(list, id) end
  for _, id in ipairs(who.GameObject or {}) do ObjectSpots(list, id) end
end

-- El candidato más cercano: primero los de tu mapa, por distancia
local function Nearest(list)
  if #list == 0 then return nil end
  local map, px, py = PlayerPos()
  local best, bestD
  for _, c in ipairs(list) do
    local d
    if map and c.map == map and px then
      d = math.sqrt((c.x - px) ^ 2 + (c.y - py) ^ 2)
    else
      d = 1e6
    end
    if not bestD or d < bestD then best, bestD = c, d end
  end
  return best, bestD and bestD < 1e6 and bestD or nil
end

----------------------------------------------------------------------
-- Estado de la misión en tu registro
----------------------------------------------------------------------
local function LogIndex(questID)
  if GetQuestLogIndexByID then
    local ok, i = pcall(GetQuestLogIndexByID, questID)
    if ok and i and i > 0 then return i end
  end
  if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
    local ok, i = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
    if ok and i and i > 0 then return i end
  end
end

local function IsComplete(questID, logIndex)
  if C_QuestLog and C_QuestLog.IsComplete then
    local ok, v = pcall(C_QuestLog.IsComplete, questID)
    if ok and v ~= nil then return v and true or false end
  end
  if GetQuestLogTitle and logIndex then
    local _, _, _, _, _, done = GetQuestLogTitle(logIndex)
    return done == 1 or done == true
  end
  return false
end

-- Objetivos { {text, finished}, ... } en el orden del registro
local function Objectives(questID, logIndex)
  local out = {}
  if C_QuestLog and C_QuestLog.GetQuestObjectives then
    local ok, objs = pcall(C_QuestLog.GetQuestObjectives, questID)
    if ok and type(objs) == "table" and #objs > 0 then
      for _, o in ipairs(objs) do table.insert(out, { text = o.text, finished = o.finished }) end
      return out
    end
  end
  if logIndex and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
    local ok, n = pcall(GetNumQuestLeaderBoards, logIndex)
    for i = 1, (ok and n or 0) do
      local text, _, finished = GetQuestLogLeaderBoard(i, logIndex)
      table.insert(out, { text = text, finished = finished and true or false })
    end
  end
  return out
end

----------------------------------------------------------------------
-- A dónde ir para avanzar una misión
----------------------------------------------------------------------
-- Devuelve: punto { mapa, x, y, título }, qué es ("give" | "turnin" | "objective"), distancia en el mapa
function NS.QuestieTarget(questID)
  local m = Mods()
  if not m or not questID then return nil end
  local ok, q = pcall(m.db.GetQuest, questID)
  if not ok or type(q) ~= "table" then return nil end
  local qname = q.name or ("misión " .. questID)
  local logIndex = LogIndex(questID)
  local list, kind = {}, nil

  if not logIndex then
    PeopleSpots(list, q.Starts)
    kind = "give"
  elseif IsComplete(questID, logIndex) then
    PeopleSpots(list, q.Finisher)
    kind = "turnin"
  else
    local objs = Objectives(questID, logIndex)
    for i, od in ipairs(q.ObjectiveData or {}) do
      local st = objs[i]
      if not (st and st.finished) then
        if od.Type == "monster" then NpcSpots(list, od.Id)
        elseif od.Type == "object" then ObjectSpots(list, od.Id)
        elseif od.Type == "item" then ItemSpots(list, od.Id) end
        if #list > 0 then kind = "objective"; break end
      end
    end
    if #list == 0 then PeopleSpots(list, q.Finisher); kind = "turnin" end
  end

  local best, dist = Nearest(list)
  if not best then return nil end
  local verb = kind == "give" and "Aceptar" or (kind == "turnin" and "Entregar" or "Objetivo")
  local who = best.name and (" · " .. best.name) or ""
  return { best.map, math.floor(best.x * 10 + 0.5) / 10, math.floor(best.y * 10 + 0.5) / 10, verb .. ": " .. qname .. who }, kind, dist
end

-- Pone la flecha hacia el próximo paso de esa misión
function NS.QuestieGo(questID)
  if not NS.HasQuestie() then Print("instalá Questie para usar esta flecha."); return end
  if not NS.QuestieOn() then Print("Questie todavía está cargando; probá en unos segundos."); return end
  local wp = NS.QuestieTarget(questID)
  if not wp then Print("Questie no tiene la ubicación de esa misión."); return end
  NS.GoTo(wp)
end

-- Entre las misiones de tu registro: la más cercana para entregar ("turnin") o para avanzar ("objective")
function NS.QuestieNearest(want)
  if not Mods() then return nil end
  local best, bestD, bestWp
  local n = GetNumQuestLogEntries and GetNumQuestLogEntries() or 0
  for i = 1, n do
    local title, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)
    if title and not isHeader and questID then
      local wp, kind, d = NS.QuestieTarget(questID)
      if wp and kind == want then
        local score = d or 1e6
        if not bestD or score < bestD then best, bestD, bestWp = questID, score, wp end
      end
    end
  end
  return bestWp, best, bestD and bestD < 1e6 and bestD or nil
end

----------------------------------------------------------------------
-- Tarjeta en la pestaña Misiones (debajo de "Tu registro de misiones")
----------------------------------------------------------------------
NS.PageExtras = NS.PageExtras or {}
local baseMisiones = NS.PageExtras.misiones
NS.PageExtras.misiones = function(P, H)
  if baseMisiones then baseMisiones(P, H) end
  -- sin Questie la tarjeta solo tendría botones que no hacen nada
  if not NS.HasQuestie() then return end
  local K, CW = H.K, H.CW
  local card = P:Card("Con Questie", "Interface\\Icons\\INV_Misc_Map02", K.water)
  local status = card:Text(" ", 11.5, K.parch)
  local function Btn(label, x)
    local b = CreateFrame("Button", nil, card.frame, "UIPanelButtonTemplate")
    if NS.Style then NS.Style.SkinButton(b) end
    b:SetSize(math.floor((CW - 40) / 2), 24)
    b:SetPoint("TOPLEFT", x, card.y - 2)
    b:SetText(label)
    return b
  end
  local turnin = Btn("Ir a entregar la más cercana", 14)
  local nextObj = Btn("Ir al próximo objetivo", 14 + math.floor((CW - 40) / 2) + 12)
  card.y = card.y - 32
  local detail = card:Text(" \n ", 11, K.mute)
  if detail.SetMaxLines then detail:SetMaxLines(2) end
  card:Text("Las misiones de la guía también tienen “Ir”: te lleva a quien la da, al objetivo que falta o a quien la entrega.", 10, K.dim)
  card:Finish()

  local function Go(want, none)
    local wp = NS.QuestieNearest(want)
    if wp then NS.GoTo(wp) else Print(none) end
  end
  turnin:SetScript("OnClick", function() Go("turnin", "no tenés misiones listas para entregar con ubicación en Questie.") end)
  nextObj:SetScript("OnClick", function() Go("objective", "no encontré objetivos pendientes con ubicación en Questie.") end)

  table.insert(P.refreshers, function()
    local has, on = NS.HasQuestie(), NS.QuestieOn()
    turnin:SetEnabled(on); nextObj:SetEnabled(on)
    if not has then
      status:SetText("|cff8892a3Questie no está instalado. Si lo instalás, acá aparecen flechas a cada misión.|r")
      detail:SetText(" ")
    elseif not on then
      status:SetText("Questie está cargando…")
      detail:SetText(" ")
    else
      status:SetText("|cff7fd16aQuestie conectado.|r Las flechas usan su base de datos.")
      local wp1, _, d1 = NS.QuestieNearest("turnin")
      local wp2, _, d2 = NS.QuestieNearest("objective")
      -- d es la distancia en el mapa de la zona (0-100): menos de 8 es a pocos pasos
      local function line(wp, d) return wp[4] .. "  |cff8892a3(" .. (not d and "otra zona" or (d < 8 and "muy cerca" or "en tu zona")) .. ")|r" end
      detail:SetText((wp1 and line(wp1, d1) or "Nada para entregar.") .. "\n" .. (wp2 and line(wp2, d2) or "Sin objetivos pendientes."))
    end
  end)
end

----------------------------------------------------------------------
-- Cuando Questie termina de cargar o cambia una misión, se refresca la ventana
----------------------------------------------------------------------
local pending
local function Refresh()
  if pending then return end
  pending = true
  C_Timer.After(0.5, function()
    pending = false
    if NS.frame and NS.frame:IsShown() and NS.RefreshLive then NS.RefreshLive() end
  end)
end

local ev = CreateFrame("Frame")
NS.SafeEvents(ev, { "PLAYER_LOGIN" })
ev:SetScript("OnEvent", function()
  if not NS.HasQuestie() or type(Questie.API) ~= "table" then return end
  local api = Questie.API
  if type(api.RegisterOnReady) == "function" then
    pcall(api.RegisterOnReady, function()
      mods = nil
      Refresh()
      if type(api.RegisterForQuestUpdates) == "function" then pcall(api.RegisterForQuestUpdates, Refresh) end
    end)
  end
end)
