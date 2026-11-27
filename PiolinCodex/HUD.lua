-- Códice de Piolin: HUD de combate
-- Un solo marco con lo que se usa peleando: Escudo de relámpagos e imbuición del arma a la
-- izquierda, los cuatro tótems con su tiempo a la derecha. Lo que falta se marca en rojo
-- (en lugar del cartel grande en el centro de la pantalla). Solo muestra información, así que
-- funciona en combate sin taint. Se mueve, se escala y se bloquea con el resto de los marcos.
local ADDON, NS = ...

local L = NS.L
local function DB() return NS.db end
local function Print(msg) print("|cffd9a93fCódice:|r " .. msg) end

local I = "Interface\\Icons\\"
local SIZE, GAP, LOW = 30, 6, 5
local SHIELD_IDS = { 324, 52127 }           -- Escudo de relámpagos, Escudo de agua
-- Casillas del juego: 1 fuego, 2 tierra, 3 agua, 4 aire. Se muestran como la barra de tótems.
local TOTEMS = {
  { slot = 2, name = "Tierra", el = "earth", icon = I .. "Spell_Nature_StoneSkinTotem" },
  { slot = 1, name = "Fuego", el = "fire", icon = I .. "Spell_Fire_SearingTotem" },
  { slot = 3, name = "Agua", el = "water", icon = I .. "INV_Spear_04" },
  { slot = 4, name = "Aire", el = "air", icon = I .. "Spell_Nature_GroundingTotem" },
}

local hud, cells, preview, flashUntil

local function IsShaman()
  local _, class = UnitClass("player")
  return class == "SHAMAN"
end

-- 1:45, 38, 4 (segundos); 28m para lo que dura minutos
local function Fmt(sec)
  sec = math.ceil(sec)
  if sec >= 600 then return math.floor(sec / 60) .. "m" end
  if sec >= 60 then return string.format("%d:%02d", math.floor(sec / 60), sec % 60) end
  return tostring(sec)
end

----------------------------------------------------------------------
-- Datos
----------------------------------------------------------------------
local function ShieldNames()
  local t = {}
  for _, id in ipairs(SHIELD_IDS) do local n = GetSpellInfo and GetSpellInfo(id); if n then t[n] = true end end
  return t
end

-- Escudo: ícono, cargas y segundos que le quedan; "unknown" si el juego no deja leer las auras
local function Shield()
  if preview then return preview.shield end
  if NS.AurasReadable and not NS.AurasReadable() then return "unknown" end
  local names = ShieldNames()
  for i = 1, 40 do
    local ok, name, icon, count, _, _, expires = pcall(UnitBuff, "player", i)
    if not ok or not name then break end
    if names[name] then
      return { icon = icon, count = count, left = (expires and expires > 0) and (expires - GetTime()) or nil }
    end
  end
  return nil
end

local function PoleEquipped()
  local mh = GetInventoryItemID("player", 16)
  if not mh then return false end
  local _, _, _, _, _, _, _, _, _, _, _, classID, subID = GetItemInfo(mh)
  return classID == 2 and subID == 20
end

-- Imbuición: "none" sin arma o con caña; si no, segundos que le quedan o nil si falta
local function Imbue()
  if preview then return preview.imbue end
  if not GetInventoryItemID("player", 16) or PoleEquipped() then return "none" end
  local has, expMs = GetWeaponEnchantInfo()
  if has then return { left = expMs and expMs / 1000 or nil } end
  return nil
end

local function Totem(slot)
  if preview then local p = preview[slot]; if p then return p[1], p[2], p[3], p[4] end return nil end
  if not GetTotemInfo then return nil end
  local ok, have, name, start, dur, icon = pcall(GetTotemInfo, slot)
  if not ok or not have or not name or name == "" or not dur or dur <= 0 then return nil end
  return name, start, dur, icon
end

----------------------------------------------------------------------
-- Marco
----------------------------------------------------------------------
local function Cell(parent, x, stripColor)
  local S, K = NS.Style, NS.Style.K
  local c = CreateFrame("Frame", nil, parent)
  c:SetSize(SIZE, SIZE + 18)
  c:SetPoint("TOPLEFT", x, -6)
  c.ring = c:CreateTexture(nil, "BACKGROUND")
  c.ring:SetPoint("TOPLEFT", -2, 2); c.ring:SetSize(SIZE + 4, SIZE + 4)
  c.ring:SetColorTexture(S.C3(K.bad)); c.ring:Hide()
  c.icon = S.Framed(c, I .. "INV_Misc_QuestionMark", SIZE)
  c.icon:SetPoint("TOP", 0, 0)
  c.count = S.Text(c, 9, K.title, S.TITLE_FONT)
  c.count:SetPoint("BOTTOMRIGHT", c.icon, "BOTTOMRIGHT", -1, 1)
  c.time = S.Text(c, 10.5, K.title, S.TITLE_FONT)
  c.time:SetPoint("TOP", c.icon, "BOTTOM", 0, -3)
  c.time:SetJustifyH("CENTER")
  if stripColor then
    c.fill = S.Bar(c, SIZE, 2, stripColor)
    c.fill:SetPoint("BOTTOM", 0, 0)
  end
  c:EnableMouse(true)
  c:RegisterForDrag("LeftButton")
  c:SetScript("OnDragStart", function() if not DB().locked then hud:StartMoving() end end)
  c:SetScript("OnDragStop", function() local f = hud:GetScript("OnDragStop"); if f then f(hud) end end)
  c:SetScript("OnLeave", GameTooltip_Hide)
  return c
end

local function TipFooter()
  GameTooltip:AddLine(DB().locked and L["Destrabá los marcos en la configuración para moverlo."] or L["Arrastrá para mover"], 0.42, 0.45, 0.5, true)
  GameTooltip:Show()
end

local function Build()
  local S, K = NS.Style, NS.Style.K
  hud = S.Panel(UIParent, K.bg, 0.72, K.edge, 0.9)
  hud:SetSize(6 * SIZE + 5 * GAP + 9 + 12, SIZE + 30)
  hud:SetFrameStrata("MEDIUM")
  hud:EnableMouse(true)
  hud:Hide()
  rawset(hud, "name", "PiolinCodexHUD")
  _G.PiolinCodexHUD = hud
  -- posición: la de la barra de tótems de antes, si existía
  if DB().totemPos and not DB().hudPos then DB().hudPos = DB().totemPos; DB().totemPos = nil end
  NS.Movable(hud, "hudPos", { "CENTER", 0, -190 })

  cells = {}
  local x = 6
  cells.shield = Cell(hud, x); x = x + SIZE + GAP
  cells.imbue = Cell(hud, x); x = x + SIZE + GAP
  local sep = hud:CreateTexture(nil, "ARTWORK")
  sep:SetPoint("TOPLEFT", x - 1, -6); sep:SetSize(1, SIZE + 12)
  sep:SetColorTexture(S.C3(K.line))
  x = x + 6
  for i, t in ipairs(TOTEMS) do
    local c = Cell(hud, x, K.el[t.el])
    c.t = t
    cells[i] = c
    x = x + SIZE + GAP
    c:SetScript("OnEnter", function(self)
      local name, start, dur = Totem(self.t.slot)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      if name then
        GameTooltip:AddLine(name, 1, 0.82, 0)
        GameTooltip:AddLine(L["Le quedan %s"]:format(Fmt(math.max(0, start + dur - GetTime()))), 0.9, 0.91, 0.93)
      else
        GameTooltip:AddLine(L["Tótem de %s"]:format(L[self.t.name]:lower()), 1, 0.82, 0)
        GameTooltip:AddLine(L["Ninguno puesto"], 0.6, 0.63, 0.68)
      end
      TipFooter()
    end)
  end
  cells.shield:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine(L["Escudo de relámpagos"], 1, 0.82, 0)
    local s = Shield()
    if s == nil then GameTooltip:AddLine(L["Te falta"], 0.9, 0.33, 0.29)
    elseif type(s) == "table" and s.left then GameTooltip:AddLine(L["Le quedan %s"]:format(Fmt(s.left)), 0.9, 0.91, 0.93) end
    TipFooter()
  end)
  cells.imbue:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine(L["Imbuición del arma"], 1, 0.82, 0)
    local m = Imbue()
    if m == nil then GameTooltip:AddLine(L["Te falta"], 0.9, 0.33, 0.29)
    elseif type(m) == "table" and m.left then GameTooltip:AddLine(L["Le quedan %s"]:format(Fmt(m.left)), 0.9, 0.91, 0.93) end
    TipFooter()
  end)
  rawset(hud, "cells", cells)
end

----------------------------------------------------------------------
-- Pintar
----------------------------------------------------------------------
local function PaintBuff(c, state, icon, flash)
  local K = NS.Style.K
  if state == "none" or state == "unknown" then
    c.icon:SetTexture(icon); c.icon:SetDesaturated(true); c.icon:SetAlpha(0.3)
    c.time:SetText(""); c.count:SetText(""); c.ring:Hide()
    return false
  end
  if state == nil then
    c.icon:SetTexture(icon); c.icon:SetDesaturated(true); c.icon:SetAlpha(0.6)
    c.time:SetText(L["falta"]); c.time:SetTextColor(NS.Style.C3(K.bad)); c.count:SetText("")
    c.ring:Show(); c.ring:SetAlpha(flash and (0.5 + 0.5 * math.abs(math.sin(GetTime() * 6))) or 0.9)
    return true
  end
  c.icon:SetTexture(state.icon or icon); c.icon:SetDesaturated(false); c.icon:SetAlpha(1)
  c.ring:Hide()
  c.count:SetText((state.count and state.count > 1) and state.count or "")
  c.time:SetText(state.left and Fmt(state.left) or "")
  c.time:SetTextColor(NS.Style.C3(K.title))
  return false
end

-- Devuelve: ¿hay algo que mirar? (tótem puesto o algo que falta) y el próximo intervalo de repintado
local function Paint()
  local K = NS.Style.K
  local now = GetTime()
  local flash = flashUntil and now < flashUntil
  local missing = false
  local lvl = UnitLevel("player") or 1
  local shield = Shield()
  if lvl < 8 and shield == nil then shield = "none" end   -- el escudo se aprende al 8
  missing = PaintBuff(cells.shield, shield, I .. "Spell_Nature_LightningShield", flash) or missing
  local weapon = GetInventoryItemTexture("player", 16) or (I .. "INV_Axe_01")
  missing = PaintBuff(cells.imbue, Imbue(), weapon, flash) or missing

  local anyTotem, soon = false, false
  for _, c in ipairs(cells) do
    local name, start, dur, icon = Totem(c.t.slot)
    local left = name and (start + dur - now) or 0
    if name and left > 0 then
      anyTotem = true
      if c.cur ~= name then
        c.cur = name
        c.icon:SetTexture(icon or c.t.icon)
        if NS.Pop and not DB().noAnim then NS.Pop(c.icon, SIZE, 0.35) end
      end
      c.icon:SetDesaturated(false)
      c.time:SetText(Fmt(left))
      c.fill:_SetValue(left / dur); c.fill:Show()
      if left <= LOW then
        soon = true
        c.time:SetTextColor(NS.Style.C3(K.bad))
        c.icon:SetAlpha(0.55 + 0.45 * math.abs(math.sin(now * 4)))
      else
        c.time:SetTextColor(NS.Style.C3(K.title)); c.icon:SetAlpha(1)
      end
    else
      c.cur = nil
      c.icon:SetTexture(c.t.icon); c.icon:SetDesaturated(true); c.icon:SetAlpha(0.25)
      c.time:SetText(""); c.fill:Hide()
    end
  end
  return anyTotem or missing, (soon or flash) and 0.1 or 0.5
end

----------------------------------------------------------------------
-- Visibilidad: siempre (atenuado si no hay nada), solo en combate u oculto
----------------------------------------------------------------------
local wait, interval = 0, 0.5
local function OnUpdate(self, el)
  wait = wait + el
  if wait < interval then return end
  wait = 0
  if preview and GetTime() > preview.untilT then preview = nil; NS.UpdateHUD() return end
  local busy
  busy, interval = Paint()
  local inCombat = InCombatLockdown()
  self:SetAlpha((busy or inCombat or preview) and 1 or 0.4)
end

function NS.UpdateHUD()
  if not hud then return end
  local db = DB()
  hud:SetScale(db.hudScale or 1)
  local mode = db.hudMode or "always"
  local show = preview or (not db.noTotems and mode ~= "hidden" and (mode == "always" or InCombatLockdown() or (flashUntil and GetTime() < flashUntil)))
  if show then
    if not hud:IsShown() then
      hud:Show()
      if NS.Appear and not db.noAnim then NS.Appear(hud, 0, -8, 0.25) end
    end
    wait, interval = 1, 0
    hud:SetScript("OnUpdate", OnUpdate)
  else
    hud:SetScript("OnUpdate", nil)
    hud:Hide()
  end
end
NS.UpdateTotems = NS.UpdateHUD   -- nombre viejo

-- Antes de pelear: marca en rojo lo que falta (devuelve false si el HUD está apagado)
function NS.HudFlash()
  if not hud or DB().noTotems or (DB().hudMode or "always") == "hidden" then return false end
  flashUntil = GetTime() + 4
  NS.UpdateHUD()
  C_Timer.After(4.1, NS.UpdateHUD)
  return true
end

-- Datos de ejemplo durante 20 segundos para ver y acomodar el HUD
function NS.HudPreview()
  if not hud then Build() end
  local t = GetTime()
  preview = {
    untilT = t + 20,
    shield = nil,
    imbue = { left = 28 * 60 },
    [2] = { "Tótem Fuerza de la tierra", t - 10, 120, I .. "Spell_Nature_EarthBindTotem" },
    [1] = { "Tótem abrasador", t - 26, 30, I .. "Spell_Fire_SearingTotem" },
    [3] = { "Tótem Corriente de sanación", t - 40, 60, I .. "INV_Spear_04" },
  }
  NS.UpdateHUD()
end
NS.TotemPreview = NS.HudPreview

----------------------------------------------------------------------
-- Eventos y comando
----------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    if not IsShaman() then return end
    Build()
    NS.SafeEvents(self, { "PLAYER_TOTEM_UPDATE", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_LEVEL_UP" })
    NS.UnitEvents(self, { "UNIT_AURA", "UNIT_INVENTORY_CHANGED" }, "player")
  end
  NS.UpdateHUD()
end)

-- /piolin hud [centrar]  (también /piolin totems)
function NS.HudSlash(msg)
  local arg = msg:match("^hud%s*(%a*)$") or msg:match("^totems%s*(%a*)$") or msg:match("^tótems%s*(%a*)$")
  if not arg then return false end
  if not IsShaman() then Print("el HUD de combate es solo para chamanes."); return true end
  if not hud then Build() end
  if arg == "centrar" then
    DB().hudPos = nil
    for _, m in ipairs(NS.movables) do if m.key == "hudPos" then m.place() end end
    Print("HUD de vuelta a su lugar.")
  end
  NS.HudPreview()
  if DB().noTotems or DB().hudMode == "hidden" then Print("el HUD está apagado en la configuración; esto es solo una muestra.") end
  return true
end
NS.TotemSlash = NS.HudSlash
