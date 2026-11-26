-- Códice de Piolin: temporizadores de tótems
-- Cuatro casillas (tierra, fuego, agua, aire) con el tiempo que le queda a cada tótem.
-- Solo muestra información, así que funciona también en combate.
local ADDON, NS = ...

local function DB() return PiolinCodexDB end
local function Print(msg) print("|cffd9a93fCódice:|r " .. msg) end

local I = "Interface\\Icons\\"
-- Casillas del juego: 1 fuego, 2 tierra, 3 agua, 4 aire. Se muestran como la barra de tótems: tierra, fuego, agua, aire.
local ORDER = {
  { slot = 2, name = "Tierra", color = "earth", icon = I .. "Spell_Nature_StoneSkinTotem" },
  { slot = 1, name = "Fuego", color = "fire", icon = I .. "Spell_Fire_SearingTotem" },
  { slot = 3, name = "Agua", color = "water", icon = I .. "INV_Spear_04" },
  { slot = 4, name = "Aire", color = "air", icon = I .. "Spell_Nature_GroundingTotem" },
}
local SIZE, GAP, LOW = 30, 6, 5

local bar, cells, preview

local function IsShaman()
  local _, class = UnitClass("player")
  return class == "SHAMAN"
end

-- Tiempo restante en texto corto: 1:45, 38, 4
local function Fmt(sec)
  sec = math.ceil(sec)
  if sec >= 60 then return string.format("%d:%02d", math.floor(sec / 60), math.floor(sec % 60)) end
  return tostring(math.ceil(sec))
end

-- Datos de una casilla: nombre, inicio, duración e ícono (o nada si está vacía)
local function Info(slot)
  if preview then
    local p = preview[slot]
    if p then return p[1], p[2], p[3], p[4] end
    return nil
  end
  if not GetTotemInfo then return nil end
  local ok, have, name, start, dur, icon = pcall(GetTotemInfo, slot)
  if not ok or not have or not name or name == "" or not dur or dur <= 0 then return nil end
  return name, start, dur, icon
end

local function SavePos()
  local p, _, _, x, y = bar:GetPoint()
  DB().totemPos = { p or "CENTER", math.floor((x or 0) + 0.5), math.floor((y or 0) + 0.5) }
end

local function Place()
  bar:ClearAllPoints()
  local pos = DB().totemPos
  if pos then bar:SetPoint(pos[1], UIParent, pos[1], pos[2], pos[3])
  else bar:SetPoint("CENTER", UIParent, "CENTER", 0, -190) end
end

local function Build()
  local S = NS.Style
  local K = S.K
  local W = 4 * SIZE + 3 * GAP + 16
  bar = S.Panel(UIParent, K.bg, 0.82, K.edge, 0.9)
  bar:SetSize(W, SIZE + 30)
  bar:SetFrameStrata("MEDIUM")
  bar:SetClampedToScreen(true)
  bar:EnableMouse(true)
  bar:SetMovable(true)
  bar:RegisterForDrag("LeftButton")
  bar:SetScript("OnDragStart", bar.StartMoving)
  bar:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePos() end)
  bar:Hide()
  rawset(bar, "name", "PiolinCodexTotems")
  _G.PiolinCodexTotems = bar
  Place()

  cells = {}
  for i, e in ipairs(ORDER) do
    local c = CreateFrame("Frame", nil, bar)
    c:SetSize(SIZE, SIZE + 22)
    c:SetPoint("TOPLEFT", 8 + (i - 1) * (SIZE + GAP), -6)
    c.e = e
    local strip = c:CreateTexture(nil, "ARTWORK")
    strip:SetPoint("TOPLEFT", 0, 0); strip:SetPoint("TOPRIGHT", 0, 0); strip:SetHeight(2)
    strip:SetColorTexture(S.C3(K[e.color]))
    c.icon = S.Framed(c, e.icon, SIZE)
    c.icon:SetPoint("TOP", 0, -4)
    c.time = S.Text(c, 11, K.parch, S.TITLE_FONT)
    c.time:SetPoint("TOP", c.icon, "BOTTOM", 0, -3)
    c.time:SetJustifyH("CENTER")
    c.fill = S.Bar(c, SIZE, 2, K[e.color])
    c.fill:SetPoint("BOTTOM", 0, 0)
    c:EnableMouse(true)
    c:SetScript("OnEnter", function(self)
      local name, start, dur = Info(self.e.slot)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      if name then
        GameTooltip:AddLine(name, 1, 0.82, 0)
        local left = math.max(0, start + dur - GetTime())
        GameTooltip:AddLine("Le quedan " .. Fmt(left) .. (left >= 60 and "" or " s"), 0.86, 0.89, 0.93)
      else
        GameTooltip:AddLine("Tótem de " .. self.e.name:lower(), 1, 0.82, 0)
        GameTooltip:AddLine("Ninguno puesto", 0.53, 0.57, 0.64)
      end
      GameTooltip:AddLine("Arrastrá la barra para moverla", 0.42, 0.46, 0.53)
      GameTooltip:Show()
    end)
    c:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- la casilla deja pasar el arrastre a la barra
    c:RegisterForDrag("LeftButton")
    c:SetScript("OnDragStart", function() bar:StartMoving() end)
    c:SetScript("OnDragStop", function() bar:StopMovingOrSizing(); SavePos() end)
    cells[i] = c
  end
  rawset(bar, "cells", cells)
end

-- Pinta las cuatro casillas; devuelve si hay al menos un tótem puesto
local function Paint()
  local K = NS.Style.K
  local now, any = GetTime(), false
  for _, c in ipairs(cells) do
    local name, start, dur, icon = Info(c.e.slot)
    local left = name and (start + dur - now) or 0
    if name and left > 0 then
      any = true
      if c.cur ~= name then
        c.cur = name
        c.icon:SetTexture(icon or c.e.icon)
        if NS.Pop and not DB().noAnim then NS.Pop(c.icon, SIZE, 0.35) end
      end
      c.icon:SetDesaturated(false)
      c.time:SetText(Fmt(left))
      c.fill:_SetValue(left / dur)
      c.fill:Show()
      if left <= LOW then
        c.time:SetTextColor(NS.Style.C3(K.bad))
        c.icon:SetAlpha(0.55 + 0.45 * math.abs(math.sin(now * 4)))
      else
        c.time:SetTextColor(NS.Style.C3(K.parch))
        c.icon:SetAlpha(1)
      end
    else
      c.cur = nil
      c.icon:SetTexture(c.e.icon)
      c.icon:SetDesaturated(true)
      c.icon:SetAlpha(0.25)
      c.time:SetText("")
      c.fill:Hide()
    end
  end
  return any
end

local elapsed = 0
local function OnUpdate(self, el)
  elapsed = elapsed + el
  if elapsed < 0.1 then return end
  elapsed = 0
  if preview and GetTime() > preview.untilT then preview = nil end
  if not Paint() then
    self:SetScript("OnUpdate", nil)
    if NS.Vanish and not DB().noAnim then NS.Vanish(self, 0, -8, 0.35) else self:Hide() end
  end
end

-- Revisa las casillas y muestra u oculta la barra
function NS.UpdateTotems()
  if not bar then return end
  if DB().noTotems and not preview then bar:Hide(); return end
  if Paint() then
    if not bar:IsShown() then
      bar:SetAlpha(1)
      bar:Show()
      if NS.Appear and not DB().noAnim then NS.Appear(bar, 0, -8, 0.25) end
    end
    elapsed = 0
    bar:SetScript("OnUpdate", OnUpdate)
  end
end

-- Muestra tótems de ejemplo durante 20 segundos para ver y mover la barra
function NS.TotemPreview()
  if not bar then Build() end
  local t = GetTime()
  preview = {
    untilT = t + 20,
    [2] = { "Tótem Fuerza de la tierra", t - 10, 120, I .. "Spell_Nature_EarthBindTotem" },
    [1] = { "Tótem abrasador", t - 22, 30, I .. "Spell_Fire_SearingTotem" },
    [3] = { "Tótem Corriente de sanación", t - 40, 60, I .. "INV_Spear_04" },
  }
  NS.UpdateTotems()
end

----------------------------------------------------------------------
-- Eventos y comando
----------------------------------------------------------------------
local ev = CreateFrame("Frame")
NS.SafeEvents(ev, { "PLAYER_LOGIN", "PLAYER_TOTEM_UPDATE", "PLAYER_ENTERING_WORLD" })
ev:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    if not IsShaman() then self:UnregisterAllEvents(); return end
    Build()
  end
  NS.UpdateTotems()
end)

-- /piolin totems [centrar]
function NS.TotemSlash(msg)
  local arg = msg:match("^totems%s*(%a*)$") or msg:match("^tótems%s*(%a*)$")
  if not arg then return false end
  if not IsShaman() then Print("los temporizadores de tótems son solo para chamanes."); return true end
  if not bar then Build() end
  if arg == "centrar" then
    DB().totemPos = nil
    Place()
    Print("barra de tótems de vuelta a su lugar.")
  end
  NS.TotemPreview()
  if DB().noTotems then Print("los temporizadores están apagados en las opciones; esto es solo una muestra.") end
  return true
end
