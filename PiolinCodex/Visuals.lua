-- Códice de Piolin: bloques visuales para Combate, Campamento, Pesca y Oficios
local ADDON, NS = ...

local function DB() return PiolinCodexDB end
local I = "Interface\\Icons\\"

-- Suma un bloque a una pestaña sin pisar los que ya tenga
function NS.AddPageExtra(key, fn)
  NS.PageExtras = NS.PageExtras or {}
  local cur = NS.PageExtras[key]
  if cur == nil then NS.PageExtras[key] = { fn }
  elseif type(cur) == "function" then NS.PageExtras[key] = { cur, fn }
  else table.insert(cur, fn) end
end

local function Way(zkey, x, y, title)
  local z = NS.TRAINER_ZONES and NS.TRAINER_ZONES[zkey]
  local map = z and NS.ResolveMap(z[1], z[2]) or 0
  NS.SetWaypoint(map, x, y, title)
end

local function GoButton(parent, H, x, y, wp)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(20, 20)
  b:SetPoint("TOPRIGHT", parent, "TOPRIGHT", x, y)
  local ic = H.Icon(b, I .. "INV_Misc_Map_01", 20)
  ic:SetAllPoints()
  b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  b:SetScript("OnClick", function() Way(wp[1], wp[2], wp[3], wp[4]) end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(wp[4], 0.85, 0.66, 0.25)
    GameTooltip:AddLine("Clic: flecha y marca en el mapa", 1, 1, 1)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  return b
end

-- Fila con ícono, título, detalle y etiqueta a la derecha
local function IconRow(C, H, icon, title, detail, pill, pillColor)
  local K, CW = H.K, H.CW
  local ic = H.Framed(C.frame, icon, 24)
  ic:SetPoint("TOPLEFT", 16, C.y - 2)
  local t = H.Text(C.frame, 12, K.gold)
  t:SetPoint("TOPLEFT", 52, C.y)
  t:SetText(title)
  local d = H.Text(C.frame, 11, K.parch)
  d:SetPoint("TOPLEFT", 52, C.y - 15)
  d:SetWidth(CW - 52 - (pill and 96 or 24))
  d:SetText(detail or "")
  local p
  if pill then
    p = H.Pill(C.frame, pill, pillColor or K.water)
    p:SetPoint("TOPRIGHT", -14, C.y - 4)
  end
  local h = math.max(34, 18 + d:GetStringHeight() + 4)
  C.y = C.y - h
  return { icon = ic, title = t, detail = d, pill = p }
end

----------------------------------------------------------------------
-- COMBATE
----------------------------------------------------------------------
NS.AddPageExtra("combate", function(P, H)
  local K, CW = H.K, H.CW

  -- Prioridad de estadísticas como barras
  local S = P:Card("Qué estadísticas buscar", I .. "Spell_Nature_Strength", K.fire)
  local stats = {
    { "Spell_Nature_Strength", "Fuerza", 1.0, "1 de fuerza = 2 de poder de ataque" },
    { "Spell_Holy_MagicalSentry", "Intelecto", 0.6, "más maná para choques y curas" },
    { "Ability_Warrior_BattleShout", "Poder de ataque", 0.5, "directo al daño" },
    { "Ability_Rogue_Sprint", "Agilidad", 0.4, "crítico y armadura" },
    { "Spell_Holy_WordFortitude", "Aguante", 0.35, "vida para pelear solo" },
  }
  for _, st in ipairs(stats) do
    local ic = H.Framed(S.frame, I .. st[1], 20)
    ic:SetPoint("TOPLEFT", 16, S.y)
    local n = H.Text(S.frame, 11.5, K.parch)
    n:SetPoint("TOPLEFT", 46, S.y - 3)
    n:SetText(st[2])
    local bar = H.Bar(S.frame, 170, 12, K.fire)
    bar:SetPoint("TOPLEFT", 160, S.y - 3)
    bar:SetValue(st[3])
    bar.text:SetText("")
    local note = H.Text(S.frame, 10, K.mute)
    note:SetPoint("LEFT", bar, "RIGHT", 10, 0)
    note:SetWidth(CW - 360)
    note:SetText(st[4])
    S.y = S.y - 26
  end
  S:Text("Sufijos que te sirven: |cffffd96a“del oso”, “del tigre”, “del gorila”|r.", 11, K.parch)
  S:Finish()

  -- Imbuición según el nivel
  local M = P:Card("Imbuición del arma según tu nivel", I .. "Spell_Fire_FlameTounge", K.fire)
  local imb = {
    { 1, 9, "Spell_Nature_RockBiter", "Muerdepiedras" },
    { 10, 29, "Spell_Fire_FlameTounge", "Lengua de fuego" },
    { 30, 60, "Spell_Nature_Cyclone", "Viento furioso" },
  }
  local level = UnitLevel("player") or 1
  local w = math.floor((CW - 40) / 3)
  for i, e in ipairs(imb) do
    local cur = level >= e[1] and level <= e[2]
    local box = H.Panel(M.frame, cur and { 0.25, 0.12, 0.03 } or { 0.04, 0.06, 0.1 }, 0.95, cur and K.fire or { 0.3, 0.36, 0.48 }, cur and 1 or 0.6)
    box:SetPoint("TOPLEFT", 14 + (i - 1) * (w + 6), M.y)
    box:SetSize(w, 48)
    local ic = H.Framed(box, I .. e[3], 26)
    ic:SetPoint("LEFT", 10, 0)
    local n = H.Text(box, 12, cur and K.gold or K.parch)
    n:SetPoint("TOPLEFT", 44, -9)
    n:SetText(e[4])
    local r = H.Text(box, 10, K.mute)
    r:SetPoint("TOPLEFT", 44, -26)
    r:SetText("niveles " .. e[1] .. "-" .. e[2] .. (cur and "  ·  |cff7fd16aahora|r" or ""))
  end
  M.y = M.y - 56
  M:Finish()

  -- Tótems: cuándo usar cada uno
  local T = P:Card("Tótems: cuándo usar cada uno", I .. "Spell_Fire_SearingTotem", K.earth)
  local tot = {
    { "Spell_Fire_SearingTotem", "Abrasador", "Peleando solo, siempre: es el que más rinde." },
    { "Spell_Fire_SealOfFire", "Nova de fuego", "Con 3 o más enemigos encima." },
    { "Spell_Nature_StoneSkinTotem", "Piel de piedra", "Cuando te pegan fuerte o tanqueás." },
    { "Spell_Nature_EarthBindTotem", "Fuerza de la tierra", "En grupo con otros de cuerpo a cuerpo." },
    { "INV_Spear_04", "Corriente de sanación", "En mazmorras, entre peleas largas." },
    { "Spell_Nature_TremorTotem", "Temblor", "Contra enemigos que dan miedo o duermen." },
  }
  local colW = math.floor((CW - 40) / 2)
  local startY = T.y
  for i, e in ipairs(tot) do
    local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
    local x, y = 14 + col * (colW + 10), startY - row * 46
    local ic = H.Framed(T.frame, I .. e[1], 26)
    ic:SetPoint("TOPLEFT", x + 2, y - 2)
    local n = H.Text(T.frame, 12, K.gold)
    n:SetPoint("TOPLEFT", x + 38, y)
    n:SetText(e[2])
    local d = H.Text(T.frame, 10, K.parch)
    d:SetPoint("TOPLEFT", x + 38, y - 15)
    d:SetWidth(colW - 44)
    d:SetText(e[3])
  end
  T.y = startY - math.ceil(#tot / 2) * 46
  T:Finish()

  -- Raciales de enano
  local R = P:Card("Tus raciales de enano", I .. "Spell_Shadow_UnholyStrength", K.earth)
  local rac = {
    { "Spell_Shadow_UnholyStrength", "Petraforma", "Quita venenos, enfermedades y sangrados; +10% armadura." },
    { "Racial_Dwarf_FindTreasure", "Buscar tesoro", "Muestra cofres y tesoros en el minimapa." },
    { "INV_Musket_03", "Especialización en armas de fuego", "+1% crítico con armas de fuego." },
    { "Spell_Frost_WizardMark", "Resistencia a la escarcha", "+10 de resistencia a la escarcha." },
  }
  for _, e in ipairs(rac) do IconRow(R, H, I .. e[1], e[2], e[3]) end
  R:Finish()
end)

----------------------------------------------------------------------
-- CAMPAMENTO
----------------------------------------------------------------------
NS.AddPageExtra("campamento", function(P, H)
  local K, CW = H.K, H.CW
  local D = P:Card("Descanso en el campamento", I .. "Spell_Fire_Fire", K.fire)
  local items = {
    { "Spell_Fire_Fire", "Hoguera básica", "Para cocinar y sumar descanso. Se aprende con Cocina." },
    { "INV_Misc_Bag_09", "Tienda de campaña", "Experiencia de descanso; se puede poner una vez por hora. Se hace con 5 cueros ligeros." },
    { "INV_Misc_Fish_02", "Pecera", "+8% a las estadísticas, con otros jugadores cerca." },
    { "Spell_Nature_Sleep", "Silla de campamento", "+2% de crítico, con otros jugadores cerca." },
  }
  local colW = math.floor((CW - 40) / 2)
  local startY = D.y
  for i, e in ipairs(items) do
    local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
    local x, y = 14 + col * (colW + 10), startY - row * 58
    local box = H.Panel(D.frame, { 0.04, 0.06, 0.1 }, 0.95, { 0.3, 0.36, 0.48 }, 0.6)
    box:SetPoint("TOPLEFT", x, y)
    box:SetSize(colW, 52)
    local ic = H.Framed(box, I .. e[1], 28)
    ic:SetPoint("LEFT", 10, 0)
    local n = H.Text(box, 12, K.gold)
    n:SetPoint("TOPLEFT", 48, -8)
    n:SetText(e[2])
    local d = H.Text(box, 10, K.parch)
    d:SetPoint("TOPLEFT", 48, -23)
    d:SetWidth(colW - 56)
    d:SetText(e[3])
  end
  D.y = startY - 2 * 58
  D:Finish()

  -- Camino a la montura
  local M = P:Card("Camino a la montura", I .. "Ability_Mount_MountainRam", K.gold)
  local goals = { { 40, 100 * 10000, "Equitación y el oso del pack" }, { 60, 1000 * 10000, "Equitación de oficial y tu Garrazul cerúleo" } }
  local bars = {}
  for i, g in ipairs(goals) do
    local pill = H.Pill(M.frame, "Nivel " .. g[1], K.water)
    pill:SetPoint("TOPLEFT", 16, M.y)
    local t = H.Text(M.frame, 11.5, K.parch)
    t:SetPoint("TOPLEFT", 90, M.y - 1)
    t:SetText(g[3] .. " · " .. NS.Money(g[2]))
    local b = H.Bar(M.frame, CW - 32, 14, K.gold)
    b:SetPoint("TOPLEFT", 16, M.y - 22)
    bars[i] = { bar = b, goal = g }
    M.y = M.y - 46
  end
  local session = M:Text(" ", 11, K.mute)
  M:Finish()
  table.insert(P.refreshers, function()
    local money, level = GetMoney(), UnitLevel("player") or 1
    local d = NS.sessionMoney and (money - NS.sessionMoney)
    session:SetText("Tenés " .. NS.Money(money) .. (d and ("  ·  en esta sesión: " .. (d >= 0 and "|cff7fd16a+|r" or "|cffff6060-|r") .. NS.Money(math.abs(d))) or ""))
    for _, e in ipairs(bars) do
      local pct = math.min(1, money / e.goal[2])
      e.bar:SetValue(pct)
      e.bar.text:SetText(math.floor(pct * 100) .. "% del oro · " .. (level >= e.goal[1] and "ya tenés el nivel" or ("te faltan " .. (e.goal[1] - level) .. " niveles")))
    end
  end)

  -- Ideas para juntar oro, con precios guardados
  local O = P:Card("Ideas para juntar oro", I .. "INV_Misc_Coin_02", K.gold)
  local rows = {
    cure = IconRow(O, H, I .. "INV_Misc_LeatherScrap_02", "Curar pellejos antes de vender", ""),
    fish = IconRow(O, H, I .. "Trade_Fishing", "Pescados que se venden bien", ""),
    cloth = IconRow(O, H, I .. "INV_Fabric_Wool_01", "Paño de lana y de seda", ""),
    camp = IconRow(O, H, I .. "INV_Misc_Bag_09", "Tiendas y sillas de campamento", "Se venden bien en la subasta."),
  }
  O:Text("Los precios son de tu último escaneo en la subasta, o de wowauctions si todavía no escaneaste.", 10, K.dim)
  O:Finish()
  local function P_(id) return NS.Price and NS.Price(id) end
  table.insert(P.refreshers, function()
    local hide, salt, cured = P_(4232), P_(4289), P_(4233)
    if hide and salt and cured then
      local gain = cured - hide - salt
      rows.cure.detail:SetText("Pellejo medio " .. NS.Money(hide) .. " + sal " .. NS.Money(salt) .. " → curado " .. NS.Money(cured) .. (gain > 0 and ("  ·  |cff7fd16aganás " .. NS.Money(gain) .. " c/u|r") or "  ·  |cffff9a40hoy no conviene|r"))
    end
    local dev, oily = P_(6522), P_(6358)
    rows.fish.detail:SetText("Pez desviado " .. (dev and NS.Money(dev) or "?") .. " · Boca negra aceitosa " .. (oily and NS.Money(oily) or "?") .. ". El resto vale más cocinado.")
    local wool, silk = P_(2592), P_(4306)
    rows.cloth.detail:SetText("Lana " .. (wool and NS.Money(wool) or "?") .. " · Seda " .. (silk and NS.Money(silk) or "?") .. " por unidad. No los vendas al vendedor.")
  end)
end)

----------------------------------------------------------------------
-- PESCA
----------------------------------------------------------------------
NS.AddPageExtra("pesca", function(P, H)
  local K, CW = H.K, H.CW
  local W = P:Card("Dónde pescar según tu nivel", I .. "INV_Misc_Map_01", K.water)
  local spots = {
    { 1, 75, "El Lago, Loch Modan", "Pargo de barro, Frenesí del lago", { "lochmodan", 40.5, 39.4, "El Lago (Loch Modan)" } },
    { 75, 150, "Lago de Villa del Lago, Crestagrana", "Siluro bigotudo", { "crestagrana", 21.5, 51.0, "Lago de Villa del Lago" } },
    { 150, 225, "Lago Mystral, Vallefresno", "Siluro bigotudo, Bacalao escama de roca", { "vallefresno", 50.1, 67.2, "Lago Mystral (Vallefresno)" } },
    { 225, 300, "Costa de Pluma Lunar, Feralas", "Pescados de nivel alto", { "feralas", 32.2, 41.4, "Bastión Pluma Lunar (Feralas)" } },
  }
  local rows = {}
  for i, sp in ipairs(spots) do
    local r = IconRow(W, H, I .. "Trade_Fishing", sp[3], "Pescás: " .. sp[4], "Pesca " .. sp[1] .. "-" .. sp[2], K.water)
    GoButton(W.frame, H, -118, W.y + 28, sp[5])
    rows[i] = { r = r, sp = sp }
  end
  W:Text("El ícono de mapa pone la flecha y la marca hacia el lugar.", 10, K.dim)
  W:Finish()
  table.insert(P.refreshers, function()
    local skill = NS.Skill("Pesca") or 0
    for _, e in ipairs(rows) do
      local here = skill >= e.sp[1] and skill < e.sp[2]
      e.r.title:SetText(e.sp[3] .. (here and "  |cff7fd16a· te toca acá|r" or ""))
    end
  end)

  local O = P:Card("Del agua a la olla", I .. "INV_Misc_Food_15", K.fire)
  local fish = {
    { 6289, "Pargo de barro mandíbula larga", "Cocinalo desde Cocina 50. Cocinado da +10 de poder de ataque y +5% de experiencia." },
    { 6317, "Frenesí del lago", "Cocinalo desde Cocina 50." },
    { 6308, "Siluro bigotudo", "La receta clave: subís Cocina de 100 a 175 con el siluro que pescás de 75 a 205." },
    { 6358, "Boca negra aceitosa", "No se cocina: vendelo en la subasta (sirve para pociones)." },
  }
  for _, f in ipairs(fish) do
    local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(f[1])) or (GetItemIcon and GetItemIcon(f[1])) or (I .. "INV_Misc_Fish_02")
    IconRow(O, H, icon, f[2], f[3])
  end
  O:Finish()
end)

----------------------------------------------------------------------
-- OFICIOS: tu camino en Peletería
----------------------------------------------------------------------
NS.AddPageExtra("oficios", function(P, H)
  local K, CW = H.K, H.CW
  local C = P:Card("Tu camino en Peletería", I .. "Trade_LeatherWorking", K.nature)
  local lo, hi = 75, 160
  local trackW = CW - 40
  local x0, y0 = 20, C.y - 14
  local segs = {}
  for i, t in ipairs(NS.LW_TIERS) do
    local a = (t.min - lo) / (hi - lo) * trackW
    local b = (t.max - lo) / (hi - lo) * trackW
    local seg = C.frame:CreateTexture(nil, "ARTWORK")
    seg:SetPoint("TOPLEFT", x0 + a, y0)
    seg:SetSize(math.max(2, b - a - 2), 12)
    seg:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")
    segs[i] = { tex = seg, t = t }
    local lab = H.Text(C.frame, 9, K.mute)
    lab:SetPoint("TOP", seg, "TOPLEFT", 0, 12)
    lab:SetText(t.min)
  end
  local endLab = H.Text(C.frame, 9, K.mute)
  endLab:SetPoint("TOPLEFT", x0 + trackW - 8, y0 + 12)
  endLab:SetText(NS.LW_TIERS[#NS.LW_TIERS].max)
  local marker = C.frame:CreateTexture(nil, "OVERLAY")
  marker:SetSize(14, 14)
  marker:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
  local now = H.Text(C.frame, 11.5, K.parch)
  now:SetPoint("TOPLEFT", 16, y0 - 34)
  now:SetWidth(CW - 32)
  C.y = y0 - 34 - 34
  C:Finish()
  table.insert(P.refreshers, function()
    local r, m = NS.Skill("Peletería")
    r = r or 0
    for _, s in ipairs(segs) do
      if r >= s.t.max then s.tex:SetVertexColor(0.35, 0.75, 0.3)
      elseif r >= s.t.min then s.tex:SetVertexColor(1, 0.82, 0.2)
      else s.tex:SetVertexColor(0.3, 0.32, 0.38) end
    end
    local px = math.max(0, math.min(trackW, (r - lo) / (hi - lo) * trackW))
    marker:ClearAllPoints()
    marker:SetPoint("TOP", C.frame, "TOPLEFT", x0 + px, y0 - 13)
    local tier = NS.CurrentTier and NS.CurrentTier()
    if tier then
      now:SetText("Estás en |cffffd96a" .. r .. "|r: tramo " .. tier.min .. "-" .. tier.max .. " → " .. tier.recipe .. (m and r >= m - 5 and "  ·  |cffff9a40cerca del tope: entrená Experto|r" or ""))
    else
      now:SetText("Peletería " .. r .. (m and (" de " .. m) or ""))
    end
  end)
end)
