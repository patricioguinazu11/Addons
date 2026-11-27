-- Códice de Piolin: panel de opciones, flecha y pines en el mapa, registro de misiones y tecla
local ADDON, NS = ...
local C = NS.colors

local function DB() return NS.db end
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
  arrow:SetScript("OnDragStart", NS.DragStart)
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
    GameTooltip:AddLine(NS.db.locked and "Para moverla, destrabá los marcos en la configuración" or "Arrastrar: mover la flecha", 1, 1, 1)
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
    local set = row and rawget(row, "SetQuestState")
    if set then
      local st = not DB().checks[id] and NS.QuestStatus(questID) or nil
      set(row, st)
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
  card:Text("Las misiones de la guía muestran “en tu registro” o “¡entregar!” en lugar de su etiqueta.", 10, K.dim)
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
-- 4. Configuración (Opciones › AddOns, el engranaje de la ventana y /piolin config)
-- Secciones a la izquierda; cada opción con una descripción corta; "Restablecer" por sección y general.
-- Las opciones "no..." son interruptores invertidos: nil = prendido (ver DB.lua).
----------------------------------------------------------------------
local L = NS.L
local SECTIONS = {
  { key = "general", t = L["General"], items = {
    { kind = "check", key = "locked", t = L["Bloquear marcos"], d = L["Destrabalos para moverlos; vale para todos los del Códice."] },
    { kind = "slider", key = "winScale", t = L["Escala de la ventana"], min = 0.7, max = 1.3 },
    { kind = "select", key = "font", t = L["Letra"], d = L["Se aplica al recargar la interfaz (/reload)."], choices = { { "inter", "Inter" }, { "game", L["La del juego"] } } },
    { kind = "check", key = "hideMinimap", inv = true, t = "Botón del rayo en el minimapa", d = "Abre y cierra el Códice." },
    { kind = "check", key = "noMiniStatus", inv = true, t = "Mini estado junto al minimapa", d = "Bolsas libres, durabilidad, piedra de hogar y tienda." },
    { kind = "check", key = "noLevelCard", inv = true, t = "Cartel al subir de nivel", d = "Qué subió, punto de talento y qué entrenar." },
    { kind = "check", key = "noAnim", inv = true, t = "Animaciones del Códice", d = "Al abrir, al tildar, al subir de nivel y al cambiar de pestaña." },
    { kind = "key" },
  }},
  { key = "combate", t = L["Combate"], items = {
    { kind = "check", key = "noTotems", inv = true, t = L["HUD de combate"], d = L["Escudo, imbuición y tótems con su tiempo."] },
    { kind = "select", key = "hudMode", t = L["Mostrar el HUD"], choices = { { "always", L["Siempre"] }, { "combat", L["En combate"] }, { "hidden", L["Oculto"] } } },
    { kind = "slider", key = "hudScale", t = L["Escala del HUD"], min = 0.6, max = 1.6 },
    { kind = "check", key = "noReminders", inv = true, t = "Marcar lo que falta antes de pelear", d = "Escudo e imbuición al seleccionar un enemigo, y el cebo de la caña." },
  }},
  { key = "mapa", t = L["Misiones y mapa"], items = {
    { kind = "check", key = "noQuestLog", inv = true, t = "Avisar misiones listas para entregar", d = "Cartel cuando completás los objetivos de una misión." },
    { kind = "check", key = "noArrow", inv = true, t = "Flecha del botón “Ir”", d = "Si la apagás, queda solo el pin en el mapa." },
    { kind = "check", key = "ownArrow", t = "Usar la flecha del Códice aunque tenga TomTom", d = "Por defecto usa TomTom si está instalado." },
    { kind = "check", key = "noAutoTrack", inv = true, t = "Rastrear instructores al entrar a una ciudad", d = "Aparecen en el minimapa en Forjaz, Ventormenta y Darnassus." },
  }},
  { key = "comercio", t = L["Comercio"], items = {
    { kind = "check", key = "noPrices", inv = true, t = "Precios en los tooltips", d = "Subasta, vendedor y qué conviene." },
    { kind = "check", key = "noGear", inv = true, t = "Comparar equipo en los tooltips", d = "Mejora o peor para un chamán Mejora." },
    { kind = "check", key = "noAutoSell", inv = true, t = "Vender la basura sola en el vendedor", d = "Todo lo gris y lo marcado con /piolin basura." },
    { kind = "check", key = "noRepair", inv = true, t = "Reparar solo en el vendedor", d = "Si te alcanza el oro." },
    { kind = "check", key = "noShop", inv = true, t = "Lista de compras en vendedor y subasta", d = "Lo que falta para tu tramo de Peletería." },
    { kind = "check", key = "noSellHelper", inv = true, t = "Ayudante para vender en la subasta", d = "Completa la puja y la compra ya." },
  }},
  { key = "oficios", t = L["Oficios y pesca"], items = {
    { kind = "check", key = "noMatUse", inv = true, t = "Para qué sirve cada material", d = "En qué tramo de Peletería lo usás y cuánto tenés." },
    { kind = "check", key = "noSkinTips", inv = true, t = "Pistas de desuello en las bestias", d = "Qué nivel de Desuello pide y si te da puntos." },
    { kind = "check", key = "noFishClick", inv = true, t = "Pescar con doble clic derecho", d = "Con la caña equipada y fuera de combate." },
  }},
  { key = "sonido", t = L["Sonido"], items = {
    { kind = "check", key = "noSound", inv = true, t = "Sonidos del Códice", d = "Avisos, tildes y pestañas, con el canal y el volumen que elijas." },
    { kind = "button", t = L["Opciones de sonido"], fn = function() if NS.OpenSoundOptions then NS.OpenSoundOptions() end end },
  }},
  { key = "perfil", t = L["Perfil"], items = { { kind = "profile" } } },
}
NS.OPTION_SECTIONS = SECTIONS

-- Lo que hay que mover en pantalla después de cambiar una opción
function NS.ApplySettings()
  if NS.minimapButton then NS.minimapButton:SetShown(not DB().hideMinimap) end
  if NS.ShowMiniStatus then NS.ShowMiniStatus(not DB().noMiniStatus) end
  if arrow and way then arrow:SetShown(not DB().noArrow) end
  if NS.UpdateHUD then NS.UpdateHUD() end
  if NS.ApplyWindowScale then NS.ApplyWindowScale() end
end

local function ResetSection(sec)
  local keys = {}
  for _, it in ipairs(sec.items) do if it.key then keys[#keys + 1] = it.key end end
  NS.ResetKeys(keys)
end

local panel, category
local function BuildPanel()
  panel = CreateFrame("Frame", "PiolinCodexOptions")
  panel.name = "Códice de Piolin"
  local S = NS.Style
  local K = S.K
  local title = S.Font(panel:CreateFontString(nil, "ARTWORK"), 18, K.title, true)
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Códice de Piolin")
  local sub = S.Font(panel:CreateFontString(nil, "ARTWORK"), 10.5, K.mute)
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetText("/piolin config  ·  " .. NS.CharKey())
  panel.checks = {}

  -- columna de secciones
  local nav, pages, current = {}, {}, 1
  local function show(i)
    current = i
    for j, b in ipairs(nav) do
      local on = j == i
      b.sel:SetShown(on); b.bar:SetShown(on)
      b.label:SetTextColor(S.C3(on and K.title or K.mute))
      pages[j]:SetShown(on)
    end
    if pages[i].refresh then pages[i].refresh() end
  end
  for i, sec in ipairs(SECTIONS) do
    local b = CreateFrame("Button", nil, panel)
    b:SetSize(150, 26)
    b:SetPoint("TOPLEFT", 12, -64 - (i - 1) * 26)
    b.sel = b:CreateTexture(nil, "BACKGROUND"); b.sel:SetAllPoints(); b.sel:SetColorTexture(S.C3(K.card))
    b.bar = b:CreateTexture(nil, "ARTWORK"); b.bar:SetPoint("TOPLEFT"); b.bar:SetPoint("BOTTOMLEFT"); b.bar:SetWidth(2); b.bar:SetColorTexture(S.C3(K.accent))
    local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.05)
    b.label = S.Font(b:CreateFontString(nil, "ARTWORK"), 12, K.mute)
    b.label:SetPoint("LEFT", 12, 0)
    b.label:SetText(sec.t)
    b:SetScript("OnClick", function() show(i) end)
    nav[i] = b
  end
  local vline = panel:CreateTexture(nil, "ARTWORK")
  vline:SetPoint("TOPLEFT", 172, -60); vline:SetPoint("BOTTOMLEFT", 172, 52); vline:SetWidth(1)
  vline:SetColorTexture(S.C3(K.line))

  -- páginas
  local X = 192
  for i, sec in ipairs(SECTIONS) do
    local pg = CreateFrame("Frame", nil, panel)
    pg:SetPoint("TOPLEFT", X, -60); pg:SetPoint("BOTTOMRIGHT", -16, 52)
    pg:Hide()
    local h = S.Font(pg:CreateFontString(nil, "ARTWORK"), 13, K.title, true)
    h:SetPoint("TOPLEFT", 0, -4)
    h:SetText(sec.t)
    local y = -32
    local painters = {}
    for _, it in ipairs(sec.items) do
      if it.kind == "check" then
        local cb = S.SkinCheck(CreateFrame("CheckButton", nil, pg, "UICheckButtonTemplate"))
        cb:SetSize(22, 22)
        cb:SetPoint("TOPLEFT", -4, y)
        table.insert(panel.checks, cb)
        local lab = S.Font(pg:CreateFontString(nil, "ARTWORK"), 12, K.parch)
        lab:SetPoint("LEFT", cb, "RIGHT", 6, 6)
        lab:SetText(it.t)
        local d = S.Font(pg:CreateFontString(nil, "ARTWORK"), 10.5, K.dim)
        d:SetPoint("TOPLEFT", lab, "BOTTOMLEFT", 0, -2)
        d:SetText(it.d or "")
        cb:SetScript("OnClick", function(self)
          local v = self:GetChecked() and true or false
          if it.inv then v = not v end
          if it.key == "locked" then DB().locked = v else DB()[it.key] = v or nil end
          NS.ApplySettings()
        end)
        painters[#painters + 1] = function()
          local v = DB()[it.key] and true or false
          if it.inv then v = not v end
          cb:SetChecked(v)
        end
        y = y - 32
      elseif it.kind == "slider" then
        local lab = S.Font(pg:CreateFontString(nil, "ARTWORK"), 12, K.parch)
        lab:SetPoint("TOPLEFT", 0, y - 4)
        lab:SetText(it.t)
        local sl = CreateFrame("Slider", nil, pg, BackdropTemplateMixin and "BackdropTemplate" or nil)
        sl:SetOrientation("HORIZONTAL")
        sl:SetSize(160, 12)
        sl:SetPoint("TOPLEFT", 170, y - 4)
        sl:SetMinMaxValues(it.min, it.max)
        sl:SetValueStep(0.05)
        if sl.SetObeyStepOnDrag then sl:SetObeyStepOnDrag(true) end
        local track = sl:CreateTexture(nil, "BACKGROUND"); track:SetPoint("LEFT"); track:SetPoint("RIGHT"); track:SetHeight(3); track:SetColorTexture(S.C3(K.line))
        local thumb = sl:CreateTexture(nil, "ARTWORK"); thumb:SetSize(8, 14); thumb:SetColorTexture(S.C3(K.title))
        sl:SetThumbTexture(thumb)
        local val = S.Font(pg:CreateFontString(nil, "ARTWORK"), 10.5, K.mute)
        val:SetPoint("LEFT", sl, "RIGHT", 10, 0)
        local painting
        sl:SetScript("OnValueChanged", function(_, v)
          v = math.floor(v * 20 + 0.5) / 20
          val:SetText(math.floor(v * 100 + 0.5) .. "%")
          if painting then return end
          DB()[it.key] = v
          NS.ApplySettings()
        end)
        painters[#painters + 1] = function() painting = true; sl:SetValue(DB()[it.key] or 1); val:SetText(math.floor((DB()[it.key] or 1) * 100 + 0.5) .. "%"); painting = false end
        y = y - 30
      elseif it.kind == "select" then
        local lab = S.Font(pg:CreateFontString(nil, "ARTWORK"), 12, K.parch)
        lab:SetPoint("TOPLEFT", 0, y - 4)
        lab:SetText(it.t)
        local btns = {}
        local x = 170
        for _, ch in ipairs(it.choices) do
          local b = S.SkinButton(CreateFrame("Button", nil, pg, "UIPanelButtonTemplate"))
          b:SetText(ch[2])
          local w = math.max(80, (b:GetFontString() and b:GetFontString():GetStringWidth() or 60) + 24)
          b:SetSize(w, 22)
          b:SetPoint("TOPLEFT", x, y)
          x = x + w + 4
          b.mark = b:CreateTexture(nil, "OVERLAY"); b.mark:SetPoint("BOTTOMLEFT", 1, 1); b.mark:SetPoint("BOTTOMRIGHT", -1, 1); b.mark:SetHeight(2); b.mark:SetColorTexture(S.C3(K.accent))
          b:SetScript("OnClick", function()
            DB()[it.key] = ch[1]
            for _, o in ipairs(btns) do o.mark:SetShown(o.v == ch[1]) end
            NS.ApplySettings()
          end)
          b.v = ch[1]
          btns[#btns + 1] = b
        end
        painters[#painters + 1] = function() for _, o in ipairs(btns) do o.mark:SetShown(o.v == (DB()[it.key] or NS.DEFAULTS[it.key])) end end
        y = y - 30
        if it.d then
          local d = S.Font(pg:CreateFontString(nil, "ARTWORK"), 10.5, K.dim)
          d:SetPoint("TOPLEFT", 170, y + 4)
          d:SetText(it.d)
          y = y - 14
        end
      elseif it.kind == "button" then
        local b = S.SkinButton(CreateFrame("Button", nil, pg, "UIPanelButtonTemplate"))
        b:SetSize(180, 24)
        b:SetPoint("TOPLEFT", 0, y)
        b:SetText(it.t)
        b:SetScript("OnClick", it.fn)
        y = y - 34
      elseif it.kind == "key" then
        y = y - 6
        local kt = S.Font(pg:CreateFontString(nil, "ARTWORK"), 12, K.parch)
        kt:SetPoint("TOPLEFT", 0, y - 4)
        kt:SetText(L["Tecla para abrir el Códice"])
        local kb = S.SkinButton(CreateFrame("Button", nil, pg, "UIPanelButtonTemplate"))
        kb:SetSize(140, 22)
        kb:SetPoint("TOPLEFT", 170, y)
        local function paintKey() kb:SetText(CurrentKey() and ("Tecla: " .. CurrentKey()) or L["Elegir tecla"]) end
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
        local kclear = S.SkinButton(CreateFrame("Button", nil, pg, "UIPanelButtonTemplate"))
        kclear:SetSize(70, 22)
        kclear:SetPoint("LEFT", kb, "RIGHT", 4, 0)
        kclear:SetText(L["Quitar"])
        kclear:SetScript("OnClick", function()
          local old = CurrentKey()
          if old and not (InCombatLockdown and InCombatLockdown()) then SetBinding(old); SaveBindings(GetCurrentBindingSet()); Print("tecla quitada.") end
          paintKey()
        end)
        painters[#painters + 1] = paintKey
        y = y - 34
        -- acciones
        local function action(text, x, fn, kind)
          local b = S.SkinButton(CreateFrame("Button", nil, pg, "UIPanelButtonTemplate"), kind)
          b:SetSize(140, 22)
          b:SetPoint("TOPLEFT", x, y)
          b:SetText(text)
          b:SetScript("OnClick", fn)
          return b
        end
        action(L["Abrir el Códice"], 0, function() NS.Toggle() end, "primary")
        action(L["Crear macros"], 146, function() NS.CreateMacros() end)
        action("Ver el HUD", 292, function() if NS.HudPreview then NS.HudPreview() end end)
        y = y - 28
      elseif it.kind == "profile" then
        local note = S.Font(pg:CreateFontString(nil, "ARTWORK"), 12, K.parch)
        note:SetPoint("TOPLEFT", 0, y)
        note:SetWidth(380)
        note:SetJustifyH("LEFT")
        note:SetText(L["Las preferencias son de este personaje. Copiá las de otro:"])
        y = y - 26
        local rows = {}
        for r = 1, 6 do
          local name = S.Font(pg:CreateFontString(nil, "ARTWORK"), 12, K.parch)
          name:SetPoint("TOPLEFT", 0, y - 4)
          local b = S.SkinButton(CreateFrame("Button", nil, pg, "UIPanelButtonTemplate"))
          b:SetSize(80, 22)
          b:SetPoint("TOPLEFT", 260, y)
          b:SetText(L["Copiar"])
          rows[r] = { name = name, b = b }
          y = y - 28
        end
        StaticPopupDialogs["PIOLINCODEX_RESET"] = {
          text = "¿Borrar todas las tildes del Códice de este personaje? No se puede deshacer.",
          button1 = "Borrar", button2 = "Cancelar",
          OnAccept = function() NS.db.checks = {}; Print("tildes borradas. Escribí /reload para ver el cambio.") end,
          timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
        }
        local wipe = S.SkinButton(CreateFrame("Button", nil, pg, "UIPanelButtonTemplate"), "danger")
        wipe:SetSize(180, 22)
        wipe:SetPoint("TOPLEFT", 0, y - 8)
        wipe:SetText(L["Borrar todas las tildes"])
        wipe:SetScript("OnClick", function() StaticPopup_Show("PIOLINCODEX_RESET") end)
        local empty = S.Font(pg:CreateFontString(nil, "ARTWORK"), 10.5, K.dim)
        empty:SetPoint("TOPLEFT", 0, -58)
        empty:SetText(L["Todavía no hay otros personajes con el Códice."])
        painters[#painters + 1] = function()
          local list = NS.OtherProfiles()
          empty:SetShown(#list == 0)
          for r, row in ipairs(rows) do
            local k = list[r]
            row.name:SetText(k or ""); row.b:SetShown(k ~= nil)
            row.b:SetScript("OnClick", function()
              if k and NS.CopyProfile(k) then Print("preferencias copiadas de " .. k .. ". Escribí /reload para ver todo."); NS.ApplySettings(); show(current) end
            end)
          end
        end
      end
    end
    pg.refresh = function() for _, f in ipairs(painters) do f() end end
    pages[i] = pg
  end

  -- restablecer
  local hline = panel:CreateTexture(nil, "ARTWORK")
  hline:SetPoint("BOTTOMLEFT", 12, 44); hline:SetPoint("BOTTOMRIGHT", -16, 44); hline:SetHeight(1)
  hline:SetColorTexture(S.C3(K.line))
  local rAll = S.SkinButton(CreateFrame("Button", nil, panel, "UIPanelButtonTemplate"))
  rAll:SetSize(140, 24)
  rAll:SetPoint("BOTTOMRIGHT", -16, 12)
  rAll:SetText(L["Restablecer todo"])
  local rSec = S.SkinButton(CreateFrame("Button", nil, panel, "UIPanelButtonTemplate"))
  rSec:SetSize(140, 24)
  rSec:SetPoint("RIGHT", rAll, "LEFT", -6, 0)
  rSec:SetText(L["Restablecer sección"])
  StaticPopupDialogs["PIOLINCODEX_RESET_ALL"] = {
    text = "¿Volver todas las opciones y posiciones del Códice a como venían? Las tildes y las notas no se tocan.",
    button1 = "Restablecer", button2 = "Cancelar",
    OnAccept = function()
      for _, sec in ipairs(SECTIONS) do ResetSection(sec) end
      NS.ResetPositions()
      NS.ApplySettings()
      show(current)
      Print("opciones restablecidas.")
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
  }
  rAll:SetScript("OnClick", function() StaticPopup_Show("PIOLINCODEX_RESET_ALL") end)
  rSec:SetScript("OnClick", function()
    ResetSection(SECTIONS[current])
    if SECTIONS[current].key == "general" then NS.ResetPositions() end
    NS.ApplySettings()
    show(current)
    Print(SECTIONS[current].t .. ": opciones restablecidas.")
  end)

  panel:SetScript("OnShow", function() show(current) end)
  show(1)
  panel.Show_ = show

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
  mini:SetScript("OnDragStart", NS.DragStart)
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
      GameTooltip:AddLine(NS.db.locked and "Para moverlo, destrabá los marcos en la configuración." or "Arrastrá el recuadro para moverlo.", 0.55, 0.6, 0.68)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    -- arrastrar desde un ícono también mueve el recuadro
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart", function() NS.DragStart(mini) end)
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
