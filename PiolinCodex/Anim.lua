-- Códice de Piolin: animaciones chamánicas (elementos, tótems, relámpagos)
local ADDON, NS = ...

local function DB() return NS.db end
local function On() return NS.db and not DB().noAnim end
local WHITE = "Interface\\Buttons\\WHITE8X8"
local GLOW = "Interface\\Buttons\\UI-ActionButton-Border"
local SPARK = "Interface\\CastingBar\\UI-CastingBar-Spark"
local EL = {
  earth = { 0.78, 0.55, 0.27 }, fire = { 1, 0.48, 0.14 }, water = { 0.3, 0.66, 1 }, air = { 0.78, 0.95, 1 },
  blue = { 0.0, 0.44, 0.87 }, heal = { 0.37, 0.88, 0.42 }, gold = { 1, 0.82, 0 },
}
local TOTEMS = {
  { "Interface\\Icons\\Spell_Nature_StrengthOfEarthTotem02", EL.earth },
  { "Interface\\Icons\\Spell_Fire_SearingTotem", EL.fire },
  { "Interface\\Icons\\INV_Spear_04", EL.water },
  { "Interface\\Icons\\Spell_Nature_Windfury", EL.air },
}

----------------------------------------------------------------------
-- Motor de interpolación (un solo OnUpdate para todo). El marco se oculta cuando no hay
-- animaciones, así el OnUpdate no corre en cada cuadro sin necesidad.
----------------------------------------------------------------------
local tweens = {}
local driver = CreateFrame("Frame")
driver:Hide()
driver:SetScript("OnUpdate", function(self, dt)
  for i = #tweens, 1, -1 do
    local tw = tweens[i]
    tw.t = tw.t + dt
    if tw.t >= tw.delay then
      local p = math.min(1, (tw.t - tw.delay) / tw.dur)
      local ok, err = pcall(tw.fn, tw.ease and tw.ease(p) or p)
      if not ok then NS.lastAnimError = err end
      if p >= 1 or not ok then
        table.remove(tweens, i)
        if tw.done then pcall(tw.done) end
      end
    end
  end
  if #tweens == 0 then self:Hide() end
end)
local function Tween(dur, fn, delay, done, ease)
  table.insert(tweens, { t = 0, dur = dur, fn = fn, delay = delay or 0, done = done, ease = ease })
  driver:Show()
end
local function OutCubic(p) return 1 - (1 - p) ^ 3 end
local function OutBack(p) local c = 1.7; return 1 + (c + 1) * (p - 1) ^ 3 + c * (p - 1) ^ 2 end
NS.Tween, NS.OutCubic = Tween, OutCubic

----------------------------------------------------------------------
-- Entradas y salidas para las ventanas que aparecen en pantalla
-- (aviso, flecha, lista de compras, instructor). Respetan "Animaciones del Códice".
----------------------------------------------------------------------
local moving = {}   -- marcos con una entrada/salida en curso (para no pisarse)

local function Anchor(f)
  local p, rel, rp, x, y = f:GetPoint(1)
  if type(p) ~= "string" then return nil end
  return { p, rel, rp, x or 0, y or 0 }
end
local function Place(f, a, dx, dy)
  f:ClearAllPoints()
  f:SetPoint(a[1], a[2], a[3], a[4] + dx, a[5] + dy)
end

-- Aparece: fundido de 0 a 1 mientras llega desde (dx, dy) a su lugar
function NS.Appear(f, dx, dy, dur)
  if not f then return end
  local token = {}
  moving[f] = token
  if not On() then f:SetAlpha(1); return end
  local a = Anchor(f)
  dx, dy = dx or 0, dy or 0
  f:SetAlpha(0)
  if a then Place(f, a, dx, dy) end
  Tween(dur or 0.25, function(p)
    if moving[f] ~= token then return end
    f:SetAlpha(p)
    if a then Place(f, a, dx * (1 - p), dy * (1 - p)) end
  end, 0, function()
    if moving[f] ~= token then return end
    f:SetAlpha(1)
    if a then Place(f, a, 0, 0) end
    moving[f] = nil
  end, OutCubic)
end

-- Desaparece: fundido de 1 a 0 alejándose hacia (dx, dy); al final se oculta y vuelve a su lugar
function NS.Vanish(f, dx, dy, dur, done)
  if not f then return end
  local token = {}
  moving[f] = token
  if not On() then f:Hide(); if done then done() end; return end
  local a = Anchor(f)
  dx, dy = dx or 0, dy or 0
  Tween(dur or 0.3, function(p)
    if moving[f] ~= token then return end
    f:SetAlpha(1 - p)
    if a then Place(f, a, dx * p, dy * p) end
  end, 0, function()
    if moving[f] ~= token then return end
    f:Hide(); f:SetAlpha(1)
    if a then Place(f, a, 0, 0) end
    moving[f] = nil
    if done then done() end
  end, OutCubic)
end

-- Rebote corto de un ícono (crece desde chico y se pasa un poquito)
function NS.Pop(tex, size, dur)
  if not tex or not On() then return end
  Tween(dur or 0.35, function(p)
    local s = size * (0.55 + 0.45 * p)
    tex:SetSize(s, s)
  end, 0, function() tex:SetSize(size, size) end, OutBack)
end

local function Tex(parent, path, w, h, layer, add, color)
  local t = parent:CreateTexture(nil, layer or "OVERLAY")
  t:SetTexture(path)
  t:SetSize(w, h or w)
  if add then t:SetBlendMode("ADD") end
  if color then t:SetVertexColor(color[1], color[2], color[3]) end
  return t
end

----------------------------------------------------------------------
-- 1. Apertura de los elementos
----------------------------------------------------------------------
local openFx
function NS.AnimOpen(frame)
  if not On() then frame:SetAlpha(1); NS.Sound("open"); return end
  if not openFx then
    openFx = CreateFrame("Frame", nil, UIParent)
    openFx:SetFrameStrata("DIALOG")
    openFx:SetSize(1, 1)
    openFx.orbs = {}
    for i, t in ipairs(TOTEMS) do
      local o = {}
      o.glow = Tex(openFx, GLOW, 70, 70, "ARTWORK", true, t[2])
      o.icon = Tex(openFx, t[1], 26, 26, "OVERLAY")
      o.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      openFx.orbs[i] = o
    end
    openFx.flash = openFx:CreateTexture(nil, "OVERLAY", nil, 3)
    openFx.flash:SetTexture(WHITE)
    openFx.flash:SetBlendMode("ADD")
    openFx.flash:SetVertexColor(0.3, 0.6, 1)
  end
  openFx:ClearAllPoints()
  openFx:SetPoint("CENTER", frame, "CENTER", 0, 0)
  openFx:Show()
  openFx.flash:ClearAllPoints()
  openFx.flash:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
  openFx.flash:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
  openFx.flash:SetAlpha(0)
  frame:SetAlpha(0)
  local starts = { { -300, 180 }, { 300, 180 }, { 300, -180 }, { -300, -180 } }
  for i, o in ipairs(openFx.orbs) do
    local sx, sy = starts[i][1], starts[i][2]
    o.icon:Show(); o.glow:Show()
    Tween(0.6, function(p)
      local x, y = sx * (1 - p), sy * (1 - p)
      local a = p < 0.15 and p / 0.15 or (p > 0.85 and (1 - p) / 0.15 or 1)
      for _, r in ipairs({ o.icon, o.glow }) do
        r:ClearAllPoints(); r:SetPoint("CENTER", openFx, "CENTER", x, y); r:SetAlpha(a)
        r:SetRotation(p * math.pi * 3)
      end
    end, (i - 1) * 0.05, function() o.icon:Hide(); o.glow:Hide() end, OutCubic)
  end
  Tween(0.45, function(p)
    frame:SetAlpha(p)
    openFx.flash:SetAlpha(0.45 * (1 - p))
  end, 0.62, function() frame:SetAlpha(1) end, OutCubic)
  C_Timer.After(0.6, function() NS.Sound("open") end)
end

----------------------------------------------------------------------
-- 3. Tilde con Escudo de relámpagos y onda de sanación
----------------------------------------------------------------------
local tickFx
function NS.AnimTick(row)
  if not On() or not row or not rawget(row, "slotTex") then return end
  if not tickFx then
    tickFx = CreateFrame("Frame", nil, UIParent)
    tickFx:SetSize(1, 1)
    tickFx:SetFrameStrata("DIALOG")
    tickFx.orbs = {}
    for i = 1, 3 do
      local o = Tex(tickFx, "Interface\\Icons\\Spell_Nature_LightningShield", 10, 10, "OVERLAY")
      o:SetTexCoord(0.2, 0.8, 0.2, 0.8)
      local g = Tex(tickFx, GLOW, 26, 26, "ARTWORK", true, EL.water)
      tickFx.orbs[i] = { o, g }
    end
    tickFx.ring = Tex(tickFx, GLOW, 40, 40, "OVERLAY", true, EL.heal)
  end
  tickFx:ClearAllPoints()
  tickFx:SetPoint("CENTER", row.slotTex, "CENTER", 0, 0)
  tickFx:SetScale(row:GetEffectiveScale() / UIParent:GetEffectiveScale())
  tickFx:Show()
  tickFx.ring:SetAlpha(0)
  Tween(0.7, function(p)
    local r = 20 - 14 * p
    for i, pair in ipairs(tickFx.orbs) do
      local a = p * math.pi * 3 + i * (math.pi * 2 / 3)
      for _, t in ipairs(pair) do
        t:ClearAllPoints(); t:SetPoint("CENTER", tickFx, "CENTER", math.cos(a) * r, math.sin(a) * r)
        t:SetAlpha(p < 0.85 and 1 or (1 - p) / 0.15)
      end
    end
  end, 0, nil, nil)
  Tween(0.5, function(p)
    tickFx.ring:SetSize(30 + 50 * p, 30 + 50 * p)
    tickFx.ring:ClearAllPoints(); tickFx.ring:SetPoint("CENTER", tickFx, "CENTER")
    tickFx.ring:SetAlpha(1 - p)
  end, 0.62, function() tickFx:Hide() end, OutCubic)
end

----------------------------------------------------------------------
-- 4. Barras: chispa de agua y "+1" flotante
----------------------------------------------------------------------
function NS.AnimBar(bar, from, to)
  if not On() or not bar then bar:_SetValue(to); return end
  local mn, mx = bar:GetMinMaxValues()
  if not rawget(bar, "spark") then
    bar.spark = Tex(bar, SPARK, 22, bar:GetHeight() * 2.2, "OVERLAY", true, EL.water)
  end
  bar.spark:Show()
  Tween(0.7, function(p)
    local v = from + (to - from) * p
    bar:_SetValue(v)
    local frac = (mx > mn) and (v - mn) / (mx - mn) or 0
    bar.spark:ClearAllPoints()
    bar.spark:SetPoint("CENTER", bar, "LEFT", bar:GetWidth() * frac, 0)
    bar.spark:SetAlpha(p < 0.8 and 1 or (1 - p) / 0.2)
  end, 0, function() bar.spark:Hide(); bar:_SetValue(to) end, OutCubic)
end

function NS.AnimFloat(anchor, text)
  if not On() or not anchor then return end
  local fs = anchor:CreateFontString(nil, "OVERLAY")
  fs:SetFont("Fonts\\MORPHEUS.TTF", 15, "OUTLINE")
  fs:SetTextColor(0.45, 0.78, 1)
  fs:SetText(text)
  Tween(1.4, function(p)
    fs:ClearAllPoints(); fs:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, 2 + 26 * p)
    fs:SetAlpha(p < 0.2 and p / 0.2 or (1 - p) / 0.8)
  end, 0, function() fs:Hide() end, OutCubic)
  NS.Sound("bar")
end

----------------------------------------------------------------------
-- 5. Sección completa (cartel tipo logro)
----------------------------------------------------------------------
local toast
function NS.AnimSection(title, n)
  if not On() then NS.Sound("section"); return end
  if not toast then
    local BD = BackdropTemplateMixin and "BackdropTemplate" or nil
    toast = CreateFrame("Frame", nil, UIParent, BD)
    toast:SetSize(380, 74)
    toast:SetFrameStrata("DIALOG")
    toast:SetBackdrop({ bgFile = WHITE, edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 20, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
    toast:SetBackdropColor(0.04, 0.08, 0.16, 0.96)
    toast:SetClipsChildren(true)
    toast.icon = Tex(toast, "Interface\\Icons\\Spell_Nature_StrengthOfEarthTotem02", 44, 44, "ARTWORK")
    toast.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    toast.icon:SetPoint("LEFT", 16, 0)
    toast.ring = Tex(toast, "Interface\\Buttons\\UI-Quickslot2", 76, 76, "OVERLAY")
    toast.ring:SetPoint("CENTER", toast.icon, "CENTER")
    toast.kick = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toast.kick:SetPoint("TOPLEFT", 72, -12)
    toast.kick:SetTextColor(0.3, 0.66, 1)
    toast.kick:SetText("SECCIÓN COMPLETA")
    toast.title = toast:CreateFontString(nil, "OVERLAY")
    toast.title:SetFont("Fonts\\MORPHEUS.TTF", 17, "")
    toast.title:SetTextColor(1, 0.82, 0)
    toast.title:SetPoint("TOPLEFT", 72, -26)
    toast.title:SetWidth(290)
    toast.title:SetJustifyH("LEFT")
    toast.sub = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toast.sub:SetPoint("TOPLEFT", 72, -48)
    toast.sub:SetTextColor(0.65, 0.7, 0.8)
    toast.shine = toast:CreateTexture(nil, "OVERLAY", nil, 4)
    toast.shine:SetTexture(WHITE)
    toast.shine:SetBlendMode("ADD")
    toast.shine:SetSize(70, 74)
  end
  toast.title:SetText(title)
  toast.sub:SetText("Los espíritus de los elementos te honran · " .. n .. "/" .. n)
  toast:Show()
  toast:SetAlpha(1)
  NS.Sound("section")
  Tween(0.55, function(p)
    toast:ClearAllPoints(); toast:SetPoint("TOP", UIParent, "TOP", 0, -120 + 140 * (1 - p))
  end, 0, nil, OutBack)
  Tween(0.8, function(p)
    toast.shine:ClearAllPoints(); toast.shine:SetPoint("CENTER", toast, "LEFT", -40 + 460 * p, 0)
    toast.shine:SetAlpha(0.28 * math.sin(p * math.pi))
  end, 0.6)
  Tween(0.6, function(p) toast:SetAlpha(1 - p) end, 4.2, function() toast:Hide() end)
end

----------------------------------------------------------------------
-- 6. Subida de nivel: relámpago, cadena y destello
----------------------------------------------------------------------
local lvlFx
local function Segment(parent, x1, y1, x2, y2, w, color)
  local t = parent.pool[parent.used + 1]
  if not t then t = Tex(parent, WHITE, 1, 1, "OVERLAY", true); table.insert(parent.pool, t) end
  parent.used = parent.used + 1
  local dx, dy = x2 - x1, y2 - y1
  local len = math.sqrt(dx * dx + dy * dy)
  t:SetSize(len, w)
  t:ClearAllPoints()
  t:SetPoint("CENTER", parent, "BOTTOMLEFT", (x1 + x2) / 2, (y1 + y2) / 2)
  t:SetRotation(math.atan2(dy, dx))
  t:SetVertexColor(color[1], color[2], color[3])
  t:Show()
end
local function Bolt(parent, x1, y1, x2, y2, disp, w, color)
  if disp < 6 then Segment(parent, x1, y1, x2, y2, w, color); return end
  local mx = (x1 + x2) / 2 + (math.random() - 0.5) * disp
  local my = (y1 + y2) / 2 + (math.random() - 0.5) * disp
  Bolt(parent, x1, y1, mx, my, disp / 2, w, color)
  Bolt(parent, mx, my, x2, y2, disp / 2, w, color)
end

function NS.AnimLevel(level)
  if not On() then return end
  if not lvlFx then
    lvlFx = CreateFrame("Frame", nil, UIParent)
    lvlFx:SetAllPoints()
    lvlFx:SetFrameStrata("FULLSCREEN_DIALOG")
    lvlFx.pool, lvlFx.used = {}, 0
    lvlFx.flash = lvlFx:CreateTexture(nil, "BACKGROUND")
    lvlFx.flash:SetAllPoints()
    lvlFx.flash:SetTexture(WHITE)
    lvlFx.flash:SetBlendMode("ADD")
    lvlFx.flash:SetVertexColor(0.35, 0.6, 1)
    lvlFx.text = lvlFx:CreateFontString(nil, "OVERLAY")
    lvlFx.text:SetFont("Fonts\\MORPHEUS.TTF", 46, "OUTLINE")
    lvlFx.text:SetTextColor(1, 0.82, 0)
    lvlFx.text:SetShadowColor(0, 0.45, 1, 1)
    lvlFx.text:SetShadowOffset(0, 0)
    lvlFx.text:SetPoint("TOP", 0, -90)
  end
  lvlFx:Show()
  local W, H = UIParent:GetWidth(), UIParent:GetHeight()
  local cx, cy = W / 2, H * 0.42     -- más o menos donde está tu personaje
  local ends = { { cx - W * 0.16, cy - 40 }, { cx + W * 0.15, cy - 10 }, { cx + W * 0.06, cy - 110 } }
  local function strike(alpha)
    for _, t in ipairs(lvlFx.pool) do t:Hide() end
    lvlFx.used = 0
    if alpha <= 0 then return end
    Bolt(lvlFx, cx + (math.random() - 0.5) * 60, H, cx, cy, 160, 3, { 0.75 * alpha, 0.9 * alpha, 1 * alpha })
    local px, py = cx, cy
    for _, e in ipairs(ends) do
      Bolt(lvlFx, px, py, e[1], e[2], 70, 2, { 0.5 * alpha, 0.8 * alpha, 1 * alpha })
      px, py = e[1], e[2]
    end
  end
  local frames = 0
  Tween(0.75, function(p)
    frames = frames + 1
    if frames % 3 == 1 then strike(1 - p) end
    lvlFx.flash:SetAlpha(p < 0.15 and 0.45 or 0.45 * (1 - (p - 0.15) / 0.85))
  end, 0, function() strike(0); lvlFx.flash:SetAlpha(0) end)
  lvlFx.text:SetText("¡Nivel " .. level .. "!")
  Tween(2.6, function(p)
    local a = p < 0.12 and p / 0.12 or (p > 0.8 and (1 - p) / 0.2 or 1)
    lvlFx.text:SetAlpha(a)
    local s = p < 0.12 and (1.6 - 0.6 * (p / 0.12)) or 1
    lvlFx.text:SetTextHeight(46 * s)
  end, 0.15, function() lvlFx.text:SetAlpha(0) end)
  NS.Sound("level")
end

----------------------------------------------------------------------
-- 7. El rayo del minimapa late cuando hay algo pendiente
----------------------------------------------------------------------
local pulse, reasons = nil, {}
local function Pending()
  wipe(reasons)
  local free = NS.FreeTalentPoints and NS.FreeTalentPoints() or 0
  if free and free > 0 then table.insert(reasons, "Tenés " .. free .. " punto(s) de talento sin gastar") end
  local q = NS.questLog
  if q and #q.ready > 0 then table.insert(reasons, "Lista para entregar: " .. q.ready[1] .. (#q.ready > 1 and (" y " .. (#q.ready - 1) .. " más") or "")) end
  if DB().tentAt and time() - DB().tentAt >= 3600 then table.insert(reasons, "La Tienda de campaña ya está disponible") end
  return #reasons > 0
end

local function BuildPulse()
  local mb = NS.minimapButton
  if not mb or pulse then return end
  pulse = CreateFrame("Frame", nil, mb)
  pulse:SetAllPoints()
  pulse:SetFrameLevel(mb:GetFrameLevel() + 2)
  pulse.r1 = Tex(pulse, GLOW, 60, 60, "OVERLAY", true, EL.water)
  pulse.r2 = Tex(pulse, GLOW, 60, 60, "OVERLAY", true, EL.water)
  for _, r in ipairs({ pulse.r1, pulse.r2 }) do r:SetPoint("CENTER", mb, "TOPLEFT", 17, -16) end
  local clock, rings = 0, { pulse.r1, pulse.r2 }
  pulse:SetScript("OnUpdate", function(_, dt)
    clock = clock + dt
    for i, r in ipairs(rings) do
      local ph = (clock / 1.6 + (i - 1) * 0.5) % 1
      r:SetSize(44 + 40 * ph, 44 + 40 * ph)
      r:SetAlpha((1 - ph) * 0.9)
    end
  end)
  pulse:Hide()
  mb:HookScript("OnEnter", function()
    if #reasons > 0 then
      GameTooltip:AddLine(" ")
      for _, r in ipairs(reasons) do GameTooltip:AddLine(r, 1, 0.55, 0.45, true) end
      GameTooltip:Show()
    end
  end)
end

local wasPending = false
local function CheckPulse()
  BuildPulse()
  if not pulse then return end
  local now = Pending()
  pulse:SetShown(now and On())
  if now and not wasPending then NS.Sound("pulse") end
  wasPending = now
end

----------------------------------------------------------------------
-- 8. Cambio de pestaña con ráfaga de viento
----------------------------------------------------------------------
local wind
function NS.AnimTab(page, frame)
  if not On() or not page or not rawget(page, "__a") then return end
  local a = page.__a
  if not wind then
    wind = {}
    for i = 1, 3 do
      local g = frame:CreateTexture(nil, "OVERLAY", nil, 5)
      g:SetTexture(WHITE)
      g:SetBlendMode("ADD")
      g:SetVertexColor(EL.air[1], EL.air[2], EL.air[3])
      g:SetSize(170 + i * 30, 2)
      wind[i] = g
    end
  end
  page:SetAlpha(0)
  Tween(0.28, function(p)
    local dx = 28 * (1 - p)
    page:ClearAllPoints()
    page:SetPoint("TOPLEFT", frame, "TOPLEFT", a[1] + dx, a[2])
    page:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", a[3] + dx, a[4])
    page:SetAlpha(p)
  end, 0, function()
    page:ClearAllPoints()
    page:SetPoint("TOPLEFT", frame, "TOPLEFT", a[1], a[2])
    page:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", a[3], a[4])
    page:SetAlpha(1)
  end, OutCubic)
  local ys = { -170, -260, -350 }
  for i, g in ipairs(wind) do
    Tween(0.45, function(p)
      g:ClearAllPoints()
      g:SetPoint("LEFT", frame, "TOPLEFT", a[1] - 40 + 560 * p, ys[i])
      g:SetAlpha(0.55 * math.sin(p * math.pi))
    end, (i - 1) * 0.05)
  end
end

----------------------------------------------------------------------
-- Eventos
----------------------------------------------------------------------
local ev = CreateFrame("Frame")
NS.SafeEvents(ev, { "PLAYER_LOGIN", "PLAYER_LEVEL_UP", "CHARACTER_POINTS_CHANGED", "TRAIT_CONFIG_UPDATED", "QUEST_LOG_UPDATE" })
ev:SetScript("OnEvent", function(self, event, a1)
  if event == "PLAYER_LOGIN" then
    C_Timer.After(5, CheckPulse)
    C_Timer.NewTicker(5, CheckPulse)
  elseif event == "PLAYER_LEVEL_UP" then
    C_Timer.After(0.3, function() NS.AnimLevel(a1) end)
  else
    C_Timer.After(1, CheckPulse)
  end
end)
