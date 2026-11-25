-- Códice de Piolin v2: ventana, pestañas, tildes, datos en vivo y recordatorios
local ADDON, NS = ...
local C = NS.colors

local FRAME_W, FRAME_H = 660, 560
local CONTENT_W = FRAME_W - 64

NS.checks = {}       -- [tabKey] = { id, ... }
NS.cbById = {}       -- [id] = checkbutton
NS.tabButtons = {}
NS.pages = {}

local function DB() return PiolinCodexDB end
local function Print(msg) DEFAULT_CHAT_FRAME:AddMessage(C.G .. "Códice de Piolin:" .. C.E .. " " .. msg) end
NS.Print = Print

----------------------------------------------------------------------
-- Utilidades del juego
----------------------------------------------------------------------
local function QuestDone(id)
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then return C_QuestLog.IsQuestFlaggedCompleted(id) end
  if IsQuestFlaggedCompleted then return IsQuestFlaggedCompleted(id) end
  return false
end

local function Skill(name)
  if not (GetNumSkillLines and GetSkillLineInfo) then return nil end
  local aliases = NS.SKILL_ALIASES[name] or { name }
  for i = 1, GetNumSkillLines() do
    local skillName, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
    if not isHeader and skillName then
      for _, a in ipairs(aliases) do
        if skillName == a then return rank, maxRank end
      end
    end
  end
  return nil
end
NS.Skill = Skill

local function Money(copper)
  if GetCoinTextureString then return GetCoinTextureString(copper) end
  local g = math.floor(copper / 10000)
  local s = math.floor((copper % 10000) / 100)
  return g .. "o " .. s .. "p"
end
NS.Money = Money

local function HasBuff(name)
  if not name then return false end
  for i = 1, 40 do
    local n = UnitBuff("player", i)
    if not n then break end
    if n == name then return true end
  end
  return false
end

----------------------------------------------------------------------
-- Cartel grande en pantalla
----------------------------------------------------------------------
local alert = CreateFrame("Frame", nil, UIParent)
alert:SetSize(700, 80)
alert:SetPoint("TOP", 0, -170)
alert:SetFrameStrata("HIGH")
alert:Hide()
alert.icon = alert:CreateTexture(nil, "ARTWORK")
alert.icon:SetSize(36, 36)
alert.icon:SetPoint("TOP", 0, 0)
alert.text = alert:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
alert.text:SetPoint("TOP", alert.icon, "BOTTOM", 0, -6)
alert.text:SetWidth(700)
alert.text:SetJustifyH("CENTER")
local lastAlert = {}

-- Estilo nuevo del cartel: tarjeta oscura con franja de color, ícono y texto (se arma la primera vez)
local function StyleAlert()
  if rawget(alert, "styled") or not NS.Style then return end
  rawset(alert, "styled", true)
  local S = NS.Style
  local bo = alert:CreateTexture(nil, "BACKGROUND", nil, -8); bo:SetAllPoints(); bo:SetColorTexture(S.C3(S.K.edge))
  local bg = alert:CreateTexture(nil, "BACKGROUND", nil, -7); bg:SetPoint("TOPLEFT", 1, -1); bg:SetPoint("BOTTOMRIGHT", -1, 1)
  bg:SetColorTexture(S.K.bg[1], S.K.bg[2], S.K.bg[3], 0.96)
  alert.stripe = alert:CreateTexture(nil, "BORDER")
  alert.stripe:SetPoint("TOPLEFT", 1, -1); alert.stripe:SetPoint("BOTTOMLEFT", 1, 1); alert.stripe:SetWidth(3)
  alert.icon:ClearAllPoints(); alert.icon:SetSize(30, 30); alert.icon:SetPoint("LEFT", 16, 0)
  alert.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  S.Font(alert.text, 15, nil, true)
  alert.text:ClearAllPoints(); alert.text:SetPoint("LEFT", alert.icon, "RIGHT", 12, 0)
  alert.text:SetJustifyH("LEFT")
end

function NS.Alert(key, text, icon, r, g, b, cooldown)
  local now = GetTime()
  if key and lastAlert[key] and now - lastAlert[key] < (cooldown or 20) then return end
  if key then lastAlert[key] = now end
  StyleAlert()
  alert.icon:SetTexture(icon or "Interface\\Icons\\Spell_Nature_LightningShield")
  alert.text:SetText(text)
  alert.text:SetTextColor(r or 1, g or 0.82, b or 0.25)
  if rawget(alert, "styled") then
    -- el ancho sigue al texto (hasta 620 px; más largo, pasa a dos renglones)
    alert.text:SetWidth(620)
    local tw = math.min(620, alert.text:GetStringWidth() + 4)
    alert.text:SetWidth(tw)
    alert:SetSize(tw + 74, math.max(54, alert.text:GetStringHeight() + 26))
    alert.stripe:SetColorTexture(r or 1, g or 0.82, b or 0.25)
  end
  if UIFrameFadeRemoveFrame then UIFrameFadeRemoveFrame(alert) end
  alert:SetAlpha(1)
  alert:Show()
  local shownAt = GetTime()
  rawset(alert, "shownAt", shownAt)
  local animated = rawget(alert, "styled") and NS.Appear and NS.Tween
  if animated then
    -- entra bajando con fundido, el ícono rebota y la franja de color se llena de arriba a abajo
    NS.Appear(alert, 0, 14, 0.28)
    NS.Pop(alert.icon, 30, 0.4)
    local stripe, h = alert.stripe, alert:GetHeight()
    if not (PiolinCodexDB and PiolinCodexDB.noAnim) then
      stripe:ClearAllPoints(); stripe:SetPoint("TOPLEFT", 1, -1); stripe:SetHeight(1)
      NS.Tween(0.35, function(p) stripe:SetHeight(math.max(1, (h - 2) * p)) end, 0.08, function()
        stripe:ClearAllPoints(); stripe:SetPoint("TOPLEFT", 1, -1); stripe:SetPoint("BOTTOMLEFT", 1, 1)
      end, NS.OutCubic)
    end
  end
  C_Timer.After(4, function()
    if rawget(alert, "shownAt") ~= shownAt then return end   -- llegó otro aviso: ese maneja la salida
    if animated then
      NS.Vanish(alert, 0, 12, 0.45)
    elseif UIFrameFadeOut then
      UIFrameFadeOut(alert, 1.5, 1, 0)
      C_Timer.After(1.6, function() alert:Hide() end)
    else
      alert:Hide()
    end
  end)
  if NS.Sound then NS.Sound(NS.SoundForAlert(key)) end
end

----------------------------------------------------------------------
-- Progreso y tildes
----------------------------------------------------------------------
local function CountTab(key)
  local ids, done = NS.checks[key] or {}, 0
  for _, id in ipairs(ids) do if DB().checks[id] then done = done + 1 end end
  return done, #ids
end

function NS.UpdateProgress()
  local totalDone, total = 0, 0
  for i, tab in ipairs(NS.TABS) do
    local d, n = CountTab(tab.key)
    totalDone, total = totalDone + d, total + n
    local btn = NS.tabButtons[i]
    if btn then
      btn.progress = n > 0 and (d .. "/" .. n .. " tildadas") or nil
      if n > 0 and d == n then btn:SetText("|cff7fd16a" .. tab.label .. "|r") else btn:SetText(tab.label) end
    end
  end
  if NS.frame then
    local pct = total > 0 and math.floor(totalDone / total * 100 + 0.5) or 0
    NS.frame.progressText:SetText(C.G .. "Progreso:" .. C.E .. " " .. totalDone .. "/" .. total .. " (" .. pct .. "%)")
    NS.frame.progressBar:SetValue(pct)
  end
end

local function SetCheck(id, value)
  DB().checks[id] = value and true or nil
  local cb = NS.cbById[id]
  if cb then cb:SetChecked(value and true or false); cb.paint() end
end

function NS.AutoCheck(silent)
  local newly = {}
  local function tick(id)
    if not DB().checks[id] then SetCheck(id, true); table.insert(newly, id) end
  end
  for id, q in pairs(NS.AUTO.quest) do if QuestDone(q) then tick(id) end end
  local level = UnitLevel("player") or 0
  for id, lv in pairs(NS.AUTO.level) do if level >= lv then tick(id) end end
  for id, rule in pairs(NS.AUTO.skill) do
    local rank, maxRank = Skill(rule[1])
    local v = rule[3] == "max" and maxRank or rank
    if v and v >= rule[2] then tick(id) end
  end
  if NS.AutoExtra then NS.AutoExtra(tick) end
  if #newly > 0 then
    NS.UpdateProgress()
    if not silent then Print("se tildaron solas " .. #newly .. " tarea(s) que ya cumpliste.") end
  end
end

----------------------------------------------------------------------
-- Textos en vivo
----------------------------------------------------------------------
local function CharText()
  local lines = {}
  local level = UnitLevel("player") or 0
  table.insert(lines, C.H .. (UnitName("player") or "?") .. C.E .. " · nivel " .. C.B .. level .. C.E)
  do
    local free = NS.FreeTalentPoints and NS.FreeTalentPoints()
    if free == nil then
      -- el cliente no informa los talentos
    elseif free > 0 then
      table.insert(lines, "|cffff6060Tenés " .. free .. " punto(s) de talento sin gastar.|r")
    else
      table.insert(lines, "Talentos: todos gastados.")
    end
  end
  local empty = {}
  for _, s in ipairs(NS.SLOTS) do
    if not GetInventoryItemID("player", s[1]) then table.insert(empty, s[2]) end
  end
  if #empty > 0 then
    table.insert(lines, "|cffff9a40Ranuras vacías:|r " .. table.concat(empty, ", "))
  else
    table.insert(lines, "|cff7fd16aEquipo completo.|r")
  end
  local profs = {}
  for _, name in ipairs({ "Pesca", "Cocina", "Desuello", "Peletería", "Primeros auxilios" }) do
    local rank, maxRank = Skill(name)
    if rank then
      local warn = rank >= maxRank and " |cffff6060(tope)|r" or ""
      table.insert(profs, name .. " " .. C.B .. rank .. "/" .. maxRank .. C.E .. warn)
    end
  end
  if #profs > 0 then table.insert(lines, table.concat(profs, " · ")) end
  if NS.CharExtra then local extra = NS.CharExtra(); if extra and extra ~= "" then table.insert(lines, extra) end end
  for _, h in ipairs(NS.HINTS) do
    if level <= h.max then table.insert(lines, C.G .. "Ahora te toca:" .. C.E .. " " .. h.t); break end
  end
  return table.concat(lines, "\n")
end

local function MatsText()
  local rank = Skill("Peletería")
  if not rank then return "No encontré Peletería en tus habilidades." end
  local tier
  for _, t in ipairs(NS.LW_TIERS) do
    if rank >= t.min and rank < t.max then tier = t; break end
  end
  if not tier then return "Peletería " .. rank .. ": no hay tramo cargado para este nivel." end
  local lines = { "Peletería " .. C.B .. rank .. C.E .. " · tramo " .. tier.min .. "-" .. tier.max .. ": " .. C.H .. tier.recipe .. C.E }
  for _, m in ipairs(tier.mats) do
    local have = GetItemCount(m[1], true) or 0
    local color = have >= m[2] and "|cff7fd16a" or "|cffff9a40"
    local missing = have >= m[2] and "listo" or ("faltan " .. (m[2] - have))
    table.insert(lines, "  " .. m[3] .. ": " .. color .. have .. "/" .. m[2] .. "|r  (" .. missing .. ")")
  end
  table.insert(lines, "|cffb9a98a(cuenta bolsas y banco)|r")
  if NS.MatsExtra then table.insert(lines, NS.MatsExtra()) end
  return table.concat(lines, "\n")
end

local function CampText()
  local lines = {}
  local money = GetMoney()
  local pct = math.min(100, math.floor(money / NS.MOUNT_GOAL * 100))
  table.insert(lines, "Ahorro para la montura del 40: " .. Money(money) .. " de " .. Money(NS.MOUNT_GOAL) .. " (" .. pct .. "%)")
  if NS.sessionMoney then
    local diff = money - NS.sessionMoney
    local sign = diff >= 0 and "|cff7fd16a+" or "|cffff6060-"
    table.insert(lines, "En esta sesión: " .. sign .. Money(math.abs(diff)) .. "|r")
  end
  if DB().tentAt then
    local left = 3600 - (time() - DB().tentAt)
    if left > 0 then
      table.insert(lines, "Tienda de campaña: disponible en " .. math.ceil(left / 60) .. " min")
    else
      table.insert(lines, "|cff7fd16aTienda de campaña: ¡disponible!|r")
    end
  else
    table.insert(lines, "Tienda de campaña: sin usar todavía (o escribí /piolin tienda al ponerla)")
  end
  return table.concat(lines, "\n"), pct
end

function NS.RefreshLive()
  local p = NS.pages.personaje
  if p and p.live then p.live:SetText(CharText()) end
  local fp = NS.pages.pesca
  if fp and fp.live and NS.FishText then fp.live:SetText(NS.FishText()) end
  local o = NS.pages.oficios
  if o and o.live then o.live:SetText(MatsText()) end
  local c = NS.pages.campamento
  if c and c.live then
    local text, pct = CampText()
    c.live:SetText(text)
    if c.bar then c.bar:SetValue(pct) end
  end
end

----------------------------------------------------------------------
-- Macros y TomTom
----------------------------------------------------------------------
function NS.CreateMacros()
  if InCombatLockdown and InCombatLockdown() then Print("no se pueden crear macros en combate."); return end
  local made, existed, failed = 0, 0, 0
  for _, m in ipairs(NS.MACROS) do
    local idx = GetMacroIndexByName(m.name)
    if idx and idx > 0 then
      existed = existed + 1
    else
      local ok = pcall(CreateMacro, m.name, "INV_MISC_QUESTIONMARK", m.body, true)
      if ok then made = made + 1 else failed = failed + 1 end
    end
  end
  Print(made .. " macro(s) creadas, " .. existed .. " ya existían" .. (failed > 0 and (", " .. failed .. " no entraron (¿lista llena?)") or "") .. ". Abrilas con /macro.")
end

function NS.GoTo(wp)
  if TomTom and TomTom.AddWaypoint then
    TomTom:AddWaypoint(wp[1], wp[2] / 100, wp[3] / 100, { title = wp[4], persistent = false, minimap = true, world = true })
    Print("flecha puesta hacia " .. wp[4] .. ".")
  else
    Print(wp[4] .. ": " .. C.B .. wp[2] .. ", " .. wp[3] .. C.E .. ". Instalá TomTom para tener una flecha.")
  end
end

----------------------------------------------------------------------
-- Maquetado
----------------------------------------------------------------------
local function NewLayout(child, tabKey)
  local L = { y = -6 }
  NS.checks[tabKey] = NS.checks[tabKey] or {}

  function L:Text(text, font, indent, r, g, b)
    local fs = child:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    fs:SetPoint("TOPLEFT", indent or 8, self.y)
    fs:SetWidth(CONTENT_W - (indent or 8) - 8)
    fs:SetJustifyH("LEFT")
    fs:SetSpacing(2)
    fs:SetText(text)
    if r then fs:SetTextColor(r, g, b) end
    self.y = self.y - fs:GetStringHeight() - 6
    return fs
  end

  function L:Header(text, icon)
    self.y = self.y - 6
    local x = 6
    if icon then
      local tex = child:CreateTexture(nil, "ARTWORK")
      tex:SetSize(20, 20)
      tex:SetPoint("TOPLEFT", 6, self.y + 2)
      tex:SetTexture(icon)
      tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      x = 32
    end
    local fs = child:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    fs:SetPoint("TOPLEFT", x, self.y)
    fs:SetWidth(CONTENT_W - x - 8)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    self.y = self.y - math.max(20, fs:GetStringHeight()) - 6
    local line = child:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.85, 0.66, 0.25, 0.35)
    line:SetPoint("TOPLEFT", 6, self.y + 3)
    line:SetSize(CONTENT_W - 12, 1)
    self.y = self.y - 4
  end

  function L:Check(id, text)
    local wp = NS.WAYPOINTS[id]
    local cb = CreateFrame("CheckButton", nil, child, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", 6, self.y + 3)
    local fs = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("TOPLEFT", 34, self.y - 2)
    fs:SetWidth(CONTENT_W - 42 - (wp and 44 or 0))
    fs:SetJustifyH("LEFT")
    fs:SetSpacing(2)
    fs:SetText(text)
    cb.paint = function()
      if cb:GetChecked() then fs:SetTextColor(0.55, 0.5, 0.42) else fs:SetTextColor(1, 1, 1) end
    end
    cb:SetChecked(DB().checks[id] and true or false)
    cb:SetScript("OnClick", function(self)
      DB().checks[id] = self:GetChecked() and true or nil
      self.paint()
      NS.UpdateProgress()
    end)
    cb.paint()
    NS.cbById[id] = cb
    table.insert(NS.checks[tabKey], id)
    if wp then
      local go = CreateFrame("Button", nil, child, "UIPanelButtonTemplate")
      go:SetSize(40, 20)
      go:SetPoint("TOPRIGHT", child, "TOPLEFT", CONTENT_W - 4, self.y + 1)
      go:SetText("Ir")
      go:SetScript("OnClick", function() NS.GoTo(wp) end)
      go:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_LEFT")
        GameTooltip:AddLine(wp[4], 0.85, 0.66, 0.25)
        GameTooltip:AddLine("Coordenadas " .. wp[2] .. ", " .. wp[3], 1, 1, 1)
        GameTooltip:AddLine(TomTom and "Clic: poner flecha de TomTom" or "Clic: mostrar en el chat", 0.7, 0.7, 0.7)
        GameTooltip:Show()
      end)
      go:SetScript("OnLeave", GameTooltip_Hide)
    end
    self.y = self.y - math.max(24, fs:GetStringHeight() + 10)
  end

  function L:Gap(n) self.y = self.y - (n or 8) end
  function L:Finish() child:SetHeight(-self.y + 16) end
  return L
end

local function BuildNotes(tab, parent)
  local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 14, -124)
  scroll:SetPoint("BOTTOMRIGHT", -34, 14)
  local lead = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  lead:SetPoint("BOTTOMLEFT", scroll, "TOPLEFT", 2, 6)
  lead:SetText(tab.lead)
  lead:SetTextColor(0.73, 0.66, 0.54)
  local bg = scroll:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0, 0, 0, 0.35)
  local eb = CreateFrame("EditBox", nil, scroll)
  eb:SetMultiLine(true)
  eb:SetFontObject(ChatFontNormal)
  eb:SetWidth(CONTENT_W - 10)
  eb:SetAutoFocus(false)
  eb:SetTextInsets(6, 6, 6, 6)
  eb:SetText(DB().notes or "")
  eb:SetScript("OnTextChanged", function(self) DB().notes = self:GetText() end)
  eb:SetScript("OnEscapePressed", eb.ClearFocus)
  scroll:SetScrollChild(eb)
  scroll:SetScript("OnMouseDown", function() eb:SetFocus() end)
  scroll.lead = lead
  scroll:Hide()
  lead:Hide()
  scroll:SetScript("OnShow", function() lead:Show() end)
  scroll:SetScript("OnHide", function() lead:Hide() end)
  return scroll
end

local function BuildPage(tab, parent)
  if tab.notes then return BuildNotes(tab, parent) end
  local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 14, -100)
  scroll:SetPoint("BOTTOMRIGHT", -34, 14)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetSize(CONTENT_W, 10)
  scroll:SetScrollChild(child)

  local L = NewLayout(child, tab.key)
  L:Text(tab.lead, "GameFontNormal", 8, 0.73, 0.66, 0.54)

  if tab.live then
    local titles = { char = "En vivo", mats = "Tu tramo actual", camp = "Oro y tienda", fish = "Pesca de hoy" }
    local icons = { char = "Interface\\Icons\\INV_Misc_Spyglass_03", mats = "Interface\\Icons\\INV_Misc_Bag_10", camp = "Interface\\Icons\\INV_Misc_Coin_02", fish = "Interface\\Icons\\Trade_Fishing" }
    L:Header(titles[tab.live], icons[tab.live])
    scroll.live = L:Text(" \n \n \n \n \n \n ", "GameFontHighlight", 10)
    if tab.live == "camp" then
      local bar = CreateFrame("StatusBar", nil, child)
      bar:SetPoint("TOPLEFT", 10, L.y)
      bar:SetSize(CONTENT_W - 20, 12)
      bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
      bar:SetStatusBarColor(0.95, 0.75, 0.2)
      bar:SetMinMaxValues(0, 100)
      local bbg = bar:CreateTexture(nil, "BACKGROUND")
      bbg:SetAllPoints()
      bbg:SetColorTexture(0, 0, 0, 0.6)
      scroll.bar = bar
      L:Gap(20)
    end
  end

  for _, sec in ipairs(tab.sections) do
    L:Header(sec.h, sec.icon)
    for _, item in ipairs(sec.items) do
      if item.id then L:Check(item.id, item.t) else L:Text(item.t, "GameFontHighlight", 12) end
    end
    L:Gap(4)
  end

  if tab.macros then
    L:Header("Macros", "Interface\\Icons\\INV_Misc_Note_02")
    L:Text("El botón crea estas macros en tu lista de personaje sin pisar las que ya existan. Si alguna sale con \"?\", revisá que el nombre del hechizo coincida con tu cliente.", "GameFontHighlightSmall", 12, 0.73, 0.66, 0.54)
    local btn = CreateFrame("Button", nil, child, "UIPanelButtonTemplate")
    btn:SetSize(160, 24)
    btn:SetPoint("TOPLEFT", 12, L.y)
    btn:SetText("Crear macros")
    btn:SetScript("OnClick", NS.CreateMacros)
    L:Gap(32)
    for _, m in ipairs(NS.MACROS) do
      L:Text(C.H .. m.name .. C.E, "GameFontNormal", 12)
      L:Text(m.body, "GameFontHighlightSmall", 22, 0.6, 0.85, 1)
    end
  end

  L:Finish()
  scroll:Hide()
  return scroll
end

function NS.ShowTab(index)
  for i, tab in ipairs(NS.TABS) do
    local page = NS.pages[tab.key]
    if page then page:SetShown(i == index) end
    local btn = NS.tabButtons[i]
    if btn then if i == index then btn:LockHighlight() else btn:UnlockHighlight() end end
  end
  DB().lastTab = index
  NS.RefreshLive()
end

----------------------------------------------------------------------
-- Ventana principal
----------------------------------------------------------------------
local function BuildFrame()
  local f = CreateFrame("Frame", "PiolinCodexFrame", UIParent, "BasicFrameTemplateWithInset")
  f:SetSize(FRAME_W, FRAME_H)
  f:SetPoint("CENTER")
  f:SetFrameStrata("HIGH")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetClampedToScreen(true)
  f:Hide()
  tinsert(UISpecialFrames, "PiolinCodexFrame")

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  title:SetPoint("TOP", 0, -6)
  title:SetText(C.G .. "Códice de Piolin" .. C.E .. "  ·  Enano Chamán Mejora")

  local x, y = 12, -30
  for i, tab in ipairs(NS.TABS) do
    if x + 76 > FRAME_W - 12 then x, y = 12, y - 24 end
    local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    b:SetSize(76, 22)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(tab.label)
    b:SetScript("OnClick", function() NS.ShowTab(i) end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
      GameTooltip:AddLine(tab.label, 0.85, 0.66, 0.25)
      GameTooltip:AddLine(tab.lead, 1, 1, 1, true)
      if self.progress then GameTooltip:AddLine(self.progress, 0.41, 0.8, 0.94) end
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    NS.tabButtons[i] = b
    x = x + 78
  end

  local bar = CreateFrame("StatusBar", nil, f)
  bar:SetPoint("TOPLEFT", 14, y - 30)
  bar:SetSize(FRAME_W - 220, 10)
  bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar:SetStatusBarColor(0.3, 0.55, 0.9)
  bar:SetMinMaxValues(0, 100)
  local bg = bar:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0, 0, 0, 0.6)
  f.progressBar = bar
  local pt = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  pt:SetPoint("LEFT", bar, "RIGHT", 8, 0)
  f.progressText = pt

  for _, tab in ipairs(NS.TABS) do NS.pages[tab.key] = BuildPage(tab, f) end

  f:SetScript("OnShow", function() NS.AutoCheck(true); NS.UpdateProgress(); NS.RefreshLive() end)
  NS.frame = f
  NS.ShowTab(DB().lastTab or 1)
  NS.UpdateProgress()
end

function NS.Toggle()
  if not NS.frame then BuildFrame() end
  NS.frame:SetShown(not NS.frame:IsShown())
end

----------------------------------------------------------------------
-- Panel junto al instructor de chamán
----------------------------------------------------------------------
local trainerPanel
local function ShowTrainerPanel()
  if select(2, UnitClass("player")) ~= "SHAMAN" then return end
  if IsTradeskillTrainer and IsTradeskillTrainer() then return end
  local anchor = ClassTrainerFrame
  if not anchor then return end
  local wasShown = trainerPanel and trainerPanel:IsShown() and trainerPanel:IsVisible()
  if not trainerPanel then
    local S = NS.Style
    trainerPanel = CreateFrame("Frame", "PiolinCodexTrainerPanel", anchor, "BasicFrameTemplateWithInset")
    S.SkinWindow(trainerPanel)
    trainerPanel:SetSize(280, 360)
    local t = S.Font(trainerPanel:CreateFontString(nil, "OVERLAY"), 12.5, S.K.title, true)
    t:SetPoint("TOPLEFT", 12, -8)
    t:SetText("Qué entrenar")
    local y = -38
    local function add(text, r, g, b, head)
      local fs = S.Font(trainerPanel:CreateFontString(nil, "OVERLAY"), head and 12 or 11.5, nil, head)
      fs:SetPoint("TOPLEFT", 14, y)
      fs:SetWidth(252)
      fs:SetJustifyH("LEFT")
      fs:SetText(text)
      fs:SetTextColor(r, g, b)
      y = y - fs:GetStringHeight() - (head and 7 or 5)
    end
    add("Comprá", 0.5, 0.86, 0.4, true)
    for _, s in ipairs(NS.TRAINER.buy) do add("+  " .. s, 0.86, 0.89, 0.93) end
    y = y - 8
    add("Salteá", 1, 0.42, 0.4, true)
    for _, s in ipairs(NS.TRAINER.skip) do add("–  " .. s, 0.53, 0.57, 0.64) end
    -- el alto sigue al contenido, así ninguna línea queda afuera
    trainerPanel:SetHeight(-y + 14)
  end
  trainerPanel:ClearAllPoints()
  trainerPanel:SetPoint("TOPLEFT", anchor, "TOPRIGHT", -30, -12)
  trainerPanel:Show()
  -- entra deslizándose desde el borde de la ventana del instructor
  if not wasShown and NS.Appear then NS.Appear(trainerPanel, -14, 0, 0.25) end
end

----------------------------------------------------------------------
-- Recordatorios
----------------------------------------------------------------------
local LIGHTNING_SHIELD = GetSpellInfo(324) or "Escudo de relámpagos"

local function CheckCombatBuffs(beforeFight)
  if DB().noReminders then return end
  if (UnitLevel("player") or 0) < 10 then return end
  local missing = {}
  local auras = not NS.AurasReadable or NS.AurasReadable()
  if auras and not HasBuff(LIGHTNING_SHIELD) then table.insert(missing, "Escudo de relámpagos") end
  local hasMH = GetWeaponEnchantInfo()
  local mh = GetInventoryItemID("player", 16)
  if mh and not hasMH then
    local _, _, _, _, _, _, _, _, _, _, _, classID, subID = GetItemInfo(mh)
    if not (classID == 2 and subID == 20) then table.insert(missing, "imbuición del arma") end
  end
  if #missing > 0 then
    NS.Alert("combat", (beforeFight and "Antes de pelear, te falta: " or "Te falta: ") .. table.concat(missing, " y "), "Interface\\Icons\\Spell_Nature_LightningShield", 1, 0.35, 0.3, 30)
  end
end

local function CheckFishing()
  if DB().noReminders then return end
  local mh = GetInventoryItemID("player", 16)
  if not mh then return end
  local _, _, _, _, _, _, _, _, _, _, _, classID, subID = GetItemInfo(mh)
  if classID ~= 2 or subID ~= 20 then return end
  local has, expiration = GetWeaponEnchantInfo()
  if not has then
    NS.Alert("lure", "Tu caña no tiene cebo: ponele un abalorio reluciente", "Interface\\Icons\\INV_Misc_Gem_Variety_02", 0.41, 0.8, 0.94, 60)
  elseif expiration and expiration < 60000 then
    NS.Alert("lure-low", "Al cebo le queda menos de 1 minuto", "Interface\\Icons\\INV_Misc_Gem_Variety_02", 0.41, 0.8, 0.94, 60)
  end
end

local function CheckTent()
  if DB().tentAt and not DB().tentWarned and time() - DB().tentAt >= 3600 then
    DB().tentWarned = true
    NS.Alert("tent", "Ya podés volver a poner la Tienda de campaña", "Interface\\Icons\\INV_Misc_Bag_09", 0.5, 0.82, 0.42, 5)
  end
end

local function StartTent()
  DB().tentAt = time()
  DB().tentWarned = nil
  Print("temporizador de la tienda iniciado: te aviso en 60 minutos.")
  NS.RefreshLive()
end

----------------------------------------------------------------------
-- Botón del minimapa
----------------------------------------------------------------------
local function BuildMinimapButton()
  local mb = CreateFrame("Button", "PiolinCodexMinimapButton", Minimap)
  mb:SetSize(31, 31)
  mb:SetFrameStrata("MEDIUM")
  mb:SetFrameLevel(8)
  mb:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  local icon = mb:CreateTexture(nil, "BACKGROUND")
  icon:SetSize(20, 20)
  icon:SetPoint("TOPLEFT", 7, -5)
  icon:SetTexture("Interface\\Icons\\Spell_Nature_LightningShield")
  local border = mb:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53)
  border:SetPoint("TOPLEFT")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  local function place()
    local a = math.rad(DB().minimapAngle or 220)
    mb:ClearAllPoints()
    mb:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(a), 80 * math.sin(a))
  end
  mb:RegisterForClicks("LeftButtonUp")
  mb:RegisterForDrag("LeftButton")
  mb:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local mx, my = Minimap:GetCenter()
      local px, py = GetCursorPosition()
      local s = Minimap:GetEffectiveScale()
      DB().minimapAngle = math.deg(math.atan2(py / s - my, px / s - mx))
      place()
    end)
  end)
  mb:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  mb:SetScript("OnClick", NS.Toggle)
  -- al pasar el mouse el ícono crece un poco y se aclara; al salir vuelve
  local size = 20
  local function hover(on)
    local from, to = size, on and 23 or 20
    if NS.Tween and not DB().noAnim then
      NS.Tween(0.15, function(p) size = from + (to - from) * p; icon:SetSize(size, size) end, 0, nil, NS.OutCubic)
    else
      size = to; icon:SetSize(to, to)
    end
    local v = on and 1 or 0.9
    icon:SetVertexColor(v, v, v)
  end
  icon:SetVertexColor(0.9, 0.9, 0.9)
  mb:SetScript("OnEnter", function(self)
    hover(true)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Códice de Piolin", 0.85, 0.66, 0.25)
    GameTooltip:AddLine("Clic: abrir o cerrar", 1, 1, 1)
    GameTooltip:AddLine("Arrastrar: mover el botón", 1, 1, 1)
    GameTooltip:Show()
  end)
  mb:SetScript("OnLeave", function() hover(false); GameTooltip_Hide() end)
  place()
  mb:SetShown(not DB().hideMinimap)
  NS.minimapButton = mb
end

----------------------------------------------------------------------
-- Eventos
----------------------------------------------------------------------
local pendingRefresh = false
local function QueueRefresh()
  if pendingRefresh then return end
  pendingRefresh = true
  C_Timer.After(0.7, function()
    pendingRefresh = false
    if NS.frame and NS.frame:IsShown() then NS.RefreshLive() end
  end)
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_LEVEL_UP", "SKILL_LINES_CHANGED", "CHARACTER_POINTS_CHANGED",
  "QUEST_TURNED_IN", "PLAYER_REGEN_DISABLED", "UNIT_INVENTORY_CHANGED", "PLAYER_EQUIPMENT_CHANGED", "BAG_UPDATE",
  "PLAYER_MONEY", "PLAYER_TARGET_CHANGED", "TRAINER_SHOW", "TRAINER_CLOSED", "UNIT_SPELLCAST_SUCCEEDED" }) do
  pcall(ev.RegisterEvent, ev, e)
end

ev:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
  if event == "ADDON_LOADED" then
    if arg1 ~= ADDON then return end
    PiolinCodexDB = PiolinCodexDB or {}
    PiolinCodexDB.checks = PiolinCodexDB.checks or {}
    BuildMinimapButton()
  elseif event == "PLAYER_LOGIN" then
    NS.sessionMoney = GetMoney()
    C_Timer.After(4, function() NS.AutoCheck(false) end)
    C_Timer.NewTicker(20, function() CheckFishing(); CheckTent() end)
    Print("listo. Escribí /piolin o tocá el botón del minimapa.")
  elseif event == "PLAYER_LEVEL_UP" then
    local lvl = arg1
    local tip = NS.LEVEL_TIPS[lvl] or "Pasá por el instructor de chamán a ver qué hay nuevo."
    C_Timer.After(1.5, function()
      NS.Alert("level", "¡Nivel " .. lvl .. "! " .. tip, "Interface\\Icons\\Ability_Shaman_Stormstrike", 1, 0.82, 0.25, 1)
      Print(C.H .. "Nivel " .. lvl .. ":" .. C.E .. " " .. tip)
      NS.AutoCheck(false)
    end)
  elseif event == "QUEST_TURNED_IN" or event == "SKILL_LINES_CHANGED" then
    C_Timer.After(1, function() NS.AutoCheck(false) end)
    QueueRefresh()
  elseif event == "PLAYER_REGEN_DISABLED" then
    pcall(CheckCombatBuffs, false)
  elseif event == "PLAYER_TARGET_CHANGED" then
    if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") and not (InCombatLockdown and InCombatLockdown()) then
      pcall(CheckCombatBuffs, true)
    end
  elseif event == "UNIT_INVENTORY_CHANGED" then
    if arg1 == "player" then CheckFishing() end
  elseif event == "TRAINER_SHOW" then
    C_Timer.After(0.1, ShowTrainerPanel)
  elseif event == "TRAINER_CLOSED" then
    if trainerPanel then trainerPanel:Hide() end
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    if arg1 == "player" and arg3 then
      local name = GetSpellInfo(arg3)
      if name and (name:find("Tienda de campa") or name:find("Camp Tent")) then StartTent() end
    end
  else
    QueueRefresh()
  end
end)

----------------------------------------------------------------------
-- Comandos
----------------------------------------------------------------------
SLASH_PIOLINCODEX1 = "/piolin"
SLASH_PIOLINCODEX2 = "/codice"
SlashCmdList["PIOLINCODEX"] = function(msg)
  msg = (msg or ""):lower()
  if NS.TradeSlash and NS.TradeSlash(msg) then return end
  if msg == "macros" then
    NS.CreateMacros()
  elseif msg == "tienda" then
    StartTent()
  elseif msg == "minimapa" then
    PiolinCodexDB.hideMinimap = not PiolinCodexDB.hideMinimap
    if NS.minimapButton then NS.minimapButton:SetShown(not PiolinCodexDB.hideMinimap) end
    Print(PiolinCodexDB.hideMinimap and "botón del minimapa oculto." or "botón del minimapa visible.")
  elseif msg == "avisos" then
    PiolinCodexDB.noReminders = not PiolinCodexDB.noReminders
    Print(PiolinCodexDB.noReminders and "recordatorios apagados." or "recordatorios encendidos.")
  elseif msg == "probar" then
    NS.Alert(nil, "Así se ven los avisos del Códice", "Interface\\Icons\\Spell_Nature_LightningShield", 1, 0.82, 0.25)
  elseif msg == "reset" then
    PiolinCodexDB.checks = {}
    Print("tildes borradas. Recargá con /reload.")
  else
    NS.Toggle()
  end
end
