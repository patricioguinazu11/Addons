-- Códice de Piolin: cartel al subir de nivel
-- Qué subió (vida, maná, estadísticas), si hay punto de talento y qué hay nuevo en el instructor.
local ADDON, NS = ...

local function DB() return NS.db end
local function Print(msg) print("|cffd9a93fCódice:|r " .. msg) end

----------------------------------------------------------------------
-- Hechizos del chamán en Forever, por nivel
-- Fuente: Conquest Capped, "WoW Forever Shaman Abilities and Spells by Level"
-- (actualizado el 07/11/2026). ranks = nivel de cada rango; quest = viene con la
-- misión del tótem; talent = el primer rango sale de un talento (solo se muestra si lo tenés).
-- es = nombre en español cuando ya está en el addon; si no, se usa el que da el juego
-- y, si el juego no lo conoce, el nombre en inglés (para no inventar traducciones).
-- rec = consejo para Mejora, el mismo criterio del panel del instructor:
--   "buy" comprá · "even" comprá los rangos pares · "first" solo el rango 1 · "until30" hasta el 30
--   "skip" salteá · "tank" solo para tanquear · nil sin consejo
----------------------------------------------------------------------
local I = "Interface\\Icons\\"
NS.SHAMAN_SPELLS = {
  { id = 403,   en = "Lightning Bolt", es = "Descarga de relámpagos", icon = "spell_nature_lightning", ranks = { 1, 8, 14, 20, 26, 32, 38, 44, 50, 56 }, rec = "even" },
  { id = 8017,  en = "Rockbiter Weapon", es = "Arma Muerdepiedras", icon = "spell_nature_rockbiter", ranks = { 1, 8, 16, 24, 34, 44, 54 }, rec = "tank" },
  { id = 331,   en = "Healing Wave", es = "Ola de sanación", icon = "spell_nature_magicimmunity", ranks = { 1, 6, 12, 18, 24, 32, 40, 48, 56, 60 }, rec = "even" },
  { id = 8042,  en = "Earth Shock", es = "Choque de tierra", icon = "spell_nature_earthshock", ranks = { 4, 8, 14, 24, 36, 48, 60 }, rec = "buy" },
  { id = 8071,  en = "Stoneskin Totem", es = "Tótem Piel de piedra", icon = "spell_nature_stoneskintotem", ranks = { 4, 14, 24, 34, 44, 54 }, quest = true },
  { id = 2484,  en = "Earthbind Totem", es = "Tótem Nexo terrestre", icon = "spell_nature_strengthofearthtotem02", ranks = { 6 }, rec = "first" },
  { id = 5730,  en = "Stoneclaw Totem", es = "Tótem Garra de piedra", icon = "spell_nature_stoneclawtotem", ranks = { 8, 18, 28, 38, 48, 58 }, rec = "first" },
  { id = 324,   en = "Lightning Shield", es = "Escudo de relámpagos", icon = "spell_nature_lightningshield", ranks = { 8, 16, 24, 32, 40, 48, 56 }, rec = "buy" },
  { id = 8050,  en = "Flame Shock", es = "Choque de llamas", icon = "spell_fire_flameshock", ranks = { 10, 18, 28, 40, 52, 60 }, rec = "buy" },
  { id = 3599,  en = "Searing Totem", es = "Tótem abrasador", icon = "spell_fire_searingtotem", ranks = { 10, 20, 30, 40, 50, 60 }, quest = true, rec = "buy" },
  { id = 8024,  en = "Flametongue Weapon", es = "Arma Lengua de fuego", icon = "spell_fire_flametounge", ranks = { 10, 18, 26, 36, 46, 56 }, rec = "until30" },
  { id = 8075,  en = "Strength of Earth Totem", es = "Tótem Fuerza de la tierra", icon = "spell_nature_earthbindtotem", ranks = { 10, 24, 38, 52, 60 }, rec = "buy" },
  { id = 1535,  en = "Fire Nova", es = "Nova de fuego", icon = "spell_fire_sealoffire", ranks = { 12, 22, 32, 42, 52 }, rec = "buy" },
  { id = 370,   en = "Purge", icon = "spell_nature_purge", ranks = { 12, 32 }, rec = "buy" },
  { id = 2008,  en = "Ancestral Spirit", icon = "spell_nature_regenerate", ranks = { 12, 24, 36, 48, 60 } },
  { id = 526,   en = "Cure Poison", icon = "spell_nature_nullifypoison", ranks = { 16 } },
  { id = 8143,  en = "Tremor Totem", es = "Tótem Temblor", icon = "spell_nature_tremortotem", ranks = { 18 }, rec = "first" },
  { id = 66842, en = "Call of the Elements", es = "Llamada de los elementos", icon = "spell_shaman_dropall_01", ranks = { 20 }, rec = "buy" },
  { id = 8056,  en = "Frost Shock", es = "Choque de escarcha", icon = "spell_frost_frostshock", ranks = { 20, 34, 46, 58 }, rec = "first" },
  { id = 36936, en = "Totemic Recall", es = "Retirada totémica", icon = "spell_shaman_totemrecall", ranks = { 20 }, rec = "buy" },
  { id = 8033,  en = "Frostbrand Weapon", icon = "spell_frost_frostbrand", ranks = { 20, 28, 38, 48, 58 }, rec = "skip" },
  { id = 2645,  en = "Ghost Wolf", es = "Lobo fantasmal", icon = "spell_nature_spiritwolf", ranks = { 20 }, rec = "buy" },
  { id = 5394,  en = "Healing Stream Totem", es = "Tótem Corriente de sanación", icon = "inv_spear_04", ranks = { 20, 30, 40, 50, 60 }, quest = true },
  { id = 8004,  en = "Lesser Healing Wave", es = "Ola de sanación inferior", icon = "spell_nature_healingwavelesser", ranks = { 20, 28, 36, 44, 52, 60 }, rec = "buy" },
  { en = "Totemic Call", ranks = { 22 } },
  { id = 131,   en = "Water Breathing", icon = "spell_shadow_demonbreath", ranks = { 22 }, rec = "skip" },
  { id = 2870,  en = "Cure Disease", icon = "spell_nature_removedisease", ranks = { 22 } },
  { id = 8166,  en = "Poison Cleansing Totem", icon = "spell_nature_poisoncleansingtotem", ranks = { 22 } },
  { id = 8181,  en = "Frost Resistance Totem", icon = "spell_frostresistancetotem_01", ranks = { 24, 38, 54 }, rec = "skip" },
  { id = 16190, en = "Mana Tide Totem", icon = "spell_frost_summonwaterelemental", ranks = { 25, 38, 48, 58 }, talent = true },
  { id = 8190,  en = "Magma Totem", icon = "spell_fire_selfdestruct", ranks = { 26, 36, 46, 56 } },
  { id = 6196,  en = "Far Sight", icon = "spell_nature_farsight", ranks = { 26 } },
  { id = 5675,  en = "Mana Spring Totem", icon = "spell_nature_manaregentotem", ranks = { 26, 36, 46, 56 } },
  { id = 8184,  en = "Fire Resistance Totem", icon = "spell_fireresistancetotem_01", ranks = { 28, 42, 58 }, rec = "skip" },
  { id = 8227,  en = "Flametongue Totem", icon = "spell_nature_guardianward", ranks = { 28, 38, 48, 58 } },
  { id = 546,   en = "Water Walking", icon = "spell_frost_windwalkon", ranks = { 28 }, rec = "skip" },
  { id = 66843, en = "Call of the Ancestors", icon = "spell_shaman_dropall_02", ranks = { 30 } },
  { id = 556,   en = "Astral Recall", es = "Regreso astral", icon = "spell_nature_astralrecal", ranks = { 30 }, rec = "buy" },
  { id = 8177,  en = "Grounding Totem", es = "Tótem derribador", icon = "spell_nature_groundingtotem", ranks = { 30 } },
  { id = 10595, en = "Nature Resistance Totem", icon = "spell_nature_natureresistancetotem", ranks = { 30, 44, 60 }, rec = "skip" },
  { id = 8232,  en = "Windfury Weapon", es = "Arma Viento furioso", icon = "spell_nature_cyclone", ranks = { 30, 40, 50, 60 }, rec = "buy" },
  { id = 20608, en = "Reincarnation", icon = "spell_nature_reincarnation", ranks = { 30 } },
  { id = 421,   en = "Chain Lightning", es = "Cadena de relámpagos", icon = "spell_nature_chainlightning", ranks = { 32, 40, 48, 56 }, rec = "buy" },
  { id = 8512,  en = "Windfury Totem", es = "Tótem Viento furioso", icon = "spell_nature_windfury", ranks = { 32, 42, 52 }, rec = "buy" },
  { id = 6495,  en = "Sentry Totem", icon = "spell_nature_removecurse", ranks = { 34 } },
  { id = 15107, en = "Windwall Totem", icon = "spell_nature_earthbind", ranks = { 36, 46, 56 } },
  { id = 8170,  en = "Disease Cleansing Totem", icon = "spell_nature_diseasecleansingtotem", ranks = { 38 } },
  { id = 66844, en = "Call of the Spirits", icon = "spell_shaman_dropall_03", ranks = { 40 } },
  { id = 1064,  en = "Chain Heal", icon = "spell_nature_healingwavegreater", ranks = { 40, 46, 54 } },
  { id = 61295, en = "Riptide", icon = "spell_nature_riptide", ranks = { 40, 50, 60 }, talent = true },
  { id = 8835,  en = "Grace of Air Totem", icon = "spell_nature_invisibilitytotem", ranks = { 42, 56, 60 } },
}

local function Knows(id)
  if not id then return false end
  for _, fn in ipairs({ IsPlayerSpell, IsSpellKnown }) do
    if type(fn) == "function" then
      local ok, v = pcall(fn, id)
      if ok and v then return true end
    end
  end
  return false
end

local function SpellName(s)
  if s.es then return s.es end
  local name = s.id and GetSpellInfo and GetSpellInfo(s.id)
  return (type(name) == "string" and name ~= "") and name or s.en
end

local function SpellIcon(s)
  if s.icon then return I .. s.icon end
  local tex = s.id and GetSpellTexture and GetSpellTexture(s.id)
  return tex or (I .. "INV_Misc_QuestionMark")
end

-- Consejo para este rango: "buy", "opt" (opcional) o "skip"
local function Advice(s, rank, level)
  local r = s.rec
  if r == "buy" then return "buy" end
  if r == "even" then return rank % 2 == 0 and "buy" or "opt" end
  if r == "first" then return rank == 1 and "buy" or "skip" end
  if r == "until30" then return level < 30 and "buy" or "skip" end
  if r == "skip" or r == "tank" then return "skip" end
  return nil
end

-- Lo que enseña el instructor justo en ese nivel
function NS.SpellsAtLevel(level)
  local out = {}
  for _, s in ipairs(NS.SHAMAN_SPELLS) do
    for rank, lv in ipairs(s.ranks) do
      if lv == level and (not s.talent or Knows(s.id)) then
        table.insert(out, { spell = s, rank = rank, new = rank == 1, advice = Advice(s, rank, level),
          name = SpellName(s), icon = SpellIcon(s) })
      end
    end
  end
  -- primero lo que conviene comprar, después lo opcional y al final lo que se saltea
  local order = { buy = 1, opt = 2 }
  table.sort(out, function(a, b)
    local oa, ob = order[a.advice] or (a.advice == "skip" and 4 or 3), order[b.advice] or (b.advice == "skip" and 4 or 3)
    if oa ~= ob then return oa < ob end
    if a.new ~= b.new then return a.new end
    return a.name < b.name
  end)
  return out
end

-- Próximo nivel (desde 'level' inclusive) en el que el instructor tiene algo
function NS.NextTrainerLevel(level)
  for lv = level, 60 do
    if #NS.SpellsAtLevel(lv) > 0 then return lv end
  end
end

----------------------------------------------------------------------
-- Estadísticas: lo que dice el evento o, si no viene, la diferencia con la foto anterior
----------------------------------------------------------------------
local STATS = { "Fuerza", "Agilidad", "Aguante", "Intelecto", "Espíritu" }
local snap

local function Snapshot()
  local s = { hp = UnitHealthMax and UnitHealthMax("player") or 0, mp = UnitPowerMax and UnitPowerMax("player", 0) or 0 }
  for i = 1, 5 do
    local ok, base = pcall(UnitStat, "player", i)
    s[i] = ok and tonumber(base) or 0
  end
  return s
end

local function Gains(args)
  local now = Snapshot()
  local g = {}
  local function pick(v, key)
    if type(v) == "number" then return v end
    if snap and type(now[key]) == "number" and type(snap[key]) == "number" then return now[key] - snap[key] end
    return 0
  end
  g.hp = pick(args[2], "hp")
  g.mp = pick(args[3], "mp")
  g.talents = type(args[4]) == "number" and args[4] or nil
  for i = 1, 5 do g[i] = pick(args[5 + i], i) end
  snap = now
  return g
end

----------------------------------------------------------------------
-- Cartel
----------------------------------------------------------------------
local card
local ADV = {
  buy = { "COMPRÁ", { 0.5, 0.86, 0.4 } },
  opt = { "OPCIONAL", { 1, 0.82, 0.25 } },
  skip = { "SALTEÁ", { 1, 0.42, 0.4 } },
}
local CW = 360

local function Build()
  local S = NS.Style
  local K = S.K
  card = S.Panel(UIParent, K.bg, 0.97, K.edge, 1)
  card:SetFrameStrata("HIGH")
  card:SetWidth(CW)
  card:SetPoint("TOP", UIParent, "TOP", 0, -160)
  card:SetClampedToScreen(true)
  card:EnableMouse(true)
  card:SetMovable(true)
  card:RegisterForDrag("LeftButton")
  card:SetScript("OnDragStart", NS.DragStart)
  card:SetScript("OnDragStop", card.StopMovingOrSizing)
  card:Hide()
  rawset(card, "name", "PiolinCodexLevelCard")
  _G.PiolinCodexLevelCard = card

  local top = card:CreateTexture(nil, "BORDER")
  top:SetPoint("TOPLEFT", 1, -1); top:SetPoint("TOPRIGHT", -1, -1); top:SetHeight(2)
  S.Grad(top, "HORIZONTAL", K.gold, 1, K.accent, 0.6)

  card.badge = S.Framed(card, I .. "Ability_Shaman_Stormstrike", 34)
  card.badge:SetPoint("TOPLEFT", 14, -14)
  card.title = S.Text(card, 17, K.gold, S.TITLE_FONT)
  card.title:SetPoint("TOPLEFT", card.badge, "TOPRIGHT", 10, 1)
  card.sub = S.Text(card, 10.5, K.mute)
  card.sub:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -3)

  local close = CreateFrame("Button", nil, card)
  close:SetSize(20, 20)
  close:SetPoint("TOPRIGHT", -6, -6)
  local x = S.Text(close, 14, K.mute); x:SetPoint("CENTER", 0, 1); x:SetText("×")
  local hl = close:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.07)
  close:SetScript("OnClick", function() card:Hide() end)

  card.fs, card.icons, card.rows = {}, {}, {}
  card:SetScript("OnUpdate", function(self, el)
    if self:IsMouseOver() then return end
    self.left = (self.left or 0) - el
    if self.left <= 0 then
      self.left = nil
      if NS.Vanish and not DB().noAnim then NS.Vanish(self, 0, 12, 0.45) else self:Hide() end
    end
  end)
end

-- Reutiliza textos, íconos y filas entre carteles
local function Reset()
  for _, t in ipairs(card.fs) do t:Hide() end
  for _, t in ipairs(card.icons) do t:Hide() end
  for _, r in ipairs(card.rows) do r:Hide() end
  card.nfs, card.nic, card.nrow = 0, 0, 0
end
local function FS(size, color, bold)
  local S = NS.Style
  card.nfs = card.nfs + 1
  local t = card.fs[card.nfs]
  if not t then t = S.Text(card, size, color); card.fs[card.nfs] = t end
  S.Font(t, size, color, bold)
  t:ClearAllPoints(); t:SetWidth(0); t:SetText(""); t:Show()
  return t
end
local function Row()
  card.nrow = card.nrow + 1
  local r = card.rows[card.nrow]
  if not r then
    local S = NS.Style
    r = CreateFrame("Frame", nil, card)
    r:SetSize(CW - 28, 22)
    r.icon = S.Framed(r, I .. "INV_Misc_QuestionMark", 18)
    r.icon:SetPoint("LEFT", 0, 0)
    r.name = S.Text(r, 11.5, S.K.parch)
    r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
    r.tag = S.Text(r, 8.5, S.K.ok, S.TITLE_FONT)
    r.tag:SetPoint("RIGHT", -2, 0)
    r:EnableMouse(true)
    r:SetScript("OnEnter", function(self)
      local s = rawget(self, "spell")
      if not s then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      local ok = s.id and GameTooltip.SetSpellByID and pcall(GameTooltip.SetSpellByID, GameTooltip, s.id)
      if not ok then GameTooltip:AddLine(SpellName(s), 1, 0.82, 0) end
      if s.quest then GameTooltip:AddLine("Necesita el tótem de la misión de clase.", 0.53, 0.57, 0.64, true) end
      GameTooltip:Show()
    end)
    r:SetScript("OnLeave", GameTooltip_Hide)
    card.rows[card.nrow] = r
  end
  r:ClearAllPoints(); r:Show()
  return r
end

local function Signed(v) return (v > 0 and "+" or "") .. v end

-- level: nivel nuevo · g: ganancias (o nil en la vista previa) · preview: armado a mano con /piolin nivel
function NS.ShowLevelCard(level, g, preview)
  if not NS.db or not NS.Style then return end
  if not card then Build() end
  local S, K = NS.Style, NS.Style.K
  Reset()
  level = tonumber(level) or UnitLevel("player") or 1
  card.title:SetText("¡Nivel " .. level .. "!")
  card.sub:SetText(preview and "Vista previa (/piolin nivel)" or "Esto es lo que trae el nivel nuevo")
  local y = -60
  local function Head(text)
    local t = FS(9, K.mute, true)
    t:SetPoint("TOPLEFT", 14, y)
    t:SetText(text)
    y = y - 16
  end

  -- 1. Lo que subió
  local parts = {}
  if g then
    if g.hp and g.hp ~= 0 then table.insert(parts, "|cff80db66Vida " .. Signed(g.hp) .. "|r") end
    if g.mp and g.mp ~= 0 then table.insert(parts, "|cff4da8ffManá " .. Signed(g.mp) .. "|r") end
    for i, n in ipairs(STATS) do
      if g[i] and g[i] ~= 0 then table.insert(parts, n .. " " .. Signed(g[i])) end
    end
  end
  Head("LO QUE SUBIÓ")
  local t = FS(11.5, K.parch)
  t:SetPoint("TOPLEFT", 14, y); t:SetWidth(CW - 28); t:SetJustifyH("LEFT")
  t:SetText(#parts > 0 and table.concat(parts, "   ") or "|cff8892a3Las estadísticas se ven en la ventana del personaje (C).|r")
  y = y - t:GetStringHeight() - 8
  local talents = g and g.talents
  if talents == nil and level >= 10 then talents = 1 end
  if talents and talents > 0 then
    local free = NS.FreeTalentPoints and NS.FreeTalentPoints() or 0
    local tl = FS(11.5, { 0.75, 0.55, 1 })
    tl:SetPoint("TOPLEFT", 14, y); tl:SetWidth(CW - 28); tl:SetJustifyH("LEFT")
    tl:SetText("+" .. talents .. " punto de talento" .. ((free and free > 1) and ("  ·  tenés " .. free .. " sin gastar") or "") .. "  (N)")
    y = y - tl:GetStringHeight() - 8
  end

  -- 2. El instructor
  if select(2, UnitClass("player")) == "SHAMAN" then
    y = y - 4
    local list = NS.SpellsAtLevel(level)
    if #list > 0 then
      Head("NUEVO EN EL INSTRUCTOR")
      local shown = 0
      for _, e in ipairs(list) do
        shown = shown + 1
        if shown > 9 then break end
        local r = Row()
        rawset(r, "spell", e.spell)
        r:SetPoint("TOPLEFT", 14, y)
        r.icon:SetTexture(e.icon)
        local extra = e.new and (e.spell.quest and "  |cff8892a3(misión)|r" or "  |cff8892a3nuevo|r") or ("  |cff8892a3rango " .. e.rank .. "|r")
        r.name:SetText(e.name .. extra)
        local a = ADV[e.advice]
        r.tag:SetText(a and a[1] or "")
        if a then r.tag:SetTextColor(a[2][1], a[2][2], a[2][3]) end
        r.icon:SetDesaturated(e.advice == "skip")
        r.name:SetAlpha(e.advice == "skip" and 0.6 or 1)
        y = y - 23
      end
      if #list > 9 then
        local more = FS(10.5, K.mute)
        more:SetPoint("TOPLEFT", 14, y)
        more:SetText("y " .. (#list - 9) .. " más en el instructor")
        y = y - 16
      end
    else
      Head("INSTRUCTOR")
      local nxt = NS.NextTrainerLevel(level + 1)
      local nt = FS(11.5, K.parch)
      nt:SetPoint("TOPLEFT", 14, y); nt:SetWidth(CW - 28); nt:SetJustifyH("LEFT")
      if nxt then
        local n = #NS.SpellsAtLevel(nxt)
        nt:SetText("Este nivel no trae nada. En el nivel " .. nxt .. " tenés " .. n .. (n == 1 and " hechizo" or " hechizos") .. " para entrenar.")
      else
        nt:SetText("Ya no quedan hechizos nuevos para entrenar.")
      end
      y = y - nt:GetStringHeight() - 6
    end
  end

  -- 3. El consejo de la guía para este nivel
  local tip = NS.LEVEL_TIPS and NS.LEVEL_TIPS[level]
  if tip then
    y = y - 6
    Head("PARA ESTE NIVEL")
    local tt = FS(11.5, K.gold)
    tt:SetPoint("TOPLEFT", 14, y); tt:SetWidth(CW - 28); tt:SetJustifyH("LEFT")
    tt:SetText(tip)
    y = y - tt:GetStringHeight() - 6
  end

  card:SetHeight(-y + 12)
  card.left = 25
  card:SetAlpha(1)
  card:Show()
  if NS.Appear then NS.Appear(card, 0, 16, 0.3) end
  if NS.Pop then NS.Pop(card.badge, 34, 0.4) end
end

----------------------------------------------------------------------
-- Eventos y comando
----------------------------------------------------------------------
local ev = CreateFrame("Frame")
NS.SafeEvents(ev, { "PLAYER_LOGIN", "PLAYER_LEVEL_UP" })
ev:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_LOGIN" then
    C_Timer.After(3, function() snap = Snapshot() end)
  elseif event == "PLAYER_LEVEL_UP" then
    local args = { ... }
    -- después del rayo y del "¡Nivel N!", cuando el juego ya actualizó las estadísticas
    C_Timer.After(1.6, function()
      local g = Gains(args)
      if not DB().noLevelCard then NS.ShowLevelCard(args[1], g) end
    end)
  end
end)

-- /piolin nivel [N]
function NS.LevelSlash(msg)
  local arg = msg:match("^nivel%s*(%d*)$")
  if not arg then return false end
  local lvl = tonumber(arg) or UnitLevel("player") or 1
  if lvl < 1 or lvl > 60 then Print("el nivel tiene que ser entre 1 y 60."); return true end
  NS.ShowLevelCard(lvl, nil, true)
  return true
end
