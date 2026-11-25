-- Códice de Piolin: interfaz con estilo WoW y colores de chamán
-- Reemplaza la ventana de texto por un panel con navegación de íconos, tarjetas, barras e íconos del juego.
local ADDON, NS = ...

local W, H = 780, 570
local NAV_W = 172
local CW = W - NAV_W - 66          -- ancho útil del contenido
local TITLE_FONT = "Fonts\\MORPHEUS.TTF"
local BODY_FONT = "Fonts\\FRIZQT__.TTF"
local BD = BackdropTemplateMixin and "BackdropTemplate" or nil
local WHITE = "Interface\\Buttons\\WHITE8X8"

-- Paleta: azul chamán + los cuatro elementos
local K = {
  gold = { 1, 0.82, 0 }, parch = { 0.93, 0.88, 0.76 }, mute = { 0.6, 0.66, 0.76 }, dim = { 0.45, 0.48, 0.55 },
  blue = { 0.0, 0.44, 0.87 }, water = { 0.3, 0.66, 1 }, air = { 0.72, 0.94, 1 }, earth = { 0.72, 0.52, 0.26 },
  fire = { 1, 0.48, 0.14 }, nature = { 0.45, 0.85, 0.35 }, ok = { 0.5, 0.86, 0.4 }, warn = { 1, 0.62, 0.25 }, bad = { 1, 0.36, 0.34 },
}
local TAB_STYLE = {
  personaje = { K.blue, "Interface\\Icons\\Spell_Nature_BloodLust" },
  misiones = { K.gold, "Interface\\Icons\\INV_Misc_Note_01" },
  ruta = { K.earth, "Interface\\Icons\\INV_Misc_Map_01" },
  pesca = { K.water, "Interface\\Icons\\Trade_Fishing" },
  oficios = { K.nature, "Interface\\Icons\\Trade_LeatherWorking" },
  combate = { K.fire, "Interface\\Icons\\Spell_Nature_LightningShield" },
  campamento = { K.fire, "Interface\\Icons\\Ability_Mount_MountainRam" },
  notas = { K.air, "Interface\\Icons\\INV_Misc_Book_11" },
}
-- Tipos de tarea: etiqueta, color e ícono
local TAGS = {
  quest = { "Misión", K.gold, "Interface\\Icons\\INV_Misc_Note_01" },
  dungeon = { "Mazmorra", K.bad, "Interface\\Icons\\INV_Misc_Bone_ElfSkull_01" },
  buy = { "Comprar", { 1, 0.85, 0.35 }, "Interface\\Icons\\INV_Misc_Coin_01" },
  train = { "Entrenar", K.water, "Interface\\Icons\\INV_Misc_Book_09" },
  craft = { "Oficio", K.nature, "Interface\\Icons\\Trade_LeatherWorking" },
  fish = { "Pesca", K.air, "Interface\\Icons\\Trade_Fishing" },
  talent = { "Talento", { 0.75, 0.55, 1 }, "Interface\\Icons\\Spell_Nature_Lightning" },
  gear = { "Equipo", K.warn, "Interface\\Icons\\INV_Chest_Leather_09" },
  goal = { "Meta", K.blue, "Interface\\Icons\\Ability_Mount_MountainRam" },
}

local function DB() return PiolinCodexDB end
local function C3(c, a) return c[1], c[2], c[3], a or 1 end

local function Grad(tex, orient, c1, a1, c2, a2)
  tex:SetTexture(WHITE)
  local ok = CreateColor and pcall(tex.SetGradient, tex, orient, CreateColor(c1[1], c1[2], c1[3], a1), CreateColor(c2[1], c2[2], c2[3], a2))
  if not ok then
    if tex.SetGradientAlpha then tex:SetGradientAlpha(orient, c1[1], c1[2], c1[3], a1, c2[1], c2[2], c2[3], a2)
    else tex:SetColorTexture(c2[1], c2[2], c2[3], a2) end
  end
end

local function Text(parent, size, color, font, layer)
  local fs = parent:CreateFontString(nil, layer or "OVERLAY")
  fs:SetFont(font or BODY_FONT, size, "")
  fs:SetShadowOffset(1, -1)
  fs:SetShadowColor(0, 0, 0, 0.9)
  fs:SetJustifyH("LEFT")
  fs:SetTextColor(C3(color or K.parch))
  return fs
end

local function Icon(parent, path, size, layer)
  local t = parent:CreateTexture(nil, layer or "ARTWORK")
  t:SetSize(size, size)
  t:SetTexture(path)
  t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  return t
end

-- Ícono con el marco de los botones de acción del juego
local function Framed(parent, path, size, layer)
  local ic = Icon(parent, path, size, layer)
  local fr = parent:CreateTexture(nil, "OVERLAY")
  fr:SetTexture("Interface\\Buttons\\UI-Quickslot2")
  fr:SetSize(size * 1.72, size * 1.72)
  fr:SetPoint("CENTER", ic, "CENTER", 0, 0)
  ic.frameTex = fr
  local oShow, oHide, oShown = ic.Show, ic.Hide, ic.SetShown
  ic.Show = function(self) oShow(self); fr:Show() end
  ic.Hide = function(self) oHide(self); fr:Hide() end
  ic.SetShown = function(self, v) oShown(self, v); fr:SetShown(v) end
  return ic
end

local function Panel(parent, bg, bgA, border, borderA, edge)
  local f = CreateFrame("Frame", nil, parent, BD)
  f:SetBackdrop({ bgFile = WHITE, edgeFile = edge or "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  f:SetBackdropColor(bg[1], bg[2], bg[3], bgA or 0.85)
  f:SetBackdropBorderColor(border[1], border[2], border[3], borderA or 0.9)
  return f
end

local function Bar(parent, w, h, color)
  local b = CreateFrame("StatusBar", nil, parent)
  b:SetSize(w, h)
  b:SetStatusBarTexture(h >= 12 and "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar" or "Interface\\TargetingFrame\\UI-StatusBar")
  if h >= 12 then
    local border = b:CreateTexture(nil, "OVERLAY", nil, 1)
    border:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder")
    border:SetPoint("TOPLEFT", -5, 6)
    border:SetPoint("BOTTOMRIGHT", 5, -6)
  end
  b:SetStatusBarColor(C3(color))
  b:SetMinMaxValues(0, 1)
  b:SetValue(0)
  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0, 0, 0, 0.55)
  local edge = b:CreateTexture(nil, "OVERLAY")
  edge:SetPoint("TOPLEFT", -1, 1)
  edge:SetPoint("BOTTOMRIGHT", 1, -1)
  edge:SetColorTexture(1, 1, 1, 0.06)
  b.text = Text(b, math.max(9, h - 3), K.parch)
  b._SetValue = b.SetValue
  b.SetValue = function(self, v)
    local cur = rawget(self, "_cur")
    self._cur = v
    if cur == nil or not NS.AnimBar or not self:IsVisible() or math.abs(v - cur) < 1e-6 then self:_SetValue(v); return end
    NS.AnimBar(self, cur, v)
  end
  b.text:SetPoint("CENTER", 0, 0)
  b.text:SetJustifyH("CENTER")
  return b
end

local function Pill(parent, label, color)
  local p = Panel(parent, { color[1] * 0.25, color[2] * 0.25, color[3] * 0.25 }, 0.9, color, 0.8)
  p.text = Text(p, 9, color)
  p.text:SetPoint("CENTER", 0, 0)
  p.text:SetText(label:upper())
  p:SetSize(math.max(54, p.text:GetStringWidth() + 16), 16)
  return p
end

local function Tooltip(frame, title, lines)
  frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(title, C3(K.gold))
    for _, l in ipairs(lines or {}) do GameTooltip:AddLine(l, 1, 1, 1, true) end
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave", GameTooltip_Hide)
end

local function ItemIcon(id)
  if C_Item and C_Item.GetItemIconByID then return C_Item.GetItemIconByID(id) end
  return GetItemIcon and GetItemIcon(id) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Clasifica cada tarea para darle ícono y etiqueta
local function TagFor(tabKey, id, text)
  local t = (text or ""):lower()
  if tabKey == "personaje" then
    if id and id:find("^eq") then return "gear" end
    return "talent"
  elseif tabKey == "misiones" then
    if id and id:find("^dm") then return "dungeon" end
    if id and id:find("^tr") then return "train" end
    if id and id:find("^ah") then return "buy" end
    return "quest"
  elseif tabKey == "pesca" then
    if t:find("libro") or t:find("receta") or t:find("leer") then return "buy" end
    return "fish"
  elseif tabKey == "oficios" then
    return "craft"
  elseif tabKey == "campamento" then
    return "goal"
  end
  if t:find("gnomeregan") or t:find("horado") or t:find("monasterio") or t:find("uldaman") or t:find("mazmorra")
    or t:find("maraudon") or t:find("zul'farrak") or t:find("templo") or t:find("cumbre") or t:find("profundidades") then return "dungeon" end
  if t:find("equitaci") or t:find("montura") then return "goal" end
  if t:find("entren") or t:find("instructor") then return "train" end
  if t:find("compr") or t:find("subasta") then return "buy" end
  return "quest"
end

----------------------------------------------------------------------
-- Ventana
----------------------------------------------------------------------
local frame, nav, pages, cards = nil, {}, {}, {}
NS.cbById = NS.cbById or {}
NS.checks = NS.checks or {}

local function CountIds(ids)
  local d = 0
  for _, id in ipairs(ids) do if DB().checks[id] then d = d + 1 end end
  return d, #ids
end

function NS.UpdateProgress()
  if not frame then return end
  local td, tn = 0, 0
  for i, tab in ipairs(NS.TABS) do
    local d, n = CountIds(NS.checks[tab.key] or {})
    td, tn = td + d, tn + n
    local b = nav[i]
    if b then
      if n > 0 then
        b.count:SetText(d == n and "|cff7fd16a✔|r" or (d .. "/" .. n))
      else
        b.count:SetText("")
      end
    end
  end
  for _, c in ipairs(cards) do
    local d, n = CountIds(c.ids)
    if n > 0 then
      c.progText:SetText(d .. "/" .. n)
      c.progBar:SetValue(d / n)
      local done = d == n
      if c.wasDone == false and done and NS.AnimSection then NS.AnimSection(c.title, n) end
      c.wasDone = done
      if d == n then c.progText:SetTextColor(C3(K.ok)) else c.progText:SetTextColor(C3(K.mute)) end
    end
  end
  local pct = tn > 0 and td / tn or 0
  frame.pctText:SetText(math.floor(pct * 100 + 0.5) .. "%")
  frame.pctBar:SetValue(pct)
end

----------------------------------------------------------------------
-- Maquetado de una página
----------------------------------------------------------------------
local function NewPage(tab, parent)
  local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", NAV_W + 30, -100)
  scroll.__a = { NAV_W + 30, -100, -36, 18 }
  scroll:SetPoint("BOTTOMRIGHT", -36, 18)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetSize(CW, 10)
  scroll:SetScrollChild(child)
  scroll:Hide()
  local P = { y = 0, child = child, scroll = scroll, live = {}, blocks = {}, top = 0 }

  -- Cada bloque (tarjeta, fila de fichas, aviso) se puede reubicar al plegar una tarjeta
  function P:Push(h, ...)
    table.insert(self.blocks, { h = h, frames = { ... } })
  end
  function P:Relayout()
    local y = self.top
    for _, b in ipairs(self.blocks) do
      for _, f in ipairs(b.frames) do
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", f.__x or 0, y)
      end
      local h = b.card and (b.card.__collapsed and 34 or b.card.__full) or b.h
      y = y - h - 10
    end
    child:SetHeight(-y + 20)
  end
  NS.checks[tab.key] = NS.checks[tab.key] or {}

  function P:Gap(n) self.y = self.y - (n or 10) end

  function P:Heading(text, lead, color, icon, accent)
    accent = accent or K.blue
    local band = child:CreateTexture(nil, "BACKGROUND", nil, 1)
    band:SetPoint("TOPLEFT", 0, self.y + 2)
    band:SetSize(CW, 52)
    Grad(band, "HORIZONTAL", accent, 0.30, accent, 0.0)
    local x = 4
    if icon then
      local ic = Framed(child, icon, 36)
      ic:SetPoint("TOPLEFT", 8, self.y - 6)
      x = 58
    end
    local t = Text(child, 21, color or K.gold, TITLE_FONT)
    t:SetPoint("TOPLEFT", x, self.y - 4)
    t:SetText(text)
    local l = Text(child, 11, K.mute)
    l:SetPoint("TOPLEFT", x + 1, self.y - 30)
    l:SetWidth(CW - x - 6)
    l:SetText(lead or "")
    local lh = math.max(14, (lead and lead ~= "") and l:GetStringHeight() or 0)
    self.y = self.y - math.max(52, 32 + lh + 4)
    local br = child:CreateTexture(nil, "ARTWORK")
    br:SetTexture("Interface\\QuestFrame\\UI-HorizontalBreak")
    br:SetPoint("TOPLEFT", -10, self.y + 6)
    br:SetSize(CW + 20, 28)
    br:SetAlpha(0.8)
    self.y = self.y - 14
    self.top = self.y
  end

  -- Tarjeta con encabezado (ícono, título, progreso opcional)
  function P:Card(title, icon, color, opts)
    opts = opts or {}
    local c = Panel(child, { 0.05, 0.08, 0.14 }, 0.92, opts.highlight and K.blue or { 0.35, 0.42, 0.55 }, opts.highlight and 1 or 0.7)
    c:SetPoint("TOPLEFT", 0, self.y)
    c:SetWidth(CW)
    local glow = c:CreateTexture(nil, "BACKGROUND", nil, 1)
    glow:SetPoint("TOPLEFT", 4, -4)
    glow:SetPoint("TOPRIGHT", -4, -4)
    glow:SetHeight(30)
    Grad(glow, "VERTICAL", color, 0, color, 0.18)
    local fold = CreateFrame("Button", nil, c)
    fold:SetSize(16, 16)
    fold:SetPoint("TOPLEFT", 10, -11)
    fold:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
    fold:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
    fold:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
    c.fold = fold
    local x = 34
    if icon then
      local ic = Framed(c, icon, 22)
      ic:SetPoint("TOPLEFT", 34, -8)
      x = 64
    end
    local t = Text(c, 15, K.gold, TITLE_FONT)
    t:SetPoint("TOPLEFT", x, -12)
    t:SetText(title)
    c.foldKey = (tab.key or "") .. ":" .. title
    local C = { y = -40, frame = c, ids = {}, page = self, title = title }
    if opts.badge then
      local b = Pill(c, opts.badge, opts.badgeColor or color)
      b:SetPoint("LEFT", t, "RIGHT", 10, 0)
    end
    if opts.here then
      local h = Pill(c, "Estás acá", K.blue)
      h:SetPoint("LEFT", t, "RIGHT", opts.badge and 80 or 10, 0)
    end
    if opts.progress then
      C.progBar = Bar(c, 70, 6, color)
      C.progBar:SetPoint("TOPRIGHT", -14, -18)
      C.progBar.text:Hide()
      C.progText = Text(c, 10, K.mute)
      C.progText:SetPoint("RIGHT", C.progBar, "LEFT", -6, 0)
      table.insert(cards, C)
    end
    local line = c:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", 10, -36)
    line:SetPoint("TOPRIGHT", -10, -36)
    line:SetHeight(1)
    line:SetColorTexture(color[1], color[2], color[3], 0.35)

    function C:Gap(n) self.y = self.y - (n or 6) end
    function C:Text(text, size, col, indent)
      local fs = Text(c, size or 11, col or K.parch)
      fs:SetPoint("TOPLEFT", indent or 14, self.y)
      fs:SetWidth(CW - (indent or 14) - 14)
      fs:SetSpacing(2)
      fs:SetText(text)
      self.y = self.y - math.max(fs:GetStringHeight(), (size or 11) + 3) - 6
      return fs
    end
    -- Fila de tarea: casilla, ícono por tipo, texto, etiqueta, botón Ir
    function C:Task(id, text, tagKey)
      local tag = TAGS[tagKey] or TAGS.quest
      local row = CreateFrame("Button", nil, c)
      row:SetPoint("TOPLEFT", 8, self.y)
      row:SetWidth(CW - 16)
      local hl = row:CreateTexture(nil, "HIGHLIGHT")
      hl:SetAllPoints()
      hl:SetColorTexture(1, 1, 1, 0.05)
      local slot = row:CreateTexture(nil, "ARTWORK")
      row.slotTex = slot
      slot:SetSize(20, 20)
      slot:SetPoint("TOPLEFT", 4, -2)
      slot:SetTexture("Interface\\Buttons\\UI-EmptySlot")
      slot:SetTexCoord(0.2, 0.8, 0.2, 0.8)
      local tick = row:CreateTexture(nil, "OVERLAY")
      tick:SetSize(18, 18)
      tick:SetPoint("CENTER", slot, 0, 0)
      tick:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
      local ic = Icon(row, tag[3], 18)
      ic:SetPoint("LEFT", slot, "RIGHT", 6, 0)
      local wp = id and NS.WAYPOINTS and NS.WAYPOINTS[id]
      local fs = Text(row, 11.5, K.parch)
      fs:SetPoint("TOPLEFT", 54, -4)
      local isQuest = id and NS.AUTO and NS.AUTO.quest and NS.AUTO.quest[id]
      fs:SetWidth(CW - 16 - 54 - 74 - (wp and 26 or 0) - (isQuest and 78 or 0))
      fs:SetSpacing(2)
      fs:SetText(text)
      local pill = Pill(row, tag[1], tag[2])
      pill:SetPoint("TOPRIGHT", -4, -3)
      row.qtext = Text(row, 9, K.water)
      row.qtext:SetPoint("RIGHT", pill, "LEFT", -6, 0)
      row.qtext:SetJustifyH("RIGHT")
      if wp then
        local go = CreateFrame("Button", nil, row)
        go:SetSize(20, 20)
        go:SetPoint("RIGHT", pill, "LEFT", -6, 0)
        local gi = Icon(go, "Interface\\Icons\\INV_Misc_Map_01", 20)
        gi:SetAllPoints()
        go:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        go:SetScript("OnClick", function() if NS.GoTo then NS.GoTo(wp) end end)
        Tooltip(go, wp[4], { "Coordenadas " .. wp[2] .. ", " .. wp[3], TomTom and "Clic: flecha de TomTom" or "Clic: coordenadas en el chat" })
      end
      local h = math.max(26, fs:GetStringHeight() + 10)
      self.zebra = not self.zebra
      if self.zebra then
        local z = row:CreateTexture(nil, "BACKGROUND")
        z:SetAllPoints()
        z:SetColorTexture(1, 1, 1, 0.025)
      end
      row:SetHeight(h)
      row.checked = DB().checks[id] and true or false
      function row:GetChecked() return self.checked end
      function row:SetChecked(v) self.checked = v and true or false end
      row.paint = function()
        tick:SetShown(row.checked)
        if row.checked then
          fs:SetTextColor(C3(K.dim)); ic:SetDesaturated(true); ic:SetAlpha(0.5)
        else
          fs:SetTextColor(C3(K.parch)); ic:SetDesaturated(false); ic:SetAlpha(1)
        end
      end
      row:SetScript("OnClick", function(self)
        self.checked = not self.checked
        DB().checks[id] = self.checked or nil
        self.paint()
        if self.checked then NS.Sound("tick"); if NS.AnimTick then NS.AnimTick(self) end end
        NS.UpdateProgress()
      end)
      row.paint()
      NS.cbById[id] = row
      table.insert(NS.checks[tab.key], id)
      table.insert(self.ids, id)
      self.y = self.y - h - 2
      return row
    end
    -- Línea informativa con viñeta de rombo
    function C:Note(text)
      local d = c:CreateTexture(nil, "ARTWORK")
      d:SetSize(8, 8)
      d:SetPoint("TOPLEFT", 16, self.y - 4)
      d:SetColorTexture(C3(color))
      d:SetRotation(math.rad(45))
      return self:Text(text, 11.5, K.parch, 32)
    end
    function C:Finish()
      c.__full = -self.y + 10
      c:SetHeight(c.__full)
      local page = self.page
      table.insert(page.blocks, { card = c, frames = { c } })
      local function apply()
        local col = c.__collapsed
        c:SetHeight(col and 34 or c.__full)
        if c.SetClipsChildren then c:SetClipsChildren(col and true or false) end
        local tex = col and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up"
        c.fold:SetNormalTexture(tex)
        c.fold:SetPushedTexture(col and "Interface\\Buttons\\UI-PlusButton-Down" or "Interface\\Buttons\\UI-MinusButton-Down")
      end
      DB().folded = DB().folded or {}
      c.__collapsed = DB().folded[c.foldKey] and true or false
      apply()
      c.fold:SetScript("OnClick", function()
        c.__collapsed = not c.__collapsed
        DB().folded[c.foldKey] = c.__collapsed or nil
        apply()
        page:Relayout()
      end)
      self.page.y = self.page.y + self.y - 10 - 10
    end
    return C
  end

  function P:Finish() self:Relayout() end
  return P
end

----------------------------------------------------------------------
-- Bloques en vivo
----------------------------------------------------------------------
local function Tile(parent, x, y, w, icon, label, color)
  local t = Panel(parent, { 0.05, 0.08, 0.14 }, 0.92, color, 0.75)
  t:SetPoint("TOPLEFT", x, y)
  t.__x = x
  t:SetSize(w, 78)
  local g = t:CreateTexture(nil, "BACKGROUND", nil, 1)
  g:SetPoint("TOPLEFT", 4, -4); g:SetPoint("BOTTOMRIGHT", -4, 4)
  Grad(g, "VERTICAL", color, 0.02, color, 0.16)
  local ic = Framed(t, icon, 28)
  ic:SetPoint("TOPLEFT", 11, -11)
  t.label = Text(t, 10, K.mute)
  t.label:SetPoint("TOPLEFT", 48, -10)
  t.label:SetText(label:upper())
  t.value = Text(t, 22, K.parch, TITLE_FONT)
  t.value:SetPoint("TOPLEFT", 48, -24)
  t.sub = Text(t, 10, K.mute)
  t.sub:SetPoint("BOTTOMLEFT", 10, 18)
  t.bar = Bar(t, w - 20, 6, color)
  t.bar:SetPoint("BOTTOMLEFT", 10, 9)
  t.bar.text:Hide()
  return t
end

local PROFS = {
  { "Pesca", "Interface\\Icons\\Trade_Fishing", K.water },
  { "Cocina", "Interface\\Icons\\INV_Misc_Food_15", K.fire },
  { "Desuello", "Interface\\Icons\\INV_Misc_Pelt_Wolf_01", K.earth },
  { "Peletería", "Interface\\Icons\\Trade_LeatherWorking", K.nature },
  { "Primeros auxilios", "Interface\\Icons\\Spell_Holy_SealOfSacrifice", K.bad },
}

local function BuildCharLive(P)
  local L = P.live
  local tw = math.floor((CW - 20) / 3)
  L.lvl = Tile(P.child, 0, P.y, tw, "Interface\\Icons\\Spell_Nature_BloodLust", "Nivel", K.blue)
  L.tal = Tile(P.child, tw + 10, P.y, tw, "Interface\\Icons\\Spell_Nature_Lightning", "Talentos", { 0.75, 0.55, 1 })
  L.gold = Tile(P.child, (tw + 10) * 2, P.y, tw, "Interface\\Icons\\INV_Misc_Coin_02", "Oro", K.gold)
  P:Push(78, L.lvl, L.tal, L.gold)
  P.y = P.y - 88

  -- banner "Ahora te toca"
  local b = Panel(P.child, { 0.02, 0.18, 0.38 }, 0.9, K.water, 0.9)
  b:SetPoint("TOPLEFT", 0, P.y)
  b:SetSize(CW, 46)
  local bi = Icon(b, "Interface\\Icons\\Spell_Nature_Windfury", 28)
  bi:SetPoint("LEFT", 10, 0)
  local bt = Text(b, 10, K.air)
  bt:SetPoint("TOPLEFT", 46, -8)
  bt:SetText("AHORA TE TOCA")
  L.hint = Text(b, 12, K.parch)
  L.hint:SetPoint("TOPLEFT", 46, -21)
  L.hint:SetWidth(CW - 60)
  P:Push(46, b)
  P.y = P.y - 56

  -- equipo
  local C = P:Card("Tu equipo", "Interface\\Icons\\INV_Chest_Leather_09", K.warn)
  L.dur = Bar(C.frame, 120, 12, K.ok)
  L.dur:SetPoint("TOPRIGHT", -14, -14)
  local dl = Text(C.frame, 10, K.mute)
  dl:SetPoint("RIGHT", L.dur, "LEFT", -6, 0)
  dl:SetText("Durabilidad")
  L.slots = {}
  local SLOT_NAMES = { [1] = "HeadSlot", [2] = "NeckSlot", [3] = "ShoulderSlot", [15] = "BackSlot", [5] = "ChestSlot",
    [9] = "WristSlot", [10] = "HandsSlot", [6] = "WaistSlot", [7] = "LegsSlot", [8] = "FeetSlot", [11] = "Finger0Slot",
    [12] = "Finger1Slot", [13] = "Trinket0Slot", [14] = "Trinket1Slot", [16] = "MainHandSlot", [18] = "RangedSlot" }
  local size, gap, vgap = 34, 22, 18
  for i, s in ipairs(NS.SLOTS) do
    local col, rowi = (i - 1) % 8, math.floor((i - 1) / 8)
    local btn = CreateFrame("Button", nil, C.frame)
    btn:SetSize(size, size)
    btn:SetPoint("TOPLEFT", 14 + col * (size + gap), C.y - rowi * (size + vgap))
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetPoint("CENTER")
    btn.bg:SetSize(size * 1.72, size * 1.72)
    btn.bg:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    local _, emptyTex = GetInventorySlotInfo(SLOT_NAMES[s[1]] or "HeadSlot")
    btn.empty = emptyTex
    btn.qual = btn:CreateTexture(nil, "OVERLAY", nil, 2)
    btn.qual:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    btn.qual:SetBlendMode("ADD")
    btn.qual:SetSize(size * 1.8, size * 1.8)
    btn.qual:SetPoint("CENTER")
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetPoint("TOPLEFT", 2, -2); btn.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.warn = btn:CreateTexture(nil, "OVERLAY")
    btn.warn:SetAllPoints()
    btn.warn:SetColorTexture(1, 0.15, 0.15, 0.22)
    btn.cap = Text(C.frame, 8, K.dim)
    btn.cap:SetPoint("TOP", btn, "BOTTOM", 0, -1)
    btn.cap:SetText(s[2])
    btn.slot = s[1]
    btn:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      if GetInventoryItemID("player", self.slot) then GameTooltip:SetInventoryItem("player", self.slot)
      else GameTooltip:AddLine(s[2], C3(K.gold)); GameTooltip:AddLine("Ranura vacía", 1, 0.4, 0.4) end
      GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)
    L.slots[i] = btn
  end
  C.y = C.y - 2 * (size + vgap)
  L.emptyText = C:Text("", 11, K.warn)
  C:Finish()

  -- oficios
  local O = P:Card("Oficios", "Interface\\Icons\\Trade_LeatherWorking", K.nature)
  L.profs = {}
  for _, pr in ipairs(PROFS) do
    local ic = Framed(O.frame, pr[2], 20)
    ic:SetPoint("TOPLEFT", 14, O.y)
    local n = Text(O.frame, 11.5, K.parch)
    n:SetPoint("TOPLEFT", 42, O.y - 3)
    n:SetText(pr[1])
    local bar = Bar(O.frame, CW - 250, 14, pr[3])
    bar:SetPoint("TOPLEFT", 170, O.y - 3)
    local cap = Pill(O.frame, "Tope", K.bad)
    cap:SetPoint("LEFT", bar, "RIGHT", 8, 0)
    L.profs[pr[1]] = { bar = bar, cap = cap, icon = ic, name = n }
    O.y = O.y - 26
  end
  O:Finish()

  -- objetivos de equipo
  local G = P:Card("Objetivos de equipo", "Interface\\Icons\\INV_Axe_09", K.blue)
  L.goals = {}
  for i = 1, 5 do
    local r = {}
    r.check = G.frame:CreateTexture(nil, "OVERLAY")
    r.check:SetSize(16, 16)
    r.check:SetPoint("TOPLEFT", 14, G.y - 2)
    r.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    r.lvl = Pill(G.frame, "Nv 00", K.water)
    r.lvl:SetPoint("TOPLEFT", 36, G.y - 1)
    r.text = Text(G.frame, 11.5, K.parch)
    r.text:SetPoint("TOPLEFT", 100, G.y - 2)
    r.text:SetWidth(CW - 120)
    L.goals[i] = r
    G.y = G.y - 22
  end
  local hint = G:Text("Sumá piezas propias con /piolin objetivo y shift-clic en el objeto.", 10, K.dim)
  G:Finish()
end

local function RefreshChar(L)
  local level = UnitLevel("player") or 0
  L.lvl.value:SetText(level)
  local xp, xpMax = UnitXP("player") or 0, UnitXPMax("player") or 1
  L.lvl.bar:SetValue(xpMax > 0 and xp / xpMax or 0)
  local rest = GetXPExhaustion and GetXPExhaustion() or 0
  L.lvl.sub:SetText(math.floor(xp / math.max(1, xpMax) * 100) .. "% del nivel" .. ((rest or 0) > 0 and ("  ·  descanso " .. math.floor(rest / math.max(1, xpMax) * 100) .. "%") or ""))
  local free = NS.FreeTalentPoints and NS.FreeTalentPoints()
  if free == nil then
    L.tal.value:SetText("—"); L.tal.value:SetTextColor(C3(K.mute)); L.tal.sub:SetText("el juego no lo informa"); L.tal.bar:SetValue(0)
  else
  L.tal.value:SetText(free)
  if free > 0 then
    L.tal.value:SetTextColor(C3(K.bad)); L.tal.sub:SetText("|cffff6060sin gastar: pasá por el árbol|r"); L.tal.bar:SetValue(1)
  else
    L.tal.value:SetTextColor(C3(K.ok)); L.tal.sub:SetText("todos gastados"); L.tal.bar:SetValue(0)
  end
  end
  local money = GetMoney()
  L.gold.value:SetFont(BODY_FONT, 14, "")
  L.gold.value:SetText(NS.Money(money))
  local pct = math.min(1, money / NS.MOUNT_GOAL)
  L.gold.bar:SetValue(pct)
  L.gold.sub:SetText("montura del 40: " .. math.floor(pct * 100) .. "%")
  for _, h in ipairs(NS.HINTS) do if level <= h.max then L.hint:SetText(h.t); break end end

  local empty = {}
  for i, b in ipairs(L.slots) do
    local tex = GetInventoryItemTexture("player", b.slot)
    b.icon:SetTexture(tex or b.empty)
    b.icon:SetTexCoord(tex and 0.08 or 0, tex and 0.92 or 1, tex and 0.08 or 0, tex and 0.92 or 1)
    b.warn:SetShown(not tex)
    local q = tex and GetInventoryItemQuality and GetInventoryItemQuality("player", b.slot)
    if q and q > 1 and GetItemQualityColor then
      local r, g, bl = GetItemQualityColor(q)
      b.qual:SetVertexColor(r, g, bl, 0.9); b.qual:Show()
    else
      b.qual:Hide()
    end
    b.cap:SetTextColor(C3(tex and K.dim or K.bad))
    if not tex then table.insert(empty, NS.SLOTS[i][2]) end
  end
  L.emptyText:SetText(#empty > 0 and ("Ranuras vacías: " .. table.concat(empty, ", ")) or "|cff7fd16aEquipo completo.|r")
  local dur = NS.Durability and NS.Durability() or 100
  L.dur:SetValue(dur / 100)
  L.dur.text:SetText(dur .. "%")
  L.dur:SetStatusBarColor(C3(dur <= 25 and K.bad or (dur <= 50 and K.warn or K.ok)))

  for name, w in pairs(L.profs) do
    local r, m = NS.Skill(name)
    if r then
      if w.last and r > w.last and NS.AnimFloat then NS.AnimFloat(w.bar, "+" .. (r - w.last) .. " " .. name) end
      w.last = r
      w.bar:SetValue(r / math.max(1, m)); w.bar.text:SetText(r .. " / " .. m)
      w.cap:SetShown(r >= m); w.icon:SetDesaturated(false); w.name:SetTextColor(C3(K.parch))
    else
      w.bar:SetValue(0); w.bar.text:SetText("no lo aprendiste"); w.cap:Hide(); w.icon:SetDesaturated(true); w.name:SetTextColor(C3(K.dim))
    end
  end

  local goals = NS.GoalStatus and NS.GoalStatus() or {}
  for i, r in ipairs(L.goals) do
    local g = goals[i]
    if g then
      r.check:SetShown(g.have); r.lvl:Show(); r.text:Show()
      r.lvl.text:SetText(g.lvl > 0 and ("NV " .. g.lvl) or "TUYO")
      r.text:SetText(g.t)
      r.text:SetTextColor(C3(g.have and K.dim or K.parch))
    else
      r.check:Hide(); r.lvl:Hide(); r.text:Hide()
    end
  end
end

local function BuildMatsLive(P)
  local L = P.live
  local C = P:Card("Tu tramo de Peletería", "Interface\\Icons\\INV_Misc_LeatherScrap_02", K.nature)
  L.recipe = C:Text("", 13, K.gold)
  L.mats = {}
  for i = 1, 4 do
    local m = {}
    m.icon = Framed(C.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 26)
    m.icon:SetPoint("TOPLEFT", 14, C.y)
    m.name = Text(C.frame, 11.5, K.parch)
    m.name:SetPoint("TOPLEFT", 48, C.y - 1)
    m.bar = Bar(C.frame, 200, 12, K.nature)
    m.bar:SetPoint("TOPLEFT", 48, C.y - 15)
    m.need = Text(C.frame, 11, K.warn)
    m.need:SetPoint("LEFT", m.bar, "RIGHT", 10, 0)
    m.icon:SetScript("OnEnter", nil)
    L.mats[i] = m
    C.y = C.y - 36
  end
  L.matsNote = C:Text("Cuenta bolsas y banco.", 10, K.dim)
  C:Finish()
  local b = Panel(P.child, { 0.16, 0.12, 0.05 }, 0.9, K.earth, 0.9)
  b:SetPoint("TOPLEFT", 0, P.y)
  b:SetSize(CW, 50)
  local bi = Icon(b, "Interface\\Icons\\INV_Misc_Pelt_Wolf_01", 30)
  bi:SetPoint("LEFT", 10, 0)
  L.skin = Text(b, 11.5, K.parch)
  L.skin:SetPoint("LEFT", 50, 0)
  L.skin:SetWidth(CW - 64)
  P:Push(50, b)
  P.y = P.y - 60
end

local function RefreshMats(L)
  local tier, rank
  if NS.CurrentTier then tier, rank = NS.CurrentTier() end
  if not tier then
    L.recipe:SetText("No hay un tramo de Peletería cargado para tu nivel.")
    for _, m in ipairs(L.mats) do m.icon:Hide(); m.name:Hide(); m.bar:Hide(); m.need:Hide() end
  else
    L.recipe:SetText((rank or "") .. "  ·  tramo " .. tier.min .. "-" .. tier.max .. ":  " .. tier.recipe)
    local total = 0
    for i, m in ipairs(L.mats) do
      local mat = tier.mats[i]
      if mat then
        local have = GetItemCount(mat[1], true) or 0
        m.icon:SetTexture(ItemIcon(mat[1])); m.icon:Show()
        m.name:SetText(mat[3]); m.name:Show()
        m.bar:SetValue(math.min(1, have / mat[2])); m.bar.text:SetText(have .. " / " .. mat[2]); m.bar:Show()
        m.bar:SetStatusBarColor(C3(have >= mat[2] and K.ok or K.warn))
        if have >= mat[2] then m.need:SetText("|cff7fd16alisto|r")
        else
          local p = NS.Price and NS.Price(mat[1])
          if p then total = total + p * (mat[2] - have) end
          m.need:SetText("faltan " .. (mat[2] - have) .. (p and ("  ·  ~" .. NS.Money(math.floor(p * (mat[2] - have)))) or ""))
        end
        m.need:Show()
      else
        m.icon:Hide(); m.name:Hide(); m.bar:Hide(); m.need:Hide()
      end
    end
    L.matsNote:SetText("Cuenta bolsas y banco." .. (total > 0 and ("   Comprar lo que falta: ~" .. NS.Money(math.floor(total))) or ""))
  end
  local sk = NS.Skill("Desuello")
  local zone
  for _, z in ipairs(NS.SKIN_ZONES or {}) do if sk and sk < z.max then zone = z.t; break end end
  L.skin:SetText(sk and ("|cffffd96aDónde desollar con " .. sk .. ":|r " .. (zone or "cualquier zona de tu nivel")) or "Aprendé Desuello para ver dónde conviene desollar.")
end

local function BuildFishLive(P)
  local L = P.live
  local tw = math.floor((CW - 20) / 3)
  L.casts = Tile(P.child, 0, P.y, tw, "Interface\\Icons\\Trade_Fishing", "Pescas hoy", K.water)
  L.skill = Tile(P.child, tw + 10, P.y, tw, "Interface\\Icons\\INV_Fishingpole_02", "Pesca", K.air)
  L.value = Tile(P.child, (tw + 10) * 2, P.y, tw, "Interface\\Icons\\INV_Misc_Coin_02", "Valor del botín", K.gold)
  P:Push(78, L.casts, L.skill, L.value)
  P.y = P.y - 88
  local C = P:Card("Botín de esta sesión", "Interface\\Icons\\INV_Misc_Fish_06", K.water)
  L.catch = {}
  for i = 1, 6 do
    local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
    local x = 14 + col * math.floor((CW - 28) / 2)
    local r = {}
    r.icon = Framed(C.frame, "Interface\\Icons\\INV_Misc_QuestionMark", 26)
    r.icon:SetPoint("TOPLEFT", x, C.y - row * 32)
    r.text = Text(C.frame, 11.5, K.parch)
    r.text:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
    r.text:SetWidth(math.floor((CW - 28) / 2) - 40)
    L.catch[i] = r
  end
  C.y = C.y - 3 * 32
  L.empty = C:Text("Todavía no pescaste en esta sesión.", 11, K.dim)
  C:Finish()
end

local function RefreshFish(L)
  local f = NS.fish or { casts = 0, items = {}, order = {} }
  L.casts.value:SetText(f.casts)
  L.casts.sub:SetText("en total: " .. (DB().fishTotal or 0))
  L.casts.bar:SetValue(0)
  local r, m = NS.Skill("Pesca")
  L.skill.value:SetText(r and (r .. "|cff8899aa/" .. m .. "|r") or "—")
  L.skill.bar:SetValue(r and r / m or 0)
  L.skill.sub:SetText(r and r >= m - 5 and "|cffff9a40cerca del tope|r" or "subiendo")
  local value = 0
  for i, w in ipairs(L.catch) do
    local id = f.order[i]
    if id then
      local it = f.items[id]
      local p = (NS.Price and NS.Price(id)) or select(11, GetItemInfo(id)) or 0
      value = value + p * it.n
      w.icon:SetTexture(ItemIcon(id)); w.icon:Show()
      w.text:SetText("|cffffd96a" .. it.n .. "x|r " .. (it.link or id)); w.text:Show()
    else
      w.icon:Hide(); w.text:Hide()
    end
  end
  for i = #L.catch + 1, #f.order do
    local it = f.items[f.order[i]]
    local p = (NS.Price and NS.Price(f.order[i])) or 0
    value = value + p * it.n
  end
  L.value.value:SetText(NS.Money(math.floor(value)))
  L.value.value:SetFont(BODY_FONT, 13, "")
  L.value.sub:SetText("subasta o vendedor")
  L.value.bar:SetValue(0)
  L.empty:SetShown(f.casts == 0)
end

local function BuildCampLive(P)
  local L = P.live
  local C = P:Card("Ahorro para la montura del 40", "Interface\\Icons\\Ability_Mount_MountainRam", K.gold)
  L.money = C:Text("", 13, K.parch)
  L.mount = Bar(C.frame, CW - 28, 18, K.gold)
  L.mount:SetPoint("TOPLEFT", 14, C.y)
  C.y = C.y - 26
  L.session = C:Text("", 11, K.mute)
  C:Finish()
  local T = P:Card("Tienda de campaña", "Interface\\Icons\\INV_Misc_Bag_09", K.nature)
  L.tent = T:Text("", 12, K.parch)
  L.tentBar = Bar(T.frame, CW - 28, 10, K.nature)
  L.tentBar:SetPoint("TOPLEFT", 14, T.y)
  L.tentBar.text:Hide()
  T.y = T.y - 18
  T:Text("Se detecta sola al ponerla. Si no, escribí /piolin tienda.", 10, K.dim)
  T:Finish()
end

local function RefreshCamp(L)
  local money = GetMoney()
  local pct = math.min(1, money / NS.MOUNT_GOAL)
  L.money:SetText(NS.Money(money) .. "  |cff8899aade|r  " .. NS.Money(NS.MOUNT_GOAL))
  L.mount:SetValue(pct)
  L.mount.text:SetText(math.floor(pct * 100) .. "%")
  if NS.sessionMoney then
    local d = money - NS.sessionMoney
    L.session:SetText("En esta sesión: " .. (d >= 0 and "|cff7fd16a+|r" or "|cffff6060-|r") .. NS.Money(math.abs(d)))
  end
  if DB().tentAt then
    local left = 3600 - (time() - DB().tentAt)
    if left > 0 then
      L.tent:SetText("Disponible en |cffffd96a" .. math.ceil(left / 60) .. " min|r")
      L.tentBar:SetValue(1 - left / 3600)
    else
      L.tent:SetText("|cff7fd16a¡Disponible! Podés volver a ponerla.|r"); L.tentBar:SetValue(1)
    end
  else
    L.tent:SetText("Sin usar todavía."); L.tentBar:SetValue(0)
  end
end

----------------------------------------------------------------------
-- Páginas especiales
----------------------------------------------------------------------
local ROTATION = {
  { "Interface\\Icons\\Spell_Nature_LightningShield", "Escudo" },
  { "Interface\\Icons\\Spell_Fire_FlameTounge", "Imbuir" },
  { "Interface\\Icons\\Spell_Fire_FlameShock", "Choque de llamas" },
  { "Interface\\Icons\\Ability_Shaman_Stormstrike", "Golpe de tormenta" },
  { "Interface\\Icons\\Spell_Nature_EarthShock", "Choque de tierra" },
}

local function BuildRotation(P, color)
  local C = P:Card("Rotación de un vistazo", "Interface\\Icons\\Ability_Shaman_Stormstrike", color)
  local step = math.floor((CW - 28) / #ROTATION)
  for i, r in ipairs(ROTATION) do
    local x = 14 + (i - 1) * step + math.floor((step - 40) / 2)
    local ic = Framed(C.frame, r[1], 38)
    ic:SetPoint("TOPLEFT", x, C.y)
    local n = Text(C.frame, 12, K.gold, TITLE_FONT)
    n:SetPoint("TOPLEFT", ic, "TOPLEFT", -6, 6)
    n:SetText(i)
    local cap = Text(C.frame, 10, K.parch)
    cap:SetPoint("TOP", ic, "BOTTOM", 0, -4)
    cap:SetWidth(step - 4)
    cap:SetJustifyH("CENTER")
    cap:SetText(r[2])
    if i < #ROTATION then
      local a = Text(C.frame, 22, K.gold, TITLE_FONT)
      a:SetPoint("LEFT", ic, "RIGHT", math.floor((step - 40) / 2) - 8, 0)
      a:SetText("›")
    end
  end
  C.y = C.y - 70
  C:Text("Antes de tirar: escudo e imbuición. Después Choque de llamas, golpes y Golpe de tormenta cuando esté listo. Choque de tierra para cortar hechizos.", 10.5, K.mute)
  C:Finish()
end

local function BuildMacros(P, color)
  local C = P:Card("Macros", "Interface\\Icons\\INV_Misc_Note_02", color)
  local btn = CreateFrame("Button", nil, C.frame, "UIPanelButtonTemplate")
  btn:SetSize(130, 22)
  btn:SetPoint("TOPRIGHT", -12, -9)
  btn:SetText("Crear macros")
  btn:SetScript("OnClick", NS.CreateMacros)
  local icons = { "Interface\\Icons\\Spell_Nature_LightningShield", "Interface\\Icons\\Spell_Fire_FlameShock", "Interface\\Icons\\Spell_Nature_EarthShock",
    "Interface\\Icons\\Spell_Nature_HealingWaveLesser", "Interface\\Icons\\Ability_Shaman_Stormstrike" }
  local colW = math.floor((CW - 36) / 2)
  local startY = C.y
  for i, m in ipairs(NS.MACROS) do
    local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
    local tile = Panel(C.frame, { 0.03, 0.05, 0.09 }, 0.9, { 0.3, 0.36, 0.48 }, 0.7)
    tile:SetPoint("TOPLEFT", 12 + col * (colW + 12), startY - row * 50)
    tile:SetSize(colW, 44)
    local ic = Framed(tile, icons[i] or "Interface\\Icons\\INV_Misc_QuestionMark", 28)
    ic:SetPoint("LEFT", 8, 0)
    local n = Text(tile, 12, K.gold)
    n:SetPoint("TOPLEFT", 46, -8)
    n:SetText(m.name)
    local body = m.body:gsub("\n", "  ")
    local b = Text(tile, 9, K.mute)
    b:SetPoint("TOPLEFT", 46, -24)
    b:SetWidth(colW - 54)
    b:SetWordWrap(false)
    b:SetText(body)
    tile:EnableMouse(true)
    Tooltip(tile, m.name, { (m.body:gsub("\n", "\n")) })
  end
  C.y = startY - math.ceil(#NS.MACROS / 2) * 50
  C:Text("Abrí /macro y arrastrá cada una a tu barra. Pasá el mouse para ver el texto completo.", 10, K.dim)
  C:Finish()
end

local function BuildNotes(tab, parent)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetPoint("TOPLEFT", NAV_W + 30, -100)
  holder.__a = { NAV_W + 30, -100, -18, 18 }
  holder:SetPoint("BOTTOMRIGHT", -18, 18)
  holder:Hide()
  local t = Text(holder, 20, K.gold, TITLE_FONT)
  t:SetPoint("TOPLEFT", 2, 0)
  t:SetText("Notas")
  local l = Text(holder, 11, K.mute)
  l:SetPoint("TOPLEFT", 2, -26)
  l:SetText(tab.lead)
  local paper = Panel(holder, { 0.86, 0.78, 0.6 }, 1, K.earth, 1, "Interface\\DialogFrame\\UI-DialogBox-Border")
  paper:SetPoint("TOPLEFT", 0, -48)
  paper:SetPoint("BOTTOMRIGHT", 0, 0)
  paper:SetBackdrop({ bgFile = WHITE, edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24, insets = { left = 6, right = 6, top = 6, bottom = 6 } })
  paper:SetBackdropColor(0.86, 0.78, 0.6, 1)
  local st1 = paper:CreateTexture(nil, "BACKGROUND", nil, 2)
  st1:SetPoint("TOPLEFT", 6, -6); st1:SetPoint("BOTTOMRIGHT", paper, "BOTTOM", 0, 6)
  st1:SetTexture("Interface\\Stationery\\StationeryTest1")
  local st2 = paper:CreateTexture(nil, "BACKGROUND", nil, 2)
  st2:SetPoint("TOPLEFT", paper, "TOP", 0, -6); st2:SetPoint("BOTTOMRIGHT", -6, 6)
  st2:SetTexture("Interface\\Stationery\\StationeryTest2")
  local scroll = CreateFrame("ScrollFrame", nil, paper, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 16, -16)
  scroll:SetPoint("BOTTOMRIGHT", -32, 14)
  local eb = CreateFrame("EditBox", nil, scroll)
  eb:SetMultiLine(true)
  eb:SetFont(BODY_FONT, 13, "")
  eb:SetTextColor(0.24, 0.15, 0.07)
  eb:SetWidth(CW - 60)
  eb:SetAutoFocus(false)
  eb:SetText(DB().notes or "")
  eb:SetScript("OnTextChanged", function(self) DB().notes = self:GetText() end)
  eb:SetScript("OnEscapePressed", eb.ClearFocus)
  scroll:SetScrollChild(eb)
  scroll:SetScript("OnMouseDown", function() eb:SetFocus() end)
  return holder
end

----------------------------------------------------------------------
-- Construcción de cada pestaña
----------------------------------------------------------------------
local function BuildPage(tab, parent)
  if tab.notes then return BuildNotes(tab, parent) end
  local style = TAB_STYLE[tab.key] or { K.gold, tab.icon }
  local color = style[1]
  local P = NewPage(tab, parent)
  P:Heading(tab.label == "Ruta" and "Ruta 20-60" or tab.label, tab.lead, K.gold, style[2], color)
  if tab.live == "char" then BuildCharLive(P) end
  if tab.live == "mats" then BuildMatsLive(P) end
  if tab.live == "fish" then BuildFishLive(P) end
  if tab.live == "camp" then BuildCampLive(P) end
  if NS.PageExtras and NS.PageExtras[tab.key] then
    P.refreshers = P.refreshers or {}
    local H = { Text = Text, Framed = Framed, Pill = Pill, K = K, CW = CW, Bar = Bar, Panel = Panel, Grad = Grad, Icon = Icon }
    local ex = NS.PageExtras[tab.key]
    if type(ex) == "function" then ex(P, H) else for _, fn in ipairs(ex) do fn(P, H) end end
  end
  if tab.macros then BuildRotation(P, color) end

  local level = UnitLevel("player") or 0
  for _, sec in ipairs(tab.sections) do
    local hasTasks = false
    for _, it in ipairs(sec.items) do if it.id then hasTasks = true end end
    local lo, hi = sec.h:match("(%d+)%s*%-%s*(%d+)")
    lo, hi = tonumber(lo), tonumber(hi)
    local opts = { progress = hasTasks }
    if tab.key == "ruta" and lo then
      opts.badge = "Nv " .. lo .. "-" .. hi
      opts.here = level >= lo and level < hi
      opts.highlight = opts.here
    end
    local title = sec.h
    if tab.key == "ruta" then title = title:gsub("^%d+%s*%-%s*%d+%s*·%s*", "") end
    local C = P:Card(title, sec.icon, color, opts)
    for _, it in ipairs(sec.items) do
      if it.id then C:Task(it.id, it.t, TagFor(tab.key, it.id, it.t)) else C:Note(it.t) end
    end
    C:Finish()
  end
  if tab.macros then BuildMacros(P, color) end
  P:Finish()
  P.scroll.live = P.live
  P.scroll.kind = tab.live
  P.scroll.refreshers = P.refreshers
  return P.scroll
end

function NS.RefreshLive()
  if not frame then return end
  for key, page in pairs(pages) do
    for _, f in ipairs(rawget(page, "refreshers") or {}) do f() end
    local L = page.live
    if L and page.kind == "char" then RefreshChar(L) end
    if L and page.kind == "mats" then RefreshMats(L) end
    if L and page.kind == "fish" then RefreshFish(L) end
    if L and page.kind == "camp" then RefreshCamp(L) end
  end
  if frame.portrait then SetPortraitTexture(frame.portrait, "player") end
  frame.sub:SetText("Enano  ·  Chamán Mejora  ·  Nivel " .. (UnitLevel("player") or "?"))
end

function NS.ShowTab(index)
  local prev = DB().lastTab
  for i, tab in ipairs(NS.TABS) do
    local page = pages[tab.key]
    if page then
      page:SetShown(i == index)
      if i == index and prev and prev ~= index and frame:IsShown() and NS.AnimTab then NS.AnimTab(page, frame) end
    end
    local b = nav[i]
    if b then
      local on = i == index
      b.sel:SetShown(on); b.accent:SetShown(on); if b.glow then b.glow:SetShown(on) end
      b.label:SetTextColor(C3(on and { 1, 1, 1 } or K.parch))
    end
  end
  DB().lastTab = index
  NS.RefreshLive()
end

local function BuildFrame()
  local f = CreateFrame("Frame", "PiolinCodexFrame", UIParent, BD)
  frame = f
  NS.frame = f
  f:SetSize(W, H)
  f:SetPoint("CENTER")
  f:SetFrameStrata("HIGH")
  f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetBackdrop({ bgFile = WHITE, edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = false, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 } })
  f:SetBackdropColor(0.025, 0.045, 0.085, 0.97)
  f:Hide()
  tinsert(UISpecialFrames, "PiolinCodexFrame")

  -- brillo azul arriba y marca de agua de tótem
  local rock = f:CreateTexture(nil, "BACKGROUND", nil, -1)
  rock:SetPoint("TOPLEFT", 12, -12); rock:SetPoint("BOTTOMRIGHT", -12, 12)
  rock:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock", "REPEAT", "REPEAT")
  rock:SetHorizTile(true); rock:SetVertTile(true)
  rock:SetVertexColor(0.35, 0.5, 0.8)
  rock:SetAlpha(0.22)
  local vig = f:CreateTexture(nil, "BACKGROUND", nil, 0)
  vig:SetPoint("BOTTOMLEFT", 12, 12); vig:SetPoint("BOTTOMRIGHT", -12, 12); vig:SetHeight(120)
  Grad(vig, "VERTICAL", { 0, 0, 0 }, 0.5, { 0, 0, 0 }, 0)
  local glow = f:CreateTexture(nil, "BACKGROUND", nil, 1)
  glow:SetPoint("TOPLEFT", 12, -12); glow:SetPoint("TOPRIGHT", -12, -12); glow:SetHeight(110)
  Grad(glow, "VERTICAL", K.blue, 0, K.blue, 0.32)
  local water = f:CreateTexture(nil, "BACKGROUND", nil, 2)
  water:SetSize(260, 260)
  water:SetPoint("BOTTOMRIGHT", -20, 16)
  water:SetTexture("Interface\\Icons\\Spell_Nature_Windfury")
  water:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  water:SetAlpha(0.05)
  water:SetDesaturated(true)

  -- retrato y título
  local por = f:CreateTexture(nil, "ARTWORK")
  por:SetSize(58, 58)
  por:SetPoint("TOPLEFT", 22, -18)
  SetPortraitTexture(por, "player")
  f.portrait = por
  local ring = f:CreateTexture(nil, "OVERLAY")
  ring:SetSize(154, 154)
  ring:SetPoint("TOPLEFT", por, "TOPLEFT", -20, 15)
  ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  local cls = f:CreateTexture(nil, "OVERLAY", nil, 2)
  cls:SetSize(22, 22)
  cls:SetPoint("BOTTOMRIGHT", por, "BOTTOMRIGHT", 4, -4)
  cls:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
  if CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS.SHAMAN then cls:SetTexCoord(unpack(CLASS_ICON_TCOORDS.SHAMAN)) end

  local title = Text(f, 26, K.gold, TITLE_FONT)
  title:SetPoint("TOPLEFT", 96, -22)
  title:SetText("Códice de Piolin")
  f.sub = Text(f, 11, K.water)
  f.sub:SetPoint("TOPLEFT", 98, -54)

  local pl = Text(f, 9, K.mute)
  pl:SetPoint("TOPRIGHT", -46, -26)
  pl:SetText("GUÍA COMPLETADA")
  pl:SetJustifyH("RIGHT")
  f.pctText = Text(f, 22, K.parch, TITLE_FONT)
  f.pctText:SetPoint("TOPRIGHT", -46, -38)
  f.pctText:SetJustifyH("RIGHT")
  f.pctBar = Bar(f, 170, 7, K.water)
  f.pctBar:SetPoint("TOPRIGHT", -46, -66)
  f.pctBar.text:Hide()

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -6, -6)

  local div = f:CreateTexture(nil, "ARTWORK")
  div:SetPoint("TOPLEFT", 18, -86); div:SetPoint("TOPRIGHT", -18, -86); div:SetHeight(2)
  Grad(div, "HORIZONTAL", K.gold, 0.1, K.gold, 0.7)

  -- navegación lateral
  local side = Panel(f, { 0.02, 0.035, 0.07 }, 0.9, { 0.3, 0.36, 0.48 }, 0.6)
  side:SetPoint("TOPLEFT", 16, -96)
  side:SetPoint("BOTTOMLEFT", 16, 16)
  side:SetWidth(NAV_W)
  for i, tab in ipairs(NS.TABS) do
    local st = TAB_STYLE[tab.key] or { K.gold, tab.icon }
    local b = CreateFrame("Button", nil, side)
    b:SetSize(NAV_W - 10, 40)
    b:SetPoint("TOPLEFT", 5, -6 - (i - 1) * 42)
    b.sel = b:CreateTexture(nil, "BACKGROUND")
    b.sel:SetAllPoints()
    b.sel:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
    b.sel:SetBlendMode("ADD")
    b.sel:SetVertexColor(st[1][1], st[1][2], st[1][3], 0.85)
    b.accent = b:CreateTexture(nil, "ARTWORK")
    b.accent:SetPoint("TOPLEFT"); b.accent:SetPoint("BOTTOMLEFT"); b.accent:SetWidth(3)
    b.accent:SetColorTexture(C3(st[1]))
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    hl:SetBlendMode("ADD")
    hl:SetAlpha(0.5)
    local ic = Framed(b, st[2], 26)
    ic:SetPoint("LEFT", 12, 0)
    b.glow = b:CreateTexture(nil, "OVERLAY", nil, 3)
    b.glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    b.glow:SetBlendMode("ADD")
    b.glow:SetAllPoints(ic)
    b.label = Text(b, 12.5, K.parch, TITLE_FONT)
    b.label:SetPoint("LEFT", ic, "RIGHT", 10, 1)
    b.label:SetText(tab.key == "ruta" and "Ruta 20-60" or tab.label)
    b.count = Text(b, 10, K.mute)
    b.count:SetPoint("RIGHT", -8, 0)
    b.count:SetJustifyH("RIGHT")
    b:SetScript("OnClick", function() NS.Sound("tab"); NS.ShowTab(i) end)
    Tooltip(b, tab.key == "ruta" and "Ruta 20-60" or tab.label, { tab.lead })
    nav[i] = b
  end
  -- los cuatro tótems al pie
  local totems = { "Interface\\Icons\\Spell_Nature_StrengthOfEarthTotem02", "Interface\\Icons\\Spell_Fire_SearingTotem",
    "Interface\\Icons\\INV_Spear_04", "Interface\\Icons\\Spell_Nature_Windfury" }
  local names = { "Tierra", "Fuego", "Agua", "Aire" }
  for i, t in ipairs(totems) do
    local ic = Framed(side, t, 22)
    ic:SetPoint("BOTTOMLEFT", 18 + (i - 1) * 38, 34)
    ic:SetAlpha(0.85)
  end
  local hint = Text(side, 9, K.dim)
  hint:SetPoint("BOTTOMLEFT", 12, 12)
  hint:SetText("/piolin ayuda  ·  Esc para cerrar")

  for _, tab in ipairs(NS.TABS) do pages[tab.key] = BuildPage(tab, f) end
  f:SetScript("OnShow", function() if NS.AutoCheck then NS.AutoCheck(true) end NS.UpdateProgress(); NS.RefreshLive() end)
  NS.pages = pages
  NS.ShowTab(DB().lastTab or 1)
  NS.UpdateProgress()
end

function NS.Toggle()
  if not frame then BuildFrame() end
  frame:SetShown(not frame:IsShown())
  if frame:IsShown() then
    if NS.AnimOpen then NS.AnimOpen(frame) else NS.Sound("open") end
  end
end
