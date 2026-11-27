-- Códice de Piolin: preferencias guardadas
-- PiolinCodexCharDB (por personaje): tildes, opciones, posiciones, notas.
-- PiolinCodexDB (cuenta): precios de la subasta, compartidos entre personajes, y una copia
-- de las opciones de cada personaje para poder copiarlas a otro.
-- Hasta la 4.5 todo estaba en PiolinCodexDB; la primera vez se copia solo al personaje.
local ADDON, NS = ...

-- Valores por defecto. Las opciones "no..." son interruptores invertidos: nil = prendido.
NS.DEFAULTS = {
  hudMode = "always",   -- always: siempre, combat: solo en combate, hidden: oculto
  hudScale = 1,
  winScale = 1,
  locked = true,        -- marcos bloqueados (no se arrastran)
  font = "inter",       -- inter: la letra del Códice, game: la del juego (o la de LibSharedMedia)
}

-- Qué se guarda en la cuenta y no en el personaje
local ACCOUNT = { prices = true }

-- Opciones que se copian entre personajes (perfil). Las tildes y las notas no.
local PROFILE_SKIP = { checks = true, notes = true, folded = true, prices = true, fishTotal = true, way = true,
  tentAt = true, tentWarned = true, capWarned = true, durWarned = true, flags = true, lastTab = true, dialogVolOrig = true }

local function CharKey()
  local name = UnitName and UnitName("player") or "?"
  local realm = GetRealmName and GetRealmName() or "?"
  return name .. " - " .. realm
end
NS.CharKey = CharKey

local function Copy(v)
  if type(v) ~= "table" then return v end
  local t = {}
  for k, x in pairs(v) do t[k] = Copy(x) end
  return t
end

function NS.InitDB()
  PiolinCodexDB = PiolinCodexDB or {}
  local acc = PiolinCodexDB
  -- 4.5 y antes: las preferencias estaban en la cuenta; se mueven a "legacy" una sola vez
  if not acc.v then
    local legacy = {}
    for k, v in pairs(acc) do if not ACCOUNT[k] then legacy[k] = v; acc[k] = nil end end
    if next(legacy) then acc.legacy = legacy end
    acc.v = 2
  end
  if type(PiolinCodexCharDB) ~= "table" then
    PiolinCodexCharDB = acc.legacy and Copy(acc.legacy) or {}
  end
  local db = PiolinCodexCharDB
  for k, v in pairs(NS.DEFAULTS) do if db[k] == nil then db[k] = Copy(v) end end
  db.checks = db.checks or {}
  acc.prices = acc.prices or db.prices or {}
  db.prices = acc.prices
  acc.profiles = acc.profiles or {}
  NS.db, NS.acc = db, acc
  return db
end

-- Al salir: los precios ya están en la cuenta (no se duplican) y se guarda la copia del perfil
function NS.SaveProfile()
  local db, acc = NS.db, NS.acc
  if not db or not acc then return end
  local snap = {}
  for k, v in pairs(db) do if not PROFILE_SKIP[k] then snap[k] = Copy(v) end end
  acc.profiles[CharKey()] = snap
end

function NS.OtherProfiles()
  local list, me = {}, CharKey()
  for k in pairs((NS.acc and NS.acc.profiles) or {}) do if k ~= me then table.insert(list, k) end end
  table.sort(list)
  return list
end

function NS.CopyProfile(key)
  local snap = NS.acc and NS.acc.profiles and NS.acc.profiles[key]
  if not snap then return false end
  for k in pairs(NS.db) do if not PROFILE_SKIP[k] then NS.db[k] = nil end end
  for k, v in pairs(snap) do NS.db[k] = Copy(v) end
  for k, v in pairs(NS.DEFAULTS) do if NS.db[k] == nil then NS.db[k] = Copy(v) end end
  return true
end

-- Vuelve una lista de opciones a su valor por defecto
function NS.ResetKeys(keys)
  for _, k in ipairs(keys) do NS.db[k] = Copy(NS.DEFAULTS[k]) end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGOUT")
ev:SetScript("OnEvent", function()
  NS.SaveProfile()
  if NS.db then NS.db.prices = nil end
end)

-- Marcos que se mueven: guardan su posición en el personaje y respetan "Bloquear marcos".
-- def = { punto, x, y } por defecto. NS.ResetPositions() los devuelve a su lugar.
NS.movables = {}
function NS.Movable(f, key, def)
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:RegisterForDrag("LeftButton")
  local function place()
    f:ClearAllPoints()
    local pos = NS.db and NS.db[key] or def
    f:SetPoint(pos[1], UIParent, pos[1], pos[2], pos[3])
  end
  f:SetScript("OnDragStart", function(self) if NS.db and not NS.db.locked then self:StartMoving() end end)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if not NS.db then return end
    local p, _, _, x, y = self:GetPoint()
    NS.db[key] = { p or "CENTER", math.floor((x or 0) + 0.5), math.floor((y or 0) + 0.5) }
  end)
  NS.movables[#NS.movables + 1] = { f = f, key = key, place = place }
  place()
  return place
end
-- Para los marcos que ya tenían su propio arrastre: solo se mueven con los marcos destrabados
function NS.DragStart(self) if NS.db and not NS.db.locked then self:StartMoving() end end
function NS.ResetPositions()
  for _, m in ipairs(NS.movables) do NS.db[m.key] = nil; m.place() end
end
