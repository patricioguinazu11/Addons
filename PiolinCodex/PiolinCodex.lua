-- Códice de Piolin: núcleo (avisos, tildes automáticas, recordatorios, minimapa, eventos y comandos).
-- La ventana principal está en UI.lua.
local ADDON, NS = ...
local C = NS.colors

NS.checks = {}       -- [tabKey] = { id, ... }
NS.cbById = {}       -- [id] = checkbutton
NS.pages = {}

local function DB() return NS.db end
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
    if not (NS.db and NS.db.noAnim) then
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
    -- con el HUD prendido, lo que falta se marca ahí en rojo (con el sonido de aviso) y no tapa la pantalla
    if NS.HudFlash and NS.HudFlash() then NS.Sound("combat") return end
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
  -- Siempre en el borde: la distancia sale del tamaño real del minimapa (en Forever es más grande que en Classic)
  local function Radius() return ((Minimap:GetWidth() or 140) / 2) + 5 end
  -- Ángulos que ya ocupan otros botones del borde (Questie y los demás addons), y el de Questie aparte
  local function TakenAngles()
    local taken, questie = {}, nil
    pcall(function()
      local mx, my = Minimap:GetCenter()
      if not mx then return end
      local ms, R = Minimap:GetEffectiveScale(), Radius()
      for _, ch in ipairs({ Minimap:GetChildren() }) do
        if type(ch) == "table" and ch ~= mb and ch.IsShown and ch:IsShown() then
          local cx, cy = ch:GetCenter()
          local k = (ch:GetEffectiveScale() or ms) / ms
          local w = (ch:GetWidth() or 0) * k
          if cx and w >= 16 and w <= 64 then
            local dx, dy = cx * k - mx, cy * k - my
            local d = math.sqrt(dx * dx + dy * dy)
            if d > R * 0.7 and d < R * 1.4 then
              local ang = math.deg(math.atan2(dy, dx))
              taken[#taken + 1] = ang
              if (ch:GetName() or ""):find("Questie") then questie = ang end
            end
          end
        end
      end
    end)
    return taken, questie
  end
  -- Lugar libre en el borde: pegado a Questie si está, y si no cerca de abajo a la izquierda
  local function AutoAngle()
    local taken, questie = TakenAngles()
    local base = questie or 220
    local step = math.deg(2 * math.asin(math.min(1, 18 / Radius()))) + 4
    local function free(a)
      for _, t in ipairs(taken) do
        if math.abs((a - t + 180) % 360 - 180) < step then return false end
      end
      return true
    end
    if free(base) then return base end
    for k = 1, 16 do
      for _, s in ipairs({ -1, 1 }) do
        local a = base + s * k * step
        if free(a) then return a end
      end
    end
    return base
  end
  local function place()
    local deg = (DB().minimapManual and DB().minimapAngle) or NS.minimapAutoAngle or 220
    local a, R = math.rad(deg), Radius()
    mb:ClearAllPoints()
    mb:SetPoint("CENTER", Minimap, "CENTER", R * math.cos(a), R * math.sin(a))
  end
  local function autoPlace()
    if not DB().minimapManual then NS.minimapAutoAngle = AutoAngle() end
    place()
  end
  mb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  mb:RegisterForDrag("LeftButton")
  mb:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local mx, my = Minimap:GetCenter()
      local px, py = GetCursorPosition()
      local s = Minimap:GetEffectiveScale()
      DB().minimapAngle = math.deg(math.atan2(py / s - my, px / s - mx))
      DB().minimapManual = true
      place()
    end)
  end)
  mb:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  mb:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
      DB().minimapManual = nil
      autoPlace()
      Print("el botón del minimapa vuelve a ubicarse solo en el borde.")
      return
    end
    NS.Toggle()
  end)
  -- Questie y otros addons crean sus botones después: se vuelve a buscar lugar en unos segundos,
  -- y si cambia el tamaño del minimapa se recalcula la distancia al borde
  if C_Timer and C_Timer.After then
    C_Timer.After(1, autoPlace)
    C_Timer.After(5, autoPlace)
  end
  if Minimap.HookScript then pcall(Minimap.HookScript, Minimap, "OnSizeChanged", function() place() end) end
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
    GameTooltip:AddLine("Clic derecho: que se ubique solo en el borde", 1, 1, 1)
    GameTooltip:Show()
  end)
  mb:SetScript("OnLeave", function() hover(false); GameTooltip_Hide() end)
  autoPlace()
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
  "QUEST_TURNED_IN", "PLAYER_REGEN_DISABLED", "PLAYER_EQUIPMENT_CHANGED", "BAG_UPDATE_DELAYED",
  "PLAYER_MONEY", "PLAYER_TARGET_CHANGED", "TRAINER_SHOW", "TRAINER_CLOSED" }) do
  pcall(ev.RegisterEvent, ev, e)
end
-- eventos de unidad: solo los del jugador (en grupo o banda no se disparan por cada compañero)
NS.UnitEvents(ev, { "UNIT_INVENTORY_CHANGED", "UNIT_SPELLCAST_SUCCEEDED" }, "player")

ev:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
  if event == "ADDON_LOADED" then
    if arg1 ~= ADDON then return end
    NS.InitDB()
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
      -- con el cartel de nivel prendido, el consejo ya va adentro del cartel
      if NS.db.noLevelCard or not NS.ShowLevelCard then NS.Alert("level", "¡Nivel " .. lvl .. "! " .. tip, "Interface\\Icons\\Ability_Shaman_Stormstrike", 1, 0.82, 0.25, 1) end
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
  if NS.LevelSlash and NS.LevelSlash(msg) then return end
  if NS.HudSlash and NS.HudSlash(msg) then return end
  if msg == "macros" then
    NS.CreateMacros()
  elseif msg == "tienda" then
    StartTent()
  elseif msg == "minimapa" then
    NS.db.hideMinimap = not NS.db.hideMinimap
    if NS.minimapButton then NS.minimapButton:SetShown(not NS.db.hideMinimap) end
    Print(NS.db.hideMinimap and "botón del minimapa oculto." or "botón del minimapa visible.")
  elseif msg == "avisos" then
    NS.db.noReminders = not NS.db.noReminders
    Print(NS.db.noReminders and "recordatorios apagados." or "recordatorios encendidos.")
  elseif msg == "probar" then
    NS.Alert(nil, "Así se ven los avisos del Códice", "Interface\\Icons\\Spell_Nature_LightningShield", 1, 0.82, 0.25)
  elseif msg == "reset" then
    NS.db.checks = {}
    Print("tildes borradas. Recargá con /reload.")
  else
    NS.Toggle()
  end
end
