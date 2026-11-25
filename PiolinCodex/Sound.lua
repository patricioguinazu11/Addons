-- Códice de Piolin: sonidos del propio WoW y su panel de opciones
local ADDON, NS = ...

local function DB() return PiolinCodexDB end

-- Sonidos del juego: nombre, constante de SOUNDKIT y número de respaldo
NS.SOUNDS = {
  { key = "none", t = "Sin sonido" },
  { key = "raid", t = "Aviso de banda", kit = "RAID_WARNING", id = 8959 },
  { key = "ready", t = "Comprobación de grupo", kit = "READY_CHECK", id = 8960 },
  { key = "level", t = "Subir de nivel", kit = "LEVEL_UP", id = 888 },
  { key = "quest", t = "Misión completada", kit = "IG_QUEST_LIST_COMPLETE", id = 878 },
  { key = "qopen", t = "Abrir registro de misiones", kit = "IG_QUEST_LIST_OPEN", id = 875 },
  { key = "book", t = "Abrir libro de hechizos", kit = "IG_SPELLBOOK_OPEN", id = 829 },
  { key = "tab", t = "Pestaña de personaje", kit = "IG_CHARACTER_INFO_TAB", id = 841 },
  { key = "check", t = "Casilla", kit = "IG_MAINMENU_OPTION_CHECKBOX_ON", id = 856 },
  { key = "ping", t = "Ping del mapa", kit = "MAP_PING", id = 3175 },
  { key = "whisper", t = "Susurro", kit = "TELL_MESSAGE", id = 3081 },
  { key = "coin", t = "Monedas", kit = "LOOT_WINDOW_COIN_SOUND", id = 120 },
  { key = "auction", t = "Casa de subastas", kit = "AUCTION_WINDOW_OPEN", id = 5274 },
  { key = "bgqueue", t = "Cola de campo de batalla", kit = "PVP_THROUGH_QUEUE", id = 8459 },
}
local BY_KEY = {}
for _, s in ipairs(NS.SOUNDS) do BY_KEY[s.key] = s end

-- Cada aviso del Códice y su sonido por defecto
NS.SOUND_EVENTS = {
  { key = "open", t = "Abrir el Códice (los elementos se juntan)", def = "book" },
  { key = "tab", t = "Cambiar de pestaña", def = "tab" },
  { key = "tick", t = "Tildar una tarea", def = "check" },
  { key = "combat", t = "Aviso de combate (escudo, imbuición)", def = "ping" },
  { key = "lure", t = "Caña sin cebo", def = "whisper" },
  { key = "quest", t = "Misión lista para entregar", def = "quest" },
  { key = "level", t = "Subida de nivel (el juego ya suena)", def = "none" },
  { key = "cap", t = "Oficio cerca del tope", def = "whisper" },
  { key = "tent", t = "Tienda disponible", def = "whisper" },
  { key = "dur", t = "Equipo gastado", def = "ping" },
  { key = "arrive", t = "Llegar a la marca del mapa", def = "ping" },
  { key = "section", t = "Sección completa", def = "quest" },
  { key = "bar", t = "Subir un oficio", def = "coin" },
  { key = "pulse", t = "El rayo del minimapa avisa", def = "whisper" },
  { key = "other", t = "Otros avisos", def = "ping" },
}
local EVENT_DEF = {}
for _, e in ipairs(NS.SOUND_EVENTS) do EVENT_DEF[e.key] = e.def end

NS.CHANNELS = { { "Dialog", "Diálogo (con volumen propio)" }, { "SFX", "Efectos" }, { "Ambience", "Ambiente" }, { "Master", "General" } }

local function SoundId(s)
  if not s or s.key == "none" then return nil end
  return (SOUNDKIT and s.kit and SOUNDKIT[s.kit]) or s.id
end

-- Volumen propio: por el canal de Diálogo, el Códice baja ese canal un momento mientras suena
local CVAR = "Sound_DialogVolume"
local restoreToken = 0
local function RestoreDialog()
  local orig = PiolinCodexDB and DB().dialogVolOrig
  if orig then SetCVar(CVAR, orig); DB().dialogVolOrig = nil end
end
NS.RestoreDialogVolume = RestoreDialog

function NS.PlaySoundKey(soundKey)
  local id = SoundId(BY_KEY[soundKey])
  if not id then return end
  local channel = (PiolinCodexDB and DB().soundChannel) or "Dialog"
  local vol = (PiolinCodexDB and DB().soundVolume) or 0.5
  if channel == "Dialog" and vol < 1 and GetCVar and SetCVar then
    if not DB().dialogVolOrig then DB().dialogVolOrig = tonumber(GetCVar(CVAR)) or 1 end
    SetCVar(CVAR, DB().dialogVolOrig * vol)
    restoreToken = restoreToken + 1
    local mine = restoreToken
    C_Timer.After(2.5, function() if mine == restoreToken then RestoreDialog() end end)
  end
  pcall(PlaySound, id, channel)
end

-- Si el juego se cerró mientras sonaba algo, deja el canal como estaba
local guard = CreateFrame("Frame")
guard:RegisterEvent("PLAYER_LOGIN")
guard:RegisterEvent("PLAYER_LOGOUT")
guard:SetScript("OnEvent", function() if PiolinCodexDB then RestoreDialog() end end)

function NS.Sound(eventKey)
  if not PiolinCodexDB or DB().noSound then return end
  local choice = DB().sounds and DB().sounds[eventKey]
  NS.PlaySoundKey(choice or EVENT_DEF[eventKey] or EVENT_DEF.other)
end

-- Qué aviso corresponde a cada cartel
function NS.SoundForAlert(key)
  key = key or ""
  if key == "combat" then return "combat" end
  if key:find("^lure") then return "lure" end
  if key == "tent" then return "tent" end
  if key == "level" then return "level" end
  if key:find("^q%d") then return "quest" end
  if key:find("^cap") then return "cap" end
  if key:find("^dur") then return "dur" end
  return "other"
end

----------------------------------------------------------------------
-- Página "Sonido" dentro de las opciones del Códice
----------------------------------------------------------------------
local function Dropdown(parent, width, items, get, set)
  local ok, dd = pcall(CreateFrame, "Frame", nil, parent, "UIDropDownMenuTemplate")
  if not ok or not UIDropDownMenu_Initialize then
    -- alternativa: un botón que va pasando por las opciones
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    if NS.Style then NS.Style.SkinButton(b) end
    b:SetSize(width + 20, 24)
    local function label()
      local v = get()
      for _, it in ipairs(items) do if it[1] == v then return it[2] end end
      return items[1][2]
    end
    b:SetText(label())
    b:SetScript("OnClick", function()
      local v, idx = get(), 1
      for i, it in ipairs(items) do if it[1] == v then idx = i end end
      local nx = items[idx % #items + 1]
      set(nx[1]); b:SetText(nx[2])
    end)
    b.refresh = function() b:SetText(label()) end
    return b
  end
  UIDropDownMenu_SetWidth(dd, width)
  local function label()
    local v = get()
    for _, it in ipairs(items) do if it[1] == v then return it[2] end end
    return items[1][2]
  end
  UIDropDownMenu_Initialize(dd, function(self, level)
    for _, it in ipairs(items) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = it[2]
      info.checked = (get() == it[1])
      info.func = function()
        set(it[1])
        UIDropDownMenu_SetText(dd, it[2])
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)
  UIDropDownMenu_SetText(dd, label())
  dd.refresh = function() UIDropDownMenu_SetText(dd, label()) end
  return dd
end

function NS.BuildSoundPanel(parentCategory, parentPanel)
  local p = CreateFrame("Frame", "PiolinCodexSoundOptions")
  p.name = "Sonido"
  p.parent = parentPanel and parentPanel.name
  local S = NS.Style
  local title = S.Font(p:CreateFontString(nil, "ARTWORK"), 18, S.K.title, true)
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Códice de Piolin · Sonido")
  local sub = S.Font(p:CreateFontString(nil, "ARTWORK"), 11.5, S.K.mute)
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetWidth(560)
  sub:SetJustifyH("LEFT")
  sub:SetText("Todos los sonidos son del propio WoW. El volumen lo maneja la barra del canal que elijas en Opciones → Sonido del juego.")

  local master = S.SkinCheck(CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate"))
  master:SetSize(24, 24)
  master:SetPoint("TOPLEFT", 14, -76)
  local ml = S.Font(p:CreateFontString(nil, "ARTWORK"), 12.5, S.K.parch)
  ml:SetPoint("LEFT", master, "RIGHT", 6, 0)
  ml:SetText("Sonidos del Códice")
  master:SetScript("OnClick", function(self) DB().noSound = not self:GetChecked() or nil end)

  local cl = S.Font(p:CreateFontString(nil, "ARTWORK"), 12.5, S.K.title, true)
  cl:SetPoint("TOPLEFT", 300, -81)
  cl:SetText("Canal")
  local chanItems = {}
  for _, c in ipairs(NS.CHANNELS) do table.insert(chanItems, { c[1], c[2] }) end
  local chan = Dropdown(p, 190, chanItems, function() return DB().soundChannel or "Dialog" end, function(v) DB().soundChannel = v end)
  chan:SetPoint("LEFT", cl, "RIGHT", 10, 0)

  local vl = S.Font(p:CreateFontString(nil, "ARTWORK"), 12.5, S.K.title, true)
  vl:SetPoint("TOPLEFT", 20, -120)
  vl:SetText("Volumen del Códice")
  local okS, slider = pcall(CreateFrame, "Slider", "PiolinCodexVolume", p, "OptionsSliderTemplate")
  if not okS then
    -- deslizador plano: riel fino y tirador azul
    slider = CreateFrame("Slider", "PiolinCodexVolume", p)
    slider:SetOrientation("HORIZONTAL")
    slider:SetHeight(16)
    local rail = slider:CreateTexture(nil, "BACKGROUND")
    rail:SetPoint("LEFT", 0, 0); rail:SetPoint("RIGHT", 0, 0); rail:SetHeight(4)
    rail:SetColorTexture(S.C3(S.K.track))
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
    if type(thumb) == "table" then thumb:SetSize(10, 16); thumb:SetVertexColor(S.C3(S.K.accent)) end
    slider.valueText = S.Font(slider:CreateFontString("PiolinCodexVolumeText", "OVERLAY"), 10.5, S.K.mute)
    slider.valueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)
  end
  slider:SetPoint("LEFT", vl, "RIGHT", 24, 0)
  slider:SetWidth(220)
  slider:SetMinMaxValues(0.1, 1)
  slider:SetValueStep(0.05)
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
  local low, high, txt = _G.PiolinCodexVolumeLow, _G.PiolinCodexVolumeHigh, _G.PiolinCodexVolumeText
  if low then low:SetText("10%") end
  if high then high:SetText("100%") end
  local vhint = S.Font(p:CreateFontString(nil, "ARTWORK"), 10.5, S.K.dim)
  vhint:SetPoint("TOPLEFT", vl, "BOTTOMLEFT", 0, -10)
  vhint:SetWidth(560)
  vhint:SetJustifyH("LEFT")
  vhint:SetText("Funciona con el canal Diálogo: mientras suena el Códice, baja ese canal un instante y después lo deja como estaba.")
  slider:SetScript("OnValueChanged", function(self, v)
    v = math.floor(v * 20 + 0.5) / 20
    DB().soundVolume = v
    if txt then txt:SetText(math.floor(v * 100) .. "%") end
  end)
  slider:SetScript("OnMouseUp", function() NS.PlaySoundKey("quest") end)

  local items = {}
  for _, s in ipairs(NS.SOUNDS) do table.insert(items, { s.key, s.t }) end
  local rows = {}
  local y = -176
  for _, e in ipairs(NS.SOUND_EVENTS) do
    local l = S.Font(p:CreateFontString(nil, "ARTWORK"), 12, S.K.parch)
    l:SetPoint("TOPLEFT", 20, y - 6)
    l:SetWidth(250)
    l:SetJustifyH("LEFT")
    l:SetText(e.t)
    local dd = Dropdown(p, 170, items,
      function() return (DB().sounds and DB().sounds[e.key]) or e.def end,
      function(v) DB().sounds = DB().sounds or {}; DB().sounds[e.key] = v; NS.PlaySoundKey(v) end)
    dd:SetPoint("TOPLEFT", 260, y)
    local play = S.SkinButton(CreateFrame("Button", nil, p, "UIPanelButtonTemplate"))
    play:SetSize(70, 24)
    play:SetPoint("LEFT", dd, "RIGHT", 6, 0)
    play:SetText("Probar")
    play:SetScript("OnClick", function() NS.PlaySoundKey((DB().sounds and DB().sounds[e.key]) or e.def) end)
    table.insert(rows, dd)
    y = y - 30
  end

  local reset = S.SkinButton(CreateFrame("Button", nil, p, "UIPanelButtonTemplate"))
  reset:SetSize(200, 26)
  reset:SetPoint("TOPLEFT", 20, y - 10)
  reset:SetText("Volver a los de fábrica")
  reset:SetScript("OnClick", function()
    DB().sounds = nil; DB().soundChannel = nil; DB().noSound = nil; DB().soundVolume = nil
    slider:SetValue(0.5)
    for _, dd in ipairs(rows) do dd.refresh() end
    chan.refresh(); master:SetChecked(true)
  end)

  p:SetScript("OnShow", function()
    master:SetChecked(not DB().noSound)
    slider:SetValue(DB().soundVolume or 0.5)
    chan.refresh()
    for _, dd in ipairs(rows) do dd.refresh() end
  end)

  if Settings and Settings.RegisterCanvasLayoutSubcategory and parentCategory then
    Settings.RegisterCanvasLayoutSubcategory(parentCategory, p, p.name)
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(p)
  end
  NS.soundPanel = p
end
