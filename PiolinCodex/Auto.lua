-- Códice de Piolin: más tildes automáticas (talentos, hechizos, objetos, ranuras y cosas que hiciste)
local ADDON, NS = ...

local function DB() return PiolinCodexDB end

----------------------------------------------------------------------
-- Reglas: cada tarea se tilda si se cumple CUALQUIERA de sus condiciones
--   { "talent", { {nombre, rango}, ... } }   todos esos talentos con ese rango o más
--   { "spell", { "Hechizo", ... } }            sabés todos esos hechizos o recetas
--   { "item", {ids}, {partes de nombre}, n }   tenés alguno (n unidades si se indica)
--   { "slot", {ranuras} }                      todas esas ranuras tienen algo puesto
--   { "flag", "clave" }                        algo que el Códice vio que hiciste
--   { "skill", "Oficio", valor, "max" }        oficio (o su tope) en ese valor o más
--   { "level", n }                             nivel n o más
----------------------------------------------------------------------
NS.AUTO.extra = {
  -- Personaje: talentos
  t21 = { { "talent", { { "Armas elementales", 3 } } } },
  t24 = { { "talent", { { "Anticipación", 1 } } } },
  t25 = { { "talent", { { "Golpe de tormenta", 1 } } }, { "spell", { "Golpe de tormenta" } } },
  t26 = { { "talent", { { "Lobo fantasmal mejorado", 2 } } } },
  t28 = { { "talent", { { "Ráfaga", 2 } } } },

  -- Misiones
  dm8 = { { "item", { 7230 }, { "martillo poderoso de smite", "smite's mighty hammer" } } },
  tr1 = { { "spell", { "Lobo fantasmal", "Choque de escarcha", "Ola de sanación inferior" } } },
  tr2 = { { "spell", { "Retirada totémica" } } },
  ah1 = { { "item", { 16083 }, { "pesca experta" } }, { "skill", "Pesca", 151, "max" } },
  ah2 = { { "item", { 16072 }, { "libro de cocina para expertos" } }, { "skill", "Cocina", 151, "max" } },
  ah3 = { { "item", { 6532 }, nil, 6 }, { "flag", "lure" } },
  ah4 = { { "item", { 4241 }, { "bolsa de lana verde" } } },
  tc2 = { { "item", nil, { "cinturón del camorrista", "guantes del camorrista", "brawler's belt", "brawler's gloves" } } },

  -- Ruta: al pasar cada etapa, sus zonas y mazmorras quedan hechas
  r20a = { { "level", 30 } }, r20b = { { "level", 30 } },
  r20c = { { "item", nil, { "heavehammer", "defensor de dalaran", "defender of dalaran" } } },
  r30a = { { "level", 40 } },
  r30d = { { "item", { 9449 }, { "crowd pummeler", "aporreamultitudes" } } },
  r30e = { { "item", nil, { "corpsemaker", "ravager", "bonebiter", "hacedor de cadáveres", "devastador", "muerdehuesos" } } },
  r30f = { { "talent", { { "Golpe de tormenta mejorado", 2 }, { "Armas de espíritu", 1 }, { "Ráfaga", 4 }, { "Arma vórtice", 1 } } } },
  r30g = { { "skill", "Equitación", 75 }, { "level", 40 } },
  r40a = { { "level", 50 } },
  r40b = { { "item", nil, { "bigger rock", "piedra más grande" } } },
  r40c = { { "level", 50 } },
  r40d = { { "talent", { { "Enfoque de las mareas", 5 }, { "Conciencia plena", 3 }, { "Enfoque totémico", 2 } } } },
  r50a = { { "level", 60 } }, r50b = { { "level", 60 } },
  r50c = { { "talent", { { "Arma vórtice", 3 }, { "Presteza mental", 2 }, { "Ráfaga", 5 }, { "Concusión", 5 } } } },
  r50d = { { "item", nil, { "beastslayer", "bonecrusher", "matabestias", "machacahuesos" } } },
  r50e = { { "skill", "Equitación", 150 } },

  -- Oficios
  lp1 = { { "spell", { "Bastidor de curtir" } } },
  lp3 = { { "spell", { "Rastrear bestias" } } },
  lp4 = { { "skill", "Primeros auxilios", 150 } },

  -- Pesca
  f2a = { { "spell", { "Siluro bigotudo" } }, { "skill", "Cocina", 175 } },
  f2b = { { "flag", "caught6308" }, { "item", { 6308 } } },
  f2c = { { "flag", "lure" } },
  f4b = { { "item", { 16970 }, { "velero azul de la costa salvaje", "savage coast blue sailfin" } }, { "skill", "Pesca", 226, "max" } },
  f4c = { { "item", { 16969 }, { "sar'theris", "sartheris" } }, { "skill", "Pesca", 226, "max" } },
  f4d = { { "item", { 16968 }, { "mahi mahi" } }, { "skill", "Pesca", 226, "max" } },
  f4e = { { "item", { 16967 }, { "feralas ahi", "ahi de feralas" } }, { "skill", "Pesca", 226, "max" } },
  f5a = { { "skill", "Pesca", 300 } },

}
-- Estas pasan a decidirse por la equitación aprendida, no solo por el nivel
NS.AUTO.level.r30g, NS.AUTO.level.r50e = nil, nil
NS.SKILL_ALIASES["Equitación"] = { "Equitación", "Riding" }

----------------------------------------------------------------------
-- Lectura del juego
----------------------------------------------------------------------
local function lower(s) return (s or ""):lower() end

-- Rangos de talentos: Compat.lua sabe leerlos tanto en Classic como en el motor moderno
local function TalentRanks()
  return NS.TalentRanks and NS.TalentRanks() or nil
end

-- ¿Sabés este hechizo o receta? Se confirma con el libro de hechizos cuando el cliente lo permite
local function Knows(spell)
  local ok, name, _, _, _, _, _, id = pcall(GetSpellInfo, spell)
  if not ok or not name then return false end
  if id and IsPlayerSpell then
    local ok2, known = pcall(IsPlayerSpell, id)
    if ok2 and known then return true end
    if IsSpellKnown then
      local ok3, k2 = pcall(IsSpellKnown, id)
      if ok3 and k2 then return true end
    end
    return false
  end
  return true
end

local function OwnedSnapshot()
  local names, ids = {}, {}
  local function add(link)
    if not link or NS.IsSecret and NS.IsSecret(link) then return end
    local id = tonumber(link:match("item:(%d+)"))
    if id then ids[id] = true end
    local n = link:match("%[(.-)%]") or (id and GetItemInfo(id))
    if n then names[#names + 1] = lower(n) end
  end
  for slot = 1, 19 do add(GetInventoryItemLink("player", slot)) end
  local CC = C_Container
  for bag = 0, 4 do
    local n = (CC and CC.GetContainerNumSlots or GetContainerNumSlots)(bag) or 0
    for s = 1, n do add((CC and CC.GetContainerItemLink or GetContainerItemLink)(bag, s)) end
    if bag > 0 and CC and CC.GetBagName then
      local bn = CC.GetBagName(bag)
      if bn then names[#names + 1] = lower(bn) end
    end
  end
  return names, ids
end

local function Eval(c, snap)
  local kind = c[1]
  if kind == "level" then
    return (UnitLevel("player") or 0) >= c[2]
  elseif kind == "skill" then
    local rank, maxRank = NS.Skill(c[2])
    local v = c[4] == "max" and maxRank or rank
    return v ~= nil and v >= c[3]
  elseif kind == "spell" then
    for _, s in ipairs(c[2]) do if not Knows(s) then return false end end
    return true
  elseif kind == "talent" then
    snap.talents = snap.talents == nil and (TalentRanks() or false) or snap.talents
    if not snap.talents then return false end
    for _, t in ipairs(c[2]) do
      if (snap.talents[lower(t[1])] or 0) < t[2] then return false end
    end
    return true
  elseif kind == "slot" then
    for _, s in ipairs(c[2]) do if not GetInventoryItemID("player", s) then return false end end
    return true
  elseif kind == "flag" then
    return DB().flags and DB().flags[c[2]] and true or false
  elseif kind == "item" then
    if c[2] then
      for _, id in ipairs(c[2]) do
        local n = GetItemCount(id, true) or 0
        if c[4] then if n >= c[4] then return true end
        elseif n > 0 or (snap.ids and snap.ids[id]) then return true end
      end
    end
    if c[3] then
      if not snap.names then snap.names, snap.ids = OwnedSnapshot() end
      for _, part in ipairs(c[3]) do
        for _, n in ipairs(snap.names) do if n:find(part, 1, true) then return true end end
      end
    end
    return false
  end
  return false
end

-- Lo llama la revisión general de tildes (PiolinCodex.lua)
function NS.AutoExtra(tick)
  local snap = {}
  for id, conds in pairs(NS.AUTO.extra) do
    if not DB().checks[id] then
      for _, c in ipairs(conds) do
        local ok, yes = pcall(Eval, c, snap)
        if ok and yes then tick(id); break end
      end
    end
  end
end

function NS.SetFlag(key)
  DB().flags = DB().flags or {}
  if not DB().flags[key] then
    DB().flags[key] = true
    C_Timer.After(0.5, function() if NS.AutoCheck then NS.AutoCheck(false) end end)
  end
end

----------------------------------------------------------------------
-- Cuándo volver a revisar
----------------------------------------------------------------------
local pending = false
local function Queue()
  if pending then return end
  pending = true
  C_Timer.After(2, function() pending = false; if NS.AutoCheck then NS.AutoCheck(false) end end)
end

local function PoleEquipped()
  local mh = GetInventoryItemID("player", 16)
  if not mh then return false end
  local _, _, _, _, _, _, _, _, _, _, _, classID, subID = GetItemInfo(mh)
  return classID == 2 and subID == 20
end

local ev = CreateFrame("Frame")
NS.SafeEvents(ev, { "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB",
  "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "TRAIT_CONFIG_UPDATED", "UNIT_INVENTORY_CHANGED", "UNIT_SPELLCAST_SUCCEEDED" })
ev:SetScript("OnEvent", function(self, event, unit, _, spellID)
  if event == "UNIT_INVENTORY_CHANGED" then
    if unit == "player" and PoleEquipped() and GetWeaponEnchantInfo() then NS.SetFlag("lure") end
    return
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    if unit == "player" and spellID then
      local n = GetSpellInfo(spellID)
      if n and not (NS.IsSecret and NS.IsSecret(n)) and (n:find("balorio") or n:find("Bauble") or n:find("Cebo")) then NS.SetFlag("lure") end
    end
    return
  end
  Queue()
end)
