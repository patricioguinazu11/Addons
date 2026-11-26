-- Códice de Piolin: panel de opciones, flecha y pines en el mapa, registro de misiones y tecla
local ADDON, NS = ...
local C = NS.colors

local function DB() return PiolinCodexDB end
local function Print(m) NS.Print(m) end

----------------------------------------------------------------------
-- 1. Tecla para abrir (Bindings.xml usa estas variables)
----------------------------------------------------------------------
BINDING_HEADER_PIOLINCODEX = "Códice de Piolin"
BINDING_NAME_PIOLINCODEX_TOGGLE = "Abrir o cerrar el Códice"
BINDING_NAME_PIOLINCODEX_CLEARWAY = "Quitar la flecha del Códice"
function PiolinCodex_Toggle() NS.Toggle() end
function PiolinCodex_ClearWay() if NS.ClearWaypoint then NS.ClearWaypoint(true) end end

local function CurrentKey()
  local k = GetBindingKey and GetBindingKey("PIOLINCODEX_TOGGLE")
  return k
end

----------------------------------------------------------------------
-- 2. Flecha y pines en el mapa (sin TomTom)
----------------------------------------------------------------------
local way      -- { map, x, y, title } con x, y de 0 a 1
local arrow, pin

local function BuildArrow()
  arrow = CreateFrame("Button", "PiolinCodexArrow", UIParent)
  arrow:SetSize(56, 56)
  arrow:SetPoint("TOP", 0, -110)
  arrow:SetMovable(true)
  arrow:EnableMouse(true)
  arrow:RegisterForDrag("LeftButton")
  arrow:RegisterForClicks("RightButtonUp")
  arrow:SetScript("OnDragStart", arrow.StartMoving)
  arrow:SetScript("OnDragStop", arrow.StopMovingOrSizing)
  arrow:SetClampedToScreen(true)
  arrow.tex = arrow:CreateTexture(nil, "ARTWORK")
  arrow.tex:SetAllPoints()
  arrow.tex:SetTexture("Interface\\Minimap\\MinimapArrow")
  local S = NS.Style
  arrow.title = arrow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  arrow.title:SetPoint("TOP", arrow, "BOTTOM", 0, -4)
  arrow.dist = arrow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  arrow.dist:SetPoint("TOP", arrow.title, "BOTTOM", 0, -2)
  if S then
    S.Font(arrow.title, 12.5, S.K.title, true); arrow.title:SetShadowOffset(1, -1); arrow.title:SetShadowColor(0, 0, 0, 1)
    S.Font(arrow.dist, 11, S.K.parch); arrow.dist:SetShadowColor(0, 0, 0, 1)
  end
  arrow:SetScript("OnClick", function() NS.ClearWaypoint(true) end)
  arrow:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("Códice de Piolin", 0.85, 0.66, 0.25)
    GameTooltip:AddLine("Arrastrar: mover la flecha", 1, 1, 1)
    GameTooltip:AddLine("Clic derecho: quitarla", 1, 1, 1)
    GameTooltip:Show()
  end)
  arrow:SetScript("OnLeave", GameTooltip_Hide)
  local elapsed, arriving = 0, false
  arrow:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed < 0.05 or not way or arriving then return end
    elapsed = 0
    local pos = C_Map and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(way.map, "player")
    local px, py
    if pos then px, py = pos:GetXY() end
    if not px or (px == 0 and py == 0) then
      self.tex:SetAlpha(0.25)
      self.tex:SetRotation(0)
      local info = C_Map.GetMapInfo and C_Map.GetMapInfo(way.map)
      self.dist:SetText("está en " .. (info and info.name or "otra zona"))
      return
    end
    self.tex:SetAlpha(1)
    local w, h = 1000, 667
    if C_Map.GetMapWorldSize then
      local ww, hh = C_Map.GetMapWorldSize(way.map)
      if ww and ww > 0 then w, h = ww, hh end
    end
    local east = (way.x - px) * w
    local north = (py - way.y) * h
    local yards = math.sqrt(east * east + north * north)
    if yards < 8 then
      Print("llegaste a " .. way.title .. ".")
      NS.Sound("arrive")
      if NS.Vanish and NS.Tween and not DB().noAnim then
        -- llegada: la flecha crece y se desvanece antes de borrarse
        arriving = true
        NS.Tween(0.45, function(p) self:SetScale(1 + 0.45 * p) end, 0, function() self:SetScale(1) end, NS.OutCubic)
        NS.Vanish(self, 0, 0, 0.45, function() arriving = false; NS.ClearWaypoint() end)
      else
        NS.ClearWaypoint()
      end
      return
    end
    local target = math.atan2(-east, north)          -- ángulo antihorario desde el norte
    local facing = GetPlayerFacing and GetPlayerFacing() or 0
    self.tex:SetRotation(target - facing)
    -- cerca del destino (menos de 30 m) la flecha late suave
    if yards < 30 and not DB().noAnim then
      self.tex:SetAlpha(0.6 + 0.4 * (0.5 + 0.5 * math.sin(GetTime() * 7)))
    end
    self.dist:SetText(math.floor(yards + 0.5) .. " m")
  end)
  arrow:Hide()
end

local function UpdatePin()
  if not WorldMapFrame or not WorldMapFrame.ScrollContainer then return end
  local canvas = WorldMapFrame.ScrollContainer.Child
  if not canvas then return end
  if not pin then
    pin = CreateFrame("Button", nil, canvas)
    pin:SetSize(32, 32)
    pin:SetFrameStrata("HIGH")
    pin.tex = pin:CreateTexture(nil, "OVERLAY")
    pin.tex:SetAllPoints()
    pin.tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1") -- la estrella amarilla de las marcas de banda
    pin.label = pin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pin.label:SetPoint("TOP", pin, "BOTTOM", 0, 0)
    pin:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine(way and way.title or "", 0.85, 0.66, 0.25)
      GameTooltip:AddLine("Marcado por el Códice", 1, 1, 1)
      GameTooltip:AddLine("Clic: quitar la marca", 0.7, 0.7, 0.7)
      GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", GameTooltip_Hide)
    pin:SetScript("OnClick", function() NS.ClearWaypoint(true) end)
  end
  local shownMap = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
  if way and shownMap == way.map then
    local w, h = canvas:GetWidth(), canvas:GetHeight()
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", canvas, "TOPLEFT", way.x * w, -way.y * h)
    pin.label:SetText(way.title)
    pin:SetScale(1 / math.max(0.4, canvas:GetScale() or 1))
    pin:Show()
  else
    pin:Hide()
  end
end

function NS.ClearWaypoint(manual)
  way = nil
  DB().way = nil
  if arrow and arrow:IsShown() and manual and NS.Vanish then NS.Vanish(arrow, 0, 8, 0.25)
  elseif arrow then arrow:Hide() end
  if pin then pin:Hide() end
  if C_Map and C_Map.ClearUserWaypoint then pcall(C_Map.ClearUserWaypoint) end
  if manual then Print("flecha quitada.") end
end

function NS.SetWaypoint(map, x, y, title, quiet)
  way = { map = map, x = x / 100, y = y / 100, title = title }
  DB().way = { map, x, y, title }
  if not arrow then BuildArrow() end
  arrow.title:SetText(title)
  local wasShown = arrow:IsShown()
  arrow:SetShown(not DB().noArrow)
  if not wasShown and arrow:IsShown() and NS.Appear and NS.Tween and not DB().noAnim then
    -- aparece bajando con fundido y un pequeño crecimiento
    NS.Appear(arrow, 0, 10, 0.3)
    arrow:SetScale(0.8)
    NS.Tween(0.35, function(p) arrow:SetScale(0.8 + 0.2 * p) end, 0, function() arrow:SetScale(1) end, NS.OutCubic)
  end
  UpdatePin()
  -- pin nativo del mapa, si el cliente lo tiene
  if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
    pcall(function()
      if not C_Map.CanSetUserWaypointOnMap or C_Map.CanSetUserWaypointOnMap(map) then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x / 100, y / 100))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
      end
    end)
  end
  if not quiet then Print("marca puesta: " .. C.H .. title .. C.E .. " (" .. x .. ", " .. y .. "). Mirá la flecha arriba o el mapa (M).") end
end

-- El botón "Ir" usa TomTom si está; si no, la flecha propia
function NS.GoTo(wp)
  if TomTom and TomTom.AddWaypoint and not DB().ownArrow then
    TomTom:AddWaypoint(wp[1], wp[2] / 100, wp[3] / 100, { title = wp[4], persistent = false, minimap = true, world = true })
    Print("flecha de TomTom puesta hacia " .. wp[4] .. ".")
  else
    NS.SetWaypoint(NS.ResolveMap(wp[1], wp[5]), wp[2], wp[3], wp[4])
  end
end

----------------------------------------------------------------------
-- 3. Registro de misiones
----------------------------------------------------------------------
local questById = {}     -- [questID] = { title, level, complete, index }
local guideQuest = {}    -- [questID] = id de la tarea de la guía
local function IndexGuide()
  wipe(guideQuest)
  for id, q in pairs(NS.AUTO.quest) do guideQuest[q] = id end
end

local function GreenRange()
  return (GetQuestGreenRange and GetQuestGreenRange()) or 8
end

local lastComplete = {}
local function ScanLog(announce)
  wipe(questById)
  local total, ready, gray, inGuide = 0, {}, {}, {}
  local level = UnitLevel("player") or 1
  local n = GetNumQuestLogEntries and GetNumQuestLogEntries() or 0
  for i = 1, n do
    local title, qlevel, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(i)
    if title and not isHeader then
      total = total + 1
      local done = isComplete == 1 or isComplete == true
      questById[questID or title] = { title = title, level = qlevel, complete = done, index = i }
      if done then table.insert(ready, title) end
      if qlevel and qlevel > 0 and qlevel < level - GreenRange() then table.insert(gray, title .. " (" .. qlevel .. ")") end
      if questID and guideQuest[questID] then table.insert(inGuide, title) end
      if questID and announce and done and not lastComplete[questID] and not DB().noQuestLog then
        NS.Alert("q" .. questID, "Lista para entregar: " .. title, "Interface\\GossipFrame\\ActiveQuestIcon", 1, 0.82, 0.25, 5)
      end
      if questID then lastComplete[questID] = done end
    end
  end
  NS.questLog = { total = total, ready = ready, gray = gray, inGuide = inGuide }
  return NS.questLog
end

function NS.QuestStatus(questID)
  local q = questById[questID]
  if not q then return nil end
  return q.complete and "ready" or "active"
end

local function PaintRows()
  for id, questID in pairs(NS.AUTO.quest) do
    local row = NS.cbById[id]
    if row and row.qtext then
      local st = NS.QuestStatus(questID)
      if st == "ready" and not DB().checks[id] then row.qtext:SetText("|cff7fd16a¡entregar!|r")
      elseif st == "active" and not DB().checks[id] then row.qtext:SetText("|cff69ccf0en tu registro|r")
      else row.qtext:SetText("") end
    end
  end
end

-- Tarjeta en la pestaña Misiones
NS.PageExtras = NS.PageExtras or {}
NS.PageExtras.misiones = function(P, H)
  local K = H.K
  local card = P:Card("Tu registro de misiones", "Interface\\GossipFrame\\AvailableQuestIcon", K.gold)
  local L = {}
  L.count = card:Text("", 13, K.parch)
  L.bar = H.Bar(card.frame, H.CW - 28, 4, K.accent or K.water)
  L.bar:SetPoint("TOPLEFT", 14, card.y - 2)
  L.bar.text:Hide()
  L.bar:SetMinMaxValues(0, 20)
  card.y = card.y - 16
  L.ready = card:Text(" \n ", 11.5, K.ok)
  L.gray = card:Text(" \n ", 11.5, K.dim)
  L.guide = card:Text(" ", 11.5, K.water)
  for _, fs in ipairs({ L.ready, L.gray, L.guide }) do if fs.SetMaxLines then fs:SetMaxLines(fs == L.guide and 1 or 2) end end
  card:Text("Las misiones de la guía muestran “en tu registro” o “¡entregar!” al costado.", 10, K.dim)
  card:Finish()
  table.insert(P.refreshers, function()
    local q = NS.questLog or ScanLog(false)
    L.count:SetText("Misiones aceptadas: |cffffd96a" .. q.total .. "|r de 20")
    L.bar:SetValue(q.total)
    L.ready:SetText(#q.ready > 0 and ("Listas para entregar: " .. table.concat(q.ready, ", ")) or "Ninguna lista para entregar todavía.")
    L.gray:SetText(#q.gray > 0 and ("|cff9d9d9dGrises (casi no dan experiencia), conviene abandonarlas:|r " .. table.concat(q.gray, ", ")) or "|cff9d9d9dNo tenés misiones grises.|r")
    L.guide:SetText(#q.inGuide > 0 and ("De tu guía: " .. table.concat(q.inGuide, ", ")) or "Ninguna misión de la guía en tu registro.")
    PaintRows()
  end)
end

----------------------------------------------------------------------
-- 4. Panel de opciones nativo
----------------------------------------------------------------------
local OPTIONS = {
  { key = "noAnim", inv = true, t = "Animaciones del Códice", d = "Elementos al abrir, tildes, logros, nivel, tótems y viento." },
  { key = "noLevelCard", inv = true, t = "Cartel al subir de nivel", d = "Qué subió, punto de talento y qué entrenar en el instructor." },
  { key = "noReminders", inv = true, t = "Avisos de combate y de cebo", d = "Escudo de relámpagos, imbuición y cebo de la caña." },
  { key = "noQuestLog", inv = true, t = "Avisar misiones listas para entregar", d = "Cartel cuando completás los objetivos de una misión." },
  { key = "noSkinTips", inv = true, t = "Pistas de desuello en las bestias", d = "Qué nivel de Desuello pide y si te da puntos." },
  { key = "noAutoTrack", inv = true, t = "Rastrear instructores al entrar a una ciudad", d = "Forjaz, Ventormenta y Darnassus: aparecen en el minimapa." },
  { key = "noGear", inv = true, t = "Comparador de equipo en los tooltips", d = "Mejora o peor para un chamán Mejora." },
  { key = "noPrices", inv = true, t = "Precios en los tooltips", d = "Subasta, vendedor y qué conviene." },
  { key = "noAutoSell", inv = true, t = "Vender la basura sola en el vendedor", d = "Todo lo gris y lo marcado con /piolin basura." },
  { key = "noRepair", inv = true, t = "Reparar solo en el vendedor", d = "Si te alcanza el oro." },
  { key = "noShop", inv = true, t = "Lista de compras en vendedor y subasta", d = "Lo que falta para tu tramo de Peletería." },
  { key = "noSellHelper", inv = true, t = "Ayudante para vender en la subasta", d = "Completa la puja y la compra ya." },
  { key = "noArrow", inv = true, t = "Mostrar la flecha del botón “Ir”", d = "Si la apagás, queda solo el pin en el mapa." },
  { key = "ownArrow", t = "Usar la flecha del Códice aunque tenga TomTom", d = "Por defecto usa TomTom si está instalado." },
  { key = "hideMinimap", inv = true, t = "Botón del rayo en el minimapa", d = "Abre y cierra el Códice." },
  { key = "noMiniStatus", inv = true, t = "Mini estado junto al minimapa", d = "Bolsas libres, durabilidad, piedra de hogar y tienda." },
}

local panel, category
local function BuildPanel()
  panel = CreateFrame("Frame", "PiolinCodexOptions")
  panel.name = "Códice de Piolin"
  local S = NS.Style
  local title = S.Font(panel:CreateFontString(nil, "ARTWORK"), 18, S.K.title, true)
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Códice de Piolin")
  local sub = S.Font(panel:CreateFontString(nil, "ARTWORK"), 11.5, S.K.mute)
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetText("Tu guía de Enano Chamán Mejora. Prendé o apagá cada función.")
  local y = -64
  panel.checks = {}
  for _, o in ipairs(OPTIONS) do
    local cb = S.SkinCheck(CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate"))
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", 14, y)
    local lab = S.Font(panel:CreateFontString(nil, "ARTWORK"), 12.5, S.K.parch)
    lab:SetPoint("LEFT", cb, "RIGHT", 6, 6)
    lab:SetText(o.t)
    local d = S.Font(panel:CreateFontString(nil, "ARTWORK"), 10.5, S.K.dim)
    d:SetPoint("TOPLEFT", lab, "BOTTOMLEFT", 0, -3)
    d:SetText(o.d)
    cb.opt = o
    cb:SetScript("OnClick", function(self)
      local v = self:GetChecked() and true or false
      if o.inv then v = not v end
      DB()[o.key] = v or nil
      if o.key == "hideMinimap" and NS.minimapButton then NS.minimapButton:SetShown(not DB().hideMinimap) end
      if o.key == "noMiniStatus" and NS.ShowMiniStatus then NS.ShowMiniStatus(not DB().noMiniStatus) end
      if o.key == "noArrow" and arrow and way then arrow:SetShown(not DB().noArrow) end
    end)
    table.insert(panel.checks, cb)
    y = y - 31
  end

  -- tecla
  local kt = S.Font(panel:CreateFontString(nil, "ARTWORK"), 13, S.K.title, true)
  kt:SetPoint("TOPLEFT", 380, -64)
  kt:SetText("Tecla para abrir el Códice")
  local kb = S.SkinButton(CreateFrame("Button", nil, panel, "UIPanelButtonTemplate"))
  kb:SetSize(180, 26)
  kb:SetPoint("TOPLEFT", kt, "BOTTOMLEFT", 0, -8)
  local khint = S.Font(panel:CreateFontString(nil, "ARTWORK"), 10.5, S.K.dim)
  khint:SetPoint("TOPLEFT", kb, "BOTTOMLEFT", 0, -6)
  khint:SetWidth(220)
  khint:SetJustifyH("LEFT")
  khint:SetText("Tocá el botón y apretá la tecla o combinación (por ejemplo Shift+C). Esc cancela. También está en Atajos de teclado → AddOns.")
  local function paintKey() kb:SetText(CurrentKey() and ("Tecla: " .. CurrentKey()) or "Elegir tecla") end
  local capture = CreateFrame("Frame", nil, kb)
  capture:SetAllPoints()
  capture:Hide()
  capture:EnableKeyboard(true)
  capture:SetScript("OnKeyDown", function(self, key)
    if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then return end
    self:Hide()
    if key == "ESCAPE" then paintKey(); return end
    if InCombatLockdown and InCombatLockdown() then Print("no se pueden cambiar teclas en combate."); paintKey(); return end
    local combo = (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. key
    local old = CurrentKey()
    if old then SetBinding(old) end
    if SetBinding(combo, "PIOLINCODEX_TOGGLE") then
      SaveBindings(GetCurrentBindingSet())
      Print("tecla " .. C.H .. combo .. C.E .. " asignada al Códice.")
    else
      Print("no se pudo usar esa tecla.")
    end
    paintKey()
  end)
  kb:SetScript("OnClick", function() kb:SetText("Apretá una tecla…"); capture:Show() end)
  local kclear = S.SkinButton(CreateFrame("Button", nil, panel, "UIPanelButtonTemplate"))
  kclear:SetSize(90, 26)
  kclear:SetPoint("LEFT", kb, "RIGHT", 6, 0)
  kclear:SetText("Quitar")
  kclear:SetScript("OnClick", function()
    local old = CurrentKey()
    if old and not (InCombatLockdown and InCombatLockdown()) then SetBinding(old); SaveBindings(GetCurrentBindingSet()); Print("tecla quitada.") end
    paintKey()
  end)

  -- acciones
  local at = S.Font(panel:CreateFontString(nil, "ARTWORK"), 13, S.K.title, true)
  at:SetPoint("TOPLEFT", 380, -190)
  at:SetText("Acciones")
  local function action(text, y2, fn, kind)
    local b = S.SkinButton(CreateFrame("Button", nil, panel, "UIPanelButtonTemplate"), kind)
    b:SetSize(180, 26)
    b:SetPoint("TOPLEFT", 380, y2)
    b:SetText(text)
    b:SetScript("OnClick", fn)
    return b
  end
  action("Abrir el Códice", -214, function() NS.Toggle() end, "primary")
  action("Crear macros", -244, function() NS.CreateMacros() end)
  action("Quitar la flecha", -274, function() NS.ClearWaypoint(true) end)
  action("Probar un aviso", -304, function() NS.Alert(nil, "Así se ven los avisos del Códice", "Interface\\Icons\\Spell_Nature_LightningShield", 1, 0.82, 0.25) end)
  StaticPopupDialogs["PIOLINCODEX_RESET"] = {
    text = "¿Borrar todas las tildes del Códice? No se puede deshacer.",
    button1 = "Borrar", button2 = "Cancelar",
    OnAccept = function() PiolinCodexDB.checks = {}; Print("tildes borradas. Escribí /reload para ver el cambio.") end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
  }
  action("Borrar todas las tildes", -344, function() StaticPopup_Show("PIOLINCODEX_RESET") end, "danger")

  panel:SetScript("OnShow", function()
    for _, cb in ipairs(panel.checks) do
      local v = DB()[cb.opt.key] and true or false
      if cb.opt.inv then v = not v end
      cb:SetChecked(v)
    end
    paintKey()
  end)

  if Settings and Settings.RegisterCanvasLayoutCategory then
    category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end
  if NS.BuildSoundPanel then NS.BuildSoundPanel(category, panel) end
end

function NS.OpenOptions()
  if not panel then BuildPanel() end
  if Settings and Settings.OpenToCategory and category then
    Settings.OpenToCategory(category.GetID and category:GetID() or category.ID)
  elseif InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)
  end
end

----------------------------------------------------------------------
-- Mini estado junto al minimapa: bolsas libres, durabilidad, piedra de hogar y tienda
----------------------------------------------------------------------
local HEARTHSTONE = 6948
local mini

local function FreeBagSlots()
  local CC = C_Container
  local free, total = 0, 0
  for bag = 0, 4 do
    local n = (CC and CC.GetContainerNumSlots or GetContainerNumSlots)
    local f = (CC and CC.GetContainerNumFreeSlots or GetContainerNumFreeSlots)
    local slots = n and n(bag) or 0
    local fr = f and f(bag) or 0
    if type(fr) == "number" then free = free + fr end
    if type(slots) == "number" then total = total + slots end
  end
  return free, total
end

local function HearthLeft()
  local getCD = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
  if not getCD then return nil end
  local ok, start, dur = pcall(getCD, HEARTHSTONE)
  if not ok or not start or not dur or dur == 0 or start == 0 then return 0 end
  return math.max(0, start + dur - GetTime())
end

local function Clock(sec)
  if sec >= 3600 then return math.floor(sec / 3600) .. "h" end
  if sec >= 60 then return math.ceil(sec / 60) .. "m" end
  return math.ceil(sec) .. "s"
end

local function BuildMiniStatus()
  local S = NS.Style
  if mini or not S then return end
  mini = CreateFrame("Frame", "PiolinCodexMiniStatus", UIParent)
  mini:SetSize(4 * 42 + 10, 52)
  mini:SetFrameStrata("MEDIUM")
  local pos = DB().miniPos
  if pos then mini:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
  else mini:SetPoint("TOP", Minimap, "BOTTOM", 0, -30) end
  -- fondo plano con borde fino, como el resto del Códice
  local bo = mini:CreateTexture(nil, "BACKGROUND", nil, -8); bo:SetAllPoints(); bo:SetColorTexture(S.C3(S.K.edge))
  local bg = mini:CreateTexture(nil, "BACKGROUND", nil, -7); bg:SetPoint("TOPLEFT", 1, -1); bg:SetPoint("BOTTOMRIGHT", -1, 1)
  bg:SetColorTexture(S.K.bg[1], S.K.bg[2], S.K.bg[3], 0.92)
  -- se mueve arrastrando y recuerda dónde quedó
  mini:SetMovable(true); mini:EnableMouse(true); mini:SetClampedToScreen(true)
  mini:RegisterForDrag("LeftButton")
  mini:SetScript("OnDragStart", mini.StartMoving)
  mini:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint(1)
    if p then DB().miniPos = { p, rp, x, y } end
  end)
  mini.items = {}
  local defs = {
    { key = "bags", icon = "Interface\\Icons\\INV_Misc_Bag_10", title = "Bolsas" },
    { key = "dur", icon = "Interface\\Icons\\Trade_BlackSmithing", title = "Durabilidad" },
    { key = "hearth", icon = "Interface\\Icons\\INV_Misc_Rune_01", title = "Piedra de hogar" },
    { key = "tent", icon = "Interface\\Icons\\INV_Misc_Bag_09", title = "Tienda de campaña" },
  }
  for i, d in ipairs(defs) do
    local b = CreateFrame("Frame", nil, mini)
    b:SetSize(40, 44)
    b:SetPoint("TOPLEFT", 6 + (i - 1) * 42, -4)
    b.icon = S.Framed(b, d.icon, 24)
    b.icon:SetPoint("TOP", 0, -2)
    b.text = S.Font(b:CreateFontString(nil, "OVERLAY"), 10, S.K.title, true)
    b.text:SetPoint("TOP", b.icon, "BOTTOM", 0, -3)
    b.text:SetJustifyH("CENTER")
    b:EnableMouse(true)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
      GameTooltip:AddLine(d.title, S.C3(S.K.title))
      if self.tip then GameTooltip:AddLine(self.tip, 1, 1, 1, true) end
      GameTooltip:AddLine("Arrastrá el recuadro para moverlo.", 0.55, 0.6, 0.68)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    -- arrastrar desde un ícono también mueve el recuadro
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart", function() mini:StartMoving() end)
    b:SetScript("OnDragStop", function() mini:GetScript("OnDragStop")(mini) end)
    mini.items[d.key] = b
  end
  mini:Hide()
end

-- Colores: verde = listo, gris = normal, naranja = ojo, rojo = urgente
local function Paint(b, text, color, tip, dim)
  local S = NS.Style
  b.text:SetText(text)
  b.text:SetTextColor(S.C3(color))
  b.tip = tip
  b.icon:SetDesaturated(dim and true or false)
  b.icon:SetAlpha(dim and 0.55 or 1)
end

function NS.RefreshMiniStatus()
  if not mini then return end
  local K = NS.Style.K
  local free, total = FreeBagSlots()
  Paint(mini.items.bags, tostring(free), free <= 2 and K.bad or (free <= 6 and K.warn or K.title),
    free .. " espacios libres de " .. total .. (free <= 2 and ". Vendé basura antes de seguir." or "."))
  local dur = NS.Durability and NS.Durability() or 100
  Paint(mini.items.dur, dur .. "%", dur <= 25 and K.bad or (dur <= 50 and K.warn or K.title),
    "La pieza más gastada está al " .. dur .. "%." .. (dur <= 50 and " Pasá por un herrero." or ""))
  local h = HearthLeft()
  if h == nil then Paint(mini.items.hearth, "—", K.dim, "El juego no informa el tiempo de la piedra.", true)
  elseif h <= 0 then Paint(mini.items.hearth, "lista", K.ok, "La piedra de hogar está lista para usar.")
  else Paint(mini.items.hearth, Clock(h), K.mute, "Lista en " .. Clock(h) .. ".", true) end
  local at = DB().tentAt
  if not at then Paint(mini.items.tent, "—", K.dim, "Todavía no pusiste la tienda en esta cuenta.", true)
  else
    local left = 3600 - (time() - at)
    if left <= 0 then Paint(mini.items.tent, "lista", K.ok, "Podés volver a poner la tienda de campaña.")
    else Paint(mini.items.tent, Clock(left), K.mute, "Disponible en " .. Clock(left) .. ".", true) end
  end
end

function NS.ShowMiniStatus(show)
  BuildMiniStatus()
  if not mini then return end
  if show and not mini:IsShown() then
    mini:Show(); NS.RefreshMiniStatus()
    if NS.Appear then NS.Appear(mini, 0, 8, 0.3) end
  elseif not show then
    mini:Hide()
  end
end

local miniEv = CreateFrame("Frame")
NS.SafeEvents(miniEv, { "PLAYER_LOGIN", "BAG_UPDATE_DELAYED", "UPDATE_INVENTORY_DURABILITY", "BAG_UPDATE_COOLDOWN", "PLAYER_ENTERING_WORLD" })
miniEv:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    NS.ShowMiniStatus(not DB().noMiniStatus)
    -- los tiempos de la piedra y la tienda se actualizan solos cada pocos segundos
    C_Timer.NewTicker(5, function() if mini and mini:IsShown() then NS.RefreshMiniStatus() end end)
  else
    NS.RefreshMiniStatus()
  end
end)

----------------------------------------------------------------------
-- Eventos y comandos
----------------------------------------------------------------------
local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "ZONE_CHANGED_NEW_AREA" }) do pcall(ev.RegisterEvent, ev, e) end
local pending = false
ev:SetScript("OnEvent", function(self, event, a1, a2)
  if event == "PLAYER_LOGIN" then
    IndexGuide()
    BuildPanel()
    ScanLog(false)
    if WorldMapFrame then
      WorldMapFrame:HookScript("OnShow", UpdatePin)
      if WorldMapFrame.OnMapChanged then hooksecurefunc(WorldMapFrame, "OnMapChanged", UpdatePin) end
    end
    local w = DB().way
    if w then NS.SetWaypoint(w[1], w[2], w[3], w[4], true) end
  elseif event == "QUEST_LOG_UPDATE" then
    if pending then return end
    pending = true
    C_Timer.After(0.5, function()
      pending = false
      ScanLog(true)
      if NS.frame and NS.frame:IsShown() then NS.RefreshLive() else PaintRows() end
    end)
  elseif event == "QUEST_ACCEPTED" then
    local questID = a2 or a1
    C_Timer.After(0.3, function()
      if not DB().noQuestLog and questID and guideQuest[questID] then
        local id = guideQuest[questID]
        Print("esta misión es parte de tu guía " .. C.G .. "(Misiones)" .. C.E .. ". Cuando la entregues se tilda sola.")
      end
    end)
  elseif event == "ZONE_CHANGED_NEW_AREA" then
    UpdatePin()
  end
end)

local prev = NS.TradeSlash
NS.TradeSlash = function(msg)
  if msg == "opciones" or msg == "config" then
    NS.OpenOptions()
    return true
  elseif msg:find("^ir") then
    local x, y = msg:match("^ir%s+([%d%.]+)[%s,]+([%d%.]+)")
    if x then
      local map = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
      if map then NS.SetWaypoint(map, tonumber(x), tonumber(y), "Punto " .. x .. ", " .. y) end
    else
      NS.ClearWaypoint(true)
    end
    return true
  elseif msg == "misiones" then
    local q = ScanLog(false)
    Print("tenés " .. q.total .. " de 20 misiones. Listas para entregar: " .. #q.ready .. ". Grises: " .. #q.gray .. ".")
    return true
  end
  return prev and prev(msg) or false
end
