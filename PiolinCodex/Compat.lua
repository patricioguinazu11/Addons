-- Códice de Piolin: compatibilidad con el motor moderno de WoW Forever
-- Si el cliente no tiene una función de Classic, la armamos con su versión moderna.
local ADDON, NS = ...

local function missing(name) return _G[name] == nil end

-- ¿Estamos en WoW Forever? (su tipo de juego interno se llama Camelot)
NS.IsForever = (WOW_PROJECT_ID ~= nil) and ((WOW_PROJECT_CAMELOT and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT)
  or (WOW_PROJECT_FOREVER and WOW_PROJECT_ID == WOW_PROJECT_FOREVER)) or false

-- Valores protegidos del motor moderno (en combate algunos datos llegan "secretos")
function NS.IsSecret(v) return issecretvalue and issecretvalue(v) or false end

-- Hechizos y objetos
if missing("GetSpellInfo") and C_Spell and C_Spell.GetSpellInfo then
  function GetSpellInfo(spell)
    local i = C_Spell.GetSpellInfo(spell)
    if i then return i.name, nil, i.iconID, i.castTime, i.minRange, i.maxRange, i.spellID end
  end
end
if missing("GetItemInfo") and C_Item and C_Item.GetItemInfo then GetItemInfo = C_Item.GetItemInfo end
if missing("GetItemIcon") and C_Item and C_Item.GetItemIconByID then GetItemIcon = C_Item.GetItemIconByID end
if missing("GetItemCount") and C_Item and C_Item.GetItemCount then GetItemCount = C_Item.GetItemCount end
if missing("GetItemStats") and C_Item and C_Item.GetItemStats then GetItemStats = C_Item.GetItemStats end
if missing("GetItemQualityColor") and C_Item and C_Item.GetItemQualityColor then GetItemQualityColor = C_Item.GetItemQualityColor end

-- Auras (beneficios). En Forever el UnitBuff viejo puede fallar y en combate las auras son secretas.
if (missing("UnitBuff") or NS.IsForever) and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
  function NS.UnitBuff(unit, index)
    if C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() then return nil end
    local a = C_UnitAuras.GetAuraDataByIndex(unit, index, "HELPFUL")
    if not a then return nil end
    if NS.IsSecret(a.name) then return nil end
    return a.name, a.icon, a.applications, a.dispelName, a.duration, a.expirationTime
  end
  UnitBuff = NS.UnitBuff
end
-- ¿Se pueden leer las auras ahora?
function NS.AurasReadable()
  if C_Secrets and C_Secrets.ShouldAurasBeSecret then return not C_Secrets.ShouldAurasBeSecret() end
  return true
end

-- Oficios: Forever los da con C_SkillInfo; otros clientes modernos con GetProfessions
if (missing("GetNumSkillLines") or NS.IsForever) and C_SkillInfo and C_SkillInfo.GetNumSkillLines then
  function GetNumSkillLines()
    if C_SkillInfo.ExpandSkillHeader then
      for i = C_SkillInfo.GetNumSkillLines(), 1, -1 do
        local s = C_SkillInfo.GetSkillLineInfo(i)
        if s and s.isHeader and s.isCollapsed then pcall(C_SkillInfo.ExpandSkillHeader, i) end
      end
    end
    return C_SkillInfo.GetNumSkillLines()
  end
  function GetSkillLineInfo(i)
    local s = C_SkillInfo.GetSkillLineInfo(i)
    if s then return s.name, s.isHeader, not s.isCollapsed, s.rank or 0, s.tempPoints, s.modifier, s.maxRank or 0 end
  end
elseif missing("GetNumSkillLines") and GetProfessions and GetProfessionInfo then
  local cache = {}
  local function build()
    wipe(cache)
    local list = { GetProfessions() }
    for i = 1, 6 do
      local idx = list[i]
      if idx then
        local name, _, rank, maxRank = GetProfessionInfo(idx)
        if name then table.insert(cache, { name, rank or 0, maxRank or 0 }) end
      end
    end
  end
  function GetNumSkillLines() build(); return #cache end
  function GetSkillLineInfo(i)
    local s = cache[i]
    if s then return s[1], false, nil, s[2], nil, nil, s[3] end
  end
end

-- Registro de misiones
if missing("GetNumQuestLogEntries") and C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
  GetNumQuestLogEntries = function() return (C_QuestLog.GetNumQuestLogEntries()) end
end
if missing("GetQuestLogTitle") and C_QuestLog and C_QuestLog.GetInfo then
  function GetQuestLogTitle(i)
    local q = C_QuestLog.GetInfo(i)
    if not q then return nil end
    local complete = q.questID and C_QuestLog.IsComplete and C_QuestLog.IsComplete(q.questID)
    return q.title, q.level, nil, q.isHeader, q.isCollapsed, complete and 1 or nil, q.frequency, q.questID
  end
end
if missing("GetQuestGreenRange") or NS.IsForever then
  local legacy = GetQuestGreenRange
  function GetQuestGreenRange()
    if C_QuestLog and C_QuestLog.GetTrivialRange then return C_QuestLog.GetTrivialRange() end
    if legacy then return legacy() end
    if UnitQuestTrivialLevelRange then return UnitQuestTrivialLevelRange("player") end
    return 8
  end
end

-- Talentos del motor moderno (C_ClassTalents / C_Traits). Forever no tiene UnitCharacterPoints
-- ni GetNumTalentTabs: los árboles viven en una configuración de "traits".
local function TraitsConfig()
  if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits and C_Traits.GetConfigInfo) then return nil end
  local configID = C_ClassTalents.GetActiveConfigID()
  if not configID then return nil end
  local info = C_Traits.GetConfigInfo(configID)
  if not (info and type(info.treeIDs) == "table" and info.treeIDs[1]) then return nil end
  return configID, info.treeIDs
end

-- Puntos sin gastar según las monedas del árbol (cada moneda se cuenta una sola vez)
local function TraitsFreePoints()
  local ok, v = pcall(function()
    if not (C_Traits and C_Traits.GetTreeCurrencyInfo) then return nil end
    local configID, trees = TraitsConfig()
    if not configID then return nil end
    local n, seen = 0, {}
    for _, treeID in ipairs(trees) do
      for _, c in ipairs(C_Traits.GetTreeCurrencyInfo(configID, treeID, false) or {}) do
        local id = c.traitCurrencyID or #seen + 1
        if type(c.quantity) == "number" and not seen[id] then seen[id] = true; n = n + c.quantity end
      end
    end
    if next(seen) == nil then return nil end
    return n
  end)
  if ok then return v end
end

local function SpellName(id)
  if not id then return nil end
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
  if GetSpellInfo then return (GetSpellInfo(id)) end
end

-- Rango de cada talento por nombre (en minúscula). nil si el cliente no lo informa.
function NS.TalentRanks()
  local map = {}
  if GetNumTalentTabs and GetNumTalents and GetTalentInfo then
    pcall(function()
      for tab = 1, GetNumTalentTabs() do
        for i = 1, GetNumTalents(tab) do
          local name, _, _, _, rank = GetTalentInfo(tab, i)
          if type(name) == "string" and type(rank) == "number" then map[name:lower()] = rank end
        end
      end
    end)
    if next(map) then return map end
  end
  pcall(function()
    if not (C_Traits and C_Traits.GetTreeNodes and C_Traits.GetNodeInfo and C_Traits.GetEntryInfo and C_Traits.GetDefinitionInfo) then return end
    local configID, trees = TraitsConfig()
    if not configID then return end
    for _, treeID in ipairs(trees) do
      for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID) or {}) do
        local node = C_Traits.GetNodeInfo(configID, nodeID)
        if node then
          local rank = node.activeRank or node.currentRank or 0
          local entryID = (node.activeEntry and node.activeEntry.entryID) or (node.entryIDs and node.entryIDs[1])
          local entry = entryID and C_Traits.GetEntryInfo(configID, entryID)
          local def = entry and entry.definitionID and C_Traits.GetDefinitionInfo(entry.definitionID)
          local name = def and (def.overrideName or SpellName(def.spellID))
          if type(name) == "string" and name ~= "" and type(rank) == "number" then
            local k = name:lower()
            map[k] = math.max(map[k] or 0, rank)
          end
        end
      end
    end
  end)
  if next(map) then return map end
  return nil
end

-- Talentos sin gastar. Prueba, en orden: UnitCharacterPoints (Classic), GetUnspentTalentPoints,
-- las monedas de C_Traits (motor moderno) y, por último, contar lo gastado en los árboles.
-- Si no hay forma de saberlo, devuelve nil.
function NS.FreeTalentPoints()
  if UnitCharacterPoints then
    local ok, v = pcall(UnitCharacterPoints, "player")
    if ok and type(v) == "number" then return v end
  end
  if GetUnspentTalentPoints then
    local ok, v = pcall(GetUnspentTalentPoints)
    if ok and type(v) == "number" then return v end
  end
  local traits = TraitsFreePoints()
  if traits then return traits end
  local level = UnitLevel("player") or 1
  local total = math.max(0, level - 9)
  if GetNumTalentTabs and GetNumTalents and GetTalentInfo then
    local ok, spent = pcall(function()
      local n = 0
      for tab = 1, GetNumTalentTabs() do
        for i = 1, GetNumTalents(tab) do
          local r = select(5, GetTalentInfo(tab, i))
          if type(r) == "number" then n = n + r end
        end
      end
      return n
    end)
    if ok and spent then return math.max(0, total - spent) end
  end
  return nil
end

-- Bolsas
if missing("UseContainerItem") and C_Container and C_Container.UseContainerItem then UseContainerItem = C_Container.UseContainerItem end

-- Tooltips de objetos: el motor moderno usa TooltipDataProcessor
function NS.HookItemTooltip(fn)
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt, data)
      if tt == GameTooltip or tt == ItemRefTooltip then
        NS.__tipData = data
        pcall(fn, tt)
        NS.__tipData = nil
      end
    end)
  else
    for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
      if tt and tt.HasScript and tt:HasScript("OnTooltipSetItem") then tt:HookScript("OnTooltipSetItem", fn) end
    end
  end
end

-- Registrar eventos sin romper si alguno no existe en este cliente
function NS.SafeEvents(frame, list)
  for _, e in ipairs(list) do pcall(frame.RegisterEvent, frame, e) end
end

-- Mapas: los números de zona cambian entre versiones; se buscan por nombre
local mapCache = {}
function NS.ResolveMap(id, names)
  if C_Map and C_Map.GetMapInfo then
    local info = C_Map.GetMapInfo(id)
    if info and names then
      for _, n in ipairs(names) do if info.name == n then return id end end
    elseif info and not names then
      return id
    end
  end
  if not names then return id end
  local key = names[1]
  if mapCache[key] then return mapCache[key] end
  if C_Map and C_Map.GetMapInfo then
    for m = 1, 3000 do
      local info = C_Map.GetMapInfo(m)
      if info and info.name and (not Enum or not Enum.UIMapType or info.mapType == Enum.UIMapType.Zone) then
        for _, n in ipairs(names) do
          if info.name == n then mapCache[key] = m; return m end
        end
      end
    end
  end
  return id
end

-- Enlace del objeto que muestra un tooltip (sirve en Classic y en el motor moderno)
function NS.TipLink(tt)
  local ok, _, link = pcall(tt.GetItem, tt)
  if ok and link and not NS.IsSecret(link) then return link end
  local d = NS.__tipData
  if d then
    if d.hyperlink and not NS.IsSecret(d.hyperlink) then return d.hyperlink end
    if d.id and not NS.IsSecret(d.id) then
      local _, l = GetItemInfo(d.id)
      return l or ("item:" .. d.id)
    end
  end
  return nil
end

-- Tooltips de criaturas y personajes
function NS.HookUnitTooltip(fn)
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tt)
      if tt == GameTooltip then pcall(fn, tt) end
    end)
  elseif GameTooltip and GameTooltip.HasScript and GameTooltip:HasScript("OnTooltipSetUnit") then
    GameTooltip:HookScript("OnTooltipSetUnit", function(tt) pcall(fn, tt) end)
  end
end
