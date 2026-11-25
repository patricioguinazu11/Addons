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
  arrow.title = arrow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  arrow.title:SetPoint("TOP", arrow, "BOTTOM", 0, -2)
  arrow.dist = arrow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  arrow.dist:SetPoint("TOP", arrow.title, "BOTTOM", 0, -2)
  arrow:SetScript("OnClick", function() NS.ClearWaypoint(true) end)
  arrow:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("Códice de Piolin", 0.85, 0.66, 0.25)
    GameTooltip:AddLine("Arrastrar: mover la flecha", 1, 1, 1)
    GameTooltip:AddLine("Clic derecho: quitarla", 1, 1, 1)
    GameTooltip:Show()
  end)
  arrow:SetScript("OnLeave", GameTooltip_Hide)
  local elapsed = 0
  arrow:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed < 0.05 or not way then return end
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
      NS.ClearWaypoint()
      return
    end
    local target = math.atan2(-east, north)          -- ángulo antihorario desde el norte
    local facing = GetPlayerFacing and GetPlayerFacing() or 0
    self.tex:SetRotation(target - facing)
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
  if arrow then arrow:Hide() end
  if pin then pin:Hide() end
  if C_Map and C_Map.ClearUserWaypoint then pcall(C_Map.ClearUserWaypoint) end
  if manual then Print("flecha quitada.") end
end

function NS.SetWaypoint(map, x, y, title, quiet)
  way = { map = map, x = x / 100, y = y / 100, title = title }
  DB().way = { map, x, y, title }
  if not arrow then BuildArrow() end
  arrow.title:SetText(title)
  arrow:SetShown(not DB().noArrow)
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
  L.bar = CreateFrame("StatusBar", nil, card.frame)
  L.bar:SetSize(H.CW - 28, 12)
  L.bar:SetPoint("TOPLEFT", 14, card.y)
  L.bar:SetStatusBarTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")
  L.bar:SetStatusBarColor(1, 0.82, 0)
  L.bar:SetMinMaxValues(0, 20)
  local bb = L.bar:CreateTexture(nil, "BACKGROUND"); bb:SetAllPoints(); bb:SetColorTexture(0, 0, 0, 0.55)
  card.y = card.y - 20
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
}

local panel, category
local function BuildPanel()
  panel = CreateFrame("Frame", "PiolinCodexOptions")
  panel.name = "Códice de Piolin"
  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Códice de Piolin")
  local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetText("Tu guía de Enano Chamán Mejora. Prendé o apagá cada función.")
  local y = -64
  panel.checks = {}
  for _, o in ipairs(OPTIONS) do
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 16, y)
    local lab = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lab:SetPoint("LEFT", cb, "RIGHT", 4, 6)
    lab:SetText(o.t)
    local d = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    d:SetPoint("TOPLEFT", lab, "BOTTOMLEFT", 0, -2)
    d:SetText(o.d)
    cb.opt = o
    cb:SetScript("OnClick", function(self)
      local v = self:GetChecked() and true or false
      if o.inv then v = not v end
      DB()[o.key] = v or nil
      if o.key == "hideMinimap" and NS.minimapButton then NS.minimapButton:SetShown(not DB().hideMinimap) end
      if o.key == "noArrow" and arrow and way then arrow:SetShown(not DB().noArrow) end
    end)
    table.insert(panel.checks, cb)
    y = y - 31
  end

  -- tecla
  local kt = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  kt:SetPoint("TOPLEFT", 380, -64)
  kt:SetText("Tecla para abrir el Códice")
  local kb = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  kb:SetSize(180, 24)
  kb:SetPoint("TOPLEFT", kt, "BOTTOMLEFT", 0, -8)
  local khint = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  khint:SetPoint("TOPLEFT", kb, "BOTTOMLEFT", 0, -4)
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
  local kclear = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  kclear:SetSize(90, 24)
  kclear:SetPoint("LEFT", kb, "RIGHT", 6, 0)
  kclear:SetText("Quitar")
  kclear:SetScript("OnClick", function()
    local old = CurrentKey()
    if old and not (InCombatLockdown and InCombatLockdown()) then SetBinding(old); SaveBindings(GetCurrentBindingSet()); Print("tecla quitada.") end
    paintKey()
  end)

  -- acciones
  local at = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  at:SetPoint("TOPLEFT", 380, -190)
  at:SetText("Acciones")
  local function action(text, y2, fn)
    local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    b:SetSize(180, 24)
    b:SetPoint("TOPLEFT", 380, y2)
    b:SetText(text)
    b:SetScript("OnClick", fn)
    return b
  end
  action("Abrir el Códice", -214, function() NS.Toggle() end)
  action("Crear macros", -244, function() NS.CreateMacros() end)
  action("Quitar la flecha", -274, function() NS.ClearWaypoint(true) end)
  action("Probar un aviso", -304, function() NS.Alert(nil, "Así se ven los avisos del Códice", "Interface\\Icons\\Spell_Nature_LightningShield", 1, 0.82, 0.25) end)
  StaticPopupDialogs["PIOLINCODEX_RESET"] = {
    text = "¿Borrar todas las tildes del Códice? No se puede deshacer.",
    button1 = "Borrar", button2 = "Cancelar",
    OnAccept = function() PiolinCodexDB.checks = {}; Print("tildes borradas. Escribí /reload para ver el cambio.") end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
  }
  action("Borrar todas las tildes", -344, function() StaticPopup_Show("PIOLINCODEX_RESET") end)

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
