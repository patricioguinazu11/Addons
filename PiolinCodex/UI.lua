-- Códice de Piolin: interfaz "moderno oscuro"
-- Fondos lisos, bordes de 1 px y el azul chamán como único acento. Letra Inter incluida en el addon.
local ADDON, NS = ...

local W, H = 780, 570
local NAV_W = 180
local HEAD_H = 66                  -- alto de la cabecera
local CW = W - NAV_W - 66          -- ancho útil del contenido
local FONT_DIR = "Interface\\AddOns\\" .. ADDON .. "\\Fonts\\"
local TITLE_FONT = FONT_DIR .. "Inter-SemiBold.ttf"
local BODY_FONT = FONT_DIR .. "Inter-Regular.ttf"
local BD = BackdropTemplateMixin and "BackdropTemplate" or nil
local WHITE = "Interface\\Buttons\\WHITE8X8"

-- Paleta: superficies oscuras neutras, texto gris claro, azul chamán de acento y los cuatro elementos
local K = {
  bg = { 0.055, 0.067, 0.09 }, side = { 0.043, 0.051, 0.07 }, card = { 0.075, 0.094, 0.13 }, raised = { 0.09, 0.12, 0.17 },
  line = { 0.12, 0.15, 0.2 }, edge = { 0.15, 0.17, 0.22 }, track = { 0.11, 0.13, 0.17 },
  title = { 0.95, 0.96, 0.97 }, accent = { 0.18, 0.56, 1 },
  gold = { 1, 0.82, 0 }, parch = { 0.86, 0.89, 0.93 }, mute = { 0.53, 0.57, 0.64 }, dim = { 0.42, 0.46, 0.53 },
  blue = { 0.18, 0.56, 1 }, water = { 0.3, 0.66, 1 }, air = { 0.72, 0.94, 1 }, earth = { 0.78, 0.58, 0.32 },
  fire = { 1, 0.48, 0.14 }, nature = { 0.45, 0.85, 0.35 }, ok = { 0.5, 0.86, 0.4 }, warn = { 1, 0.62, 0.25 }, bad = { 1, 0.42, 0.4 },
}
local TAB_STYLE = {
  personaje = { K.blue, "Interface\\Icons\\Spell_Nature_BloodLust" },
  misiones = { K.gold, "Interface\\Icons\\INV_Misc_Note_01" },
  ruta = { K.earth, "Interface\\Icons\\INV_Misc_Map_01" },
  pesca = { K.water, "Interface\\Icons\\Trade_Fishing" },
  oficios = { K.nature, "Interface\\Icons\\Trade_LeatherWorking" },
  combate = { K.fire, "Interface\\Icons\\Spell_Nature_LightningShield" },
  campamento = { K.fire, "Interface\\Icons\\Ability_Mount_MountainRam" },
  teclas = { K.accent, "Interface\\Icons\\INV_Misc_Note_02" },
  pantalla = { K.accent, "Interface\\Icons\\INV_Misc_Spyglass_03" },
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
  if not fs:SetFont(font or BODY_FONT, size, "") then fs:SetFont("Fonts\\FRIZQT__.TTF", size, "") end
  fs:SetShadowOffset(1, -1)
  fs:SetShadowColor(0, 0, 0, 0.55)
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

-- Ícono con un borde fino oscuro (reemplaza al marco de botón de acción)
local function Framed(parent, path, size, layer)
  local ic = Icon(parent, path, size, layer)
  local fr = parent:CreateTexture(nil, "BORDER")
  fr:SetColorTexture(0, 0, 0, 0.85)
  fr:SetPoint("TOPLEFT", ic, "TOPLEFT", -1, 1)
  fr:SetPoint("BOTTOMRIGHT", ic, "BOTTOMRIGHT", 1, -1)
  ic.frameTex = fr
  local oShow, oHide, oShown = ic.Show, ic.Hide, ic.SetShown
  ic.Show = function(self) oShow(self); fr:Show() end
  ic.Hide = function(self) oHide(self); fr:Hide() end
  ic.SetShown = function(self, v) oShown(self, v); fr:SetShown(v) end
  return ic
end

-- Recuadro plano: fondo liso y borde de 1 px
local function Panel(parent, bg, bgA, border, borderA)
  local f = CreateFrame("Frame", nil, parent, BD)
  f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, tile = false, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
  f:SetBackdropColor(bg[1], bg[2], bg[3], bgA or 1)
  f:SetBackdropBorderColor(border[1], border[2], border[3], borderA or 1)
  return f
end

-- Barra plana sobre un riel oscuro
local function Bar(parent, w, h, color)
  local b = CreateFrame("StatusBar", nil, parent)
  b:SetSize(w, h)
  b:SetStatusBarTexture(WHITE)
  b:SetStatusBarColor(C3(color))
  b:SetMinMaxValues(0, 1)
  b:SetValue(0)
  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(C3(K.track))
  b.text = Text(b, math.max(9, math.min(11, h - 3)), K.title, TITLE_FONT)
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

-- Etiqueta: texto de color sobre un fondo tenue del mismo color
local function Pill(parent, label, color)
  local tint = { K.card[1] + (color[1] - K.card[1]) * 0.16, K.card[2] + (color[2] - K.card[2]) * 0.16, K.card[3] + (color[3] - K.card[3]) * 0.16 }
  local p = Panel(parent, tint, 1, tint, 1)
  p.text = Text(p, 8.5, color, TITLE_FONT)
  p.text:SetShadowColor(0, 0, 0, 0)
  p.text:SetPoint("CENTER", 0, 0)
  -- string.upper no pasa a mayúscula las vocales con tilde: las convierto a mano
  local up = label:upper():gsub("á", "Á"):gsub("é", "É"):gsub("í", "Í"):gsub("ó", "Ó"):gsub("ú", "Ú"):gsub("ñ", "Ñ")
  p.text:SetText(up)
  p:SetSize(math.max(50, p.text:GetStringWidth() + 14), 16)
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

----------------------------------------------------------------------
-- Piezas de estilo compartidas con las otras ventanas (opciones, compras, instructor, avisos)
----------------------------------------------------------------------
local function Font(fs, size, color, bold)
  if not fs or not fs.SetFont then return fs end
  if not fs:SetFont(bold and TITLE_FONT or BODY_FONT, size, "") then fs:SetFont("Fonts\\FRIZQT__.TTF", size, "") end
  fs:SetShadowOffset(1, -1)
  fs:SetShadowColor(0, 0, 0, 0.55)
  if color then fs:SetTextColor(C3(color)) end
  return fs
end

-- Oculta las texturas que trae una plantilla de Blizzard (sin tocar las que agregamos después)
local function HideTemplateTextures(f, keys)
  for _, k in ipairs(keys or {}) do
    local t = rawget(f, k)
    if type(t) == "table" and t.SetAlpha then t:SetAlpha(0) end
  end
  for _, g in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture", "GetDisabledCheckedTexture" }) do
    if f[g] then
      local ok, t = pcall(f[g], f)
      if ok and type(t) == "table" and t.SetAlpha then t:SetAlpha(0) end
    end
  end
end

local btnFonts
local function ButtonFonts()
  if btnFonts or not CreateFont then return btnFonts end
  local n = CreateFont("PiolinCodexButtonFont"); n:SetFont(BODY_FONT, 12, ""); n:SetTextColor(C3(K.title)); n:SetShadowColor(0, 0, 0, 0)
  local d = CreateFont("PiolinCodexButtonFontOff"); d:SetFont(BODY_FONT, 12, ""); d:SetTextColor(C3(K.dim)); d:SetShadowColor(0, 0, 0, 0)
  btnFonts = { n, d }
  return btnFonts
end

-- Botón plano. kind: nil (normal), "primary" (azul) o "danger" (rojo apagado)
local function SkinButton(b, kind)
  rawset(b, "__skinned", kind or "normal")
  HideTemplateTextures(b, { "Left", "Middle", "Right", "LeftSeparator", "RightSeparator" })
  local fill = kind == "primary" and K.accent or (kind == "danger" and { 0.26, 0.09, 0.09 }) or K.raised
  local border = kind == "primary" and K.accent or (kind == "danger" and { 0.5, 0.17, 0.17 }) or K.edge
  local bo = b:CreateTexture(nil, "BACKGROUND", nil, -8); bo:SetAllPoints(); bo:SetColorTexture(C3(border))
  local bg = b:CreateTexture(nil, "BACKGROUND", nil, -7); bg:SetPoint("TOPLEFT", 1, -1); bg:SetPoint("BOTTOMRIGHT", -1, 1); bg:SetColorTexture(C3(fill))
  local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.07)
  local fonts = ButtonFonts()
  if fonts and b.SetNormalFontObject then
    b:SetNormalFontObject(fonts[1]); b:SetHighlightFontObject(fonts[1]); b:SetDisabledFontObject(fonts[2])
  else
    local fs = b.GetFontString and b:GetFontString()
    if type(fs) == "table" then Font(fs, 12, K.title) end
  end
  return b
end

-- Casilla plana: cuadro de 16 px con borde gris; tildada muestra una marca clara
local function SkinCheck(cb)
  rawset(cb, "__skinned", "check")
  HideTemplateTextures(cb, {})
  local box = cb:CreateTexture(nil, "BACKGROUND", nil, -8); box:SetSize(16, 16); box:SetPoint("CENTER"); box:SetColorTexture(0.23, 0.27, 0.34, 1)
  local inner = cb:CreateTexture(nil, "BACKGROUND", nil, -7); inner:SetPoint("TOPLEFT", box, 1, -1); inner:SetPoint("BOTTOMRIGHT", box, -1, 1); inner:SetColorTexture(C3(K.card))
  local hl = cb:CreateTexture(nil, "HIGHLIGHT"); hl:SetPoint("TOPLEFT", box, 0, 0); hl:SetPoint("BOTTOMRIGHT", box, 0, 0); hl:SetColorTexture(1, 1, 1, 0.08)
  if cb.GetCheckedTexture then
    local ok, ct = pcall(cb.GetCheckedTexture, cb)
    if ok and type(ct) == "table" then
      ct:SetTexture("Interface\\Buttons\\UI-CheckBox-Check"); ct:SetDesaturated(true); ct:SetVertexColor(1, 1, 1)
      ct:ClearAllPoints(); ct:SetPoint("CENTER", box, 0, 0); ct:SetSize(20, 20)
    end
  end
  return cb
end

-- Ventana plana para los marcos con plantilla de Blizzard (BasicFrameTemplate...)
local function SkinWindow(f)
  rawset(f, "__skinned", "window")
  pcall(function()
    for _, r in ipairs({ f:GetRegions() }) do
      if r.GetObjectType and r:GetObjectType() == "Texture" then r:SetAlpha(0) end
    end
  end)
  for _, k in ipairs({ "Inset", "NineSlice", "Bg", "TitleBg", "TopTileStreaks" }) do
    local c = rawget(f, k)
    if type(c) == "table" and c.SetAlpha then c:SetAlpha(0) end
  end
  local bo = f:CreateTexture(nil, "BACKGROUND", nil, -8); bo:SetAllPoints(); bo:SetColorTexture(C3(K.edge))
  local bg = f:CreateTexture(nil, "BACKGROUND", nil, -7); bg:SetPoint("TOPLEFT", 1, -1); bg:SetPoint("BOTTOMRIGHT", -1, 1); bg:SetColorTexture(K.bg[1], K.bg[2], K.bg[3], 0.97)
  local top = f:CreateTexture(nil, "BORDER"); top:SetPoint("TOPLEFT", 1, -1); top:SetPoint("TOPRIGHT", -1, -1); top:SetHeight(2)
  Grad(top, "HORIZONTAL", K.accent, 1, K.accent, 0)
  local head = f:CreateTexture(nil, "BORDER"); head:SetPoint("TOPLEFT", 1, -26); head:SetPoint("TOPRIGHT", -1, -26); head:SetHeight(1)
  head:SetColorTexture(C3(K.line))
  local close = rawget(f, "CloseButton")
  if type(close) == "table" then
    HideTemplateTextures(close, {})
    close:ClearAllPoints(); close:SetPoint("TOPRIGHT", -4, -4); close:SetSize(20, 20)
    local x = Font(close:CreateFontString(nil, "OVERLAY"), 14, K.mute)
    x:SetPoint("CENTER", 0, 1); x:SetText("×")
    local chl = close:CreateTexture(nil, "HIGHLIGHT"); chl:SetAllPoints(); chl:SetColorTexture(1, 1, 1, 0.07)
  end
  return f
end

NS.Style = {
  K = K, C3 = C3, BODY_FONT = BODY_FONT, TITLE_FONT = TITLE_FONT,
  Font = Font, Text = Text, Panel = Panel, Bar = Bar, Pill = Pill, Icon = Icon, Framed = Framed, Grad = Grad,
  SkinButton = SkinButton, SkinCheck = SkinCheck, SkinWindow = SkinWindow,
}

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
        b.count:SetText(d == n and "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12|t" or (d .. "/" .. n))
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
  scroll:SetPoint("TOPLEFT", NAV_W + 22, -(HEAD_H + 16))
  scroll.__a = { NAV_W + 22, -(HEAD_H + 16), -36, 14 }
  scroll:SetPoint("BOTTOMRIGHT", -36, 14)
  -- barra de desplazamiento fina: sin flechas, solo un riel y un tirador lisos
  pcall(function()
    local sb = scroll.ScrollBar
    if not sb then return end
    for _, k in ipairs({ "ScrollUpButton", "ScrollDownButton", "Back", "Forward" }) do if sb[k] then sb[k]:SetAlpha(0); sb[k]:EnableMouse(false) end end
    local thumb = sb.ThumbTexture or (sb.GetThumbTexture and sb:GetThumbTexture())
    if thumb then thumb:SetColorTexture(0.25, 0.29, 0.37, 1); thumb:SetWidth(4) end
    local rail = sb:CreateTexture(nil, "BACKGROUND")
    rail:SetPoint("TOP", 0, -2); rail:SetPoint("BOTTOM", 0, 2); rail:SetWidth(4)
    rail:SetColorTexture(C3(K.track))
  end)
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

  -- Título de la página: texto grande y la bajada en gris, sin bandas ni adornos
  function P:Heading(text, lead, color, icon, accent)
    local t = Text(child, 19, K.title, TITLE_FONT)
    t:SetPoint("TOPLEFT", 0, self.y)
    t:SetText(text)
    local l = Text(child, 11.5, K.mute)
    l:SetPoint("TOPLEFT", 0, self.y - 27)
    l:SetWidth(CW - 6)
    l:SetText(lead or "")
    local lh = (lead and lead ~= "") and math.max(14, l:GetStringHeight()) or 0
    self.y = self.y - 27 - lh - 14
    self.top = self.y
  end

  -- Tarjeta con encabezado (ícono, título, progreso opcional)
  function P:Card(title, icon, color, opts)
    opts = opts or {}
    local c = Panel(child, K.card, 1, opts.highlight and K.accent or K.line, 1)
    c:SetPoint("TOPLEFT", 0, self.y)
    c:SetWidth(CW)
    -- plegar/desplegar: un signo chico en gris
    local fold = CreateFrame("Button", nil, c)
    fold:SetSize(18, 18)
    fold:SetPoint("TOPLEFT", 8, -8)
    fold.sign = Text(fold, 13, K.dim, TITLE_FONT)
    fold.sign:SetPoint("CENTER", 0, 1)
    fold.sign:SetJustifyH("CENTER")
    fold.sign:SetText("–")
    local fhl = fold:CreateTexture(nil, "HIGHLIGHT")
    fhl:SetAllPoints(); fhl:SetColorTexture(1, 1, 1, 0.06)
    c.fold = fold
    local x = 30
    if icon then
      local ic = Framed(c, icon, 18)
      ic:SetPoint("TOPLEFT", 30, -9)
      x = 56
    end
    local t = Text(c, 13.5, K.title, TITLE_FONT)
    t:SetPoint("TOPLEFT", x, -10)
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
      C.progBar = Bar(c, 56, 3, K.accent)
      C.progBar:SetPoint("TOPRIGHT", -12, -17)
      C.progBar.text:Hide()
      C.progText = Text(c, 10.5, K.mute)
      C.progText:SetPoint("RIGHT", C.progBar, "LEFT", -8, 0)
      table.insert(cards, C)
    end
    local line = c:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", 1, -35)
    line:SetPoint("TOPRIGHT", -1, -35)
    line:SetHeight(1)
    line:SetColorTexture(C3(K.line))

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
      row:SetPoint("TOPLEFT", 1, self.y)
      row:SetWidth(CW - 2)
      local hl = row:CreateTexture(nil, "HIGHLIGHT")
      hl:SetAllPoints()
      hl:SetColorTexture(1, 1, 1, 0.035)
      -- casilla plana: borde gris; tildada, se llena de azul con una marca clara
      local slot = row:CreateTexture(nil, "ARTWORK")
      row.slotTex = slot
      slot:SetSize(14, 14)
      slot:SetPoint("TOPLEFT", 12, -7)
      slot:SetColorTexture(0.23, 0.27, 0.34, 1)
      local slotIn = row:CreateTexture(nil, "ARTWORK", nil, 1)
      slotIn:SetPoint("TOPLEFT", slot, 1, -1); slotIn:SetPoint("BOTTOMRIGHT", slot, -1, 1)
      slotIn:SetColorTexture(C3(K.card))
      local tick = row:CreateTexture(nil, "OVERLAY")
      tick:SetSize(16, 16)
      tick:SetPoint("CENTER", slot, 0, 0)
      tick:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
      tick:SetDesaturated(true)
      tick:SetVertexColor(1, 1, 1)
      local ic = { SetDesaturated = function() end, SetAlpha = function() end }
      local wp = id and NS.WAYPOINTS and NS.WAYPOINTS[id]
      local fs = Text(row, 11.5, K.parch)
      fs:SetPoint("TOPLEFT", 36, -6)
      local isQuest = id and NS.AUTO and NS.AUTO.quest and NS.AUTO.quest[id]
      fs:SetWidth(CW - 2 - 36 - 74 - (wp and 26 or 0) - (isQuest and 78 or 0))
      fs:SetSpacing(2)
      fs:SetText(text)
      local pill = Pill(row, tag[1], tag[2])
      pill:SetPoint("TOPRIGHT", -12, -6)
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
      local h = math.max(28, fs:GetStringHeight() + 12)
      -- separador fino entre filas (no antes de la primera)
      if self.hadRow then
        local sep = row:CreateTexture(nil, "BACKGROUND")
        sep:SetPoint("TOPLEFT", 0, 0); sep:SetPoint("TOPRIGHT", 0, 0); sep:SetHeight(1)
        sep:SetColorTexture(1, 1, 1, 0.035)
      end
      self.hadRow = true
      row:SetHeight(h)
      row.checked = DB().checks[id] and true or false
      function row:GetChecked() return self.checked end
      function row:SetChecked(v) self.checked = v and true or false end
      row.paint = function()
        tick:SetShown(row.checked)
        slotIn:SetShown(not row.checked)
        if row.checked then slot:SetColorTexture(C3(K.accent)) else slot:SetColorTexture(0.23, 0.27, 0.34, 1) end
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
      self.y = self.y - h
      return row
    end
    -- Línea informativa con viñeta de rombo
    function C:Note(text)
      local d = c:CreateTexture(nil, "ARTWORK")
      d:SetSize(5, 5)
      d:SetPoint("TOPLEFT", 16, self.y - 6)
      d:SetColorTexture(C3(color))
      return self:Text(text, 11.5, K.parch, 30)
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
        c.fold.sign:SetText(col and "+" or "–")
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
  local t = Panel(parent, K.card, 1, K.line, 1)
  t:SetPoint("TOPLEFT", x, y)
  t.__x = x
  t:SetSize(w, 78)
  local ic = Framed(t, icon, 22)
  ic:SetPoint("TOPLEFT", 12, -12)
  t.label = Text(t, 10.5, K.mute)
  t.label:SetPoint("TOPLEFT", 42, -10)
  t.label:SetText(label)
  t.value = Text(t, 20, K.title, TITLE_FONT)
  t.value:SetPoint("TOPLEFT", 42, -24)
  t.sub = Text(t, 10, K.mute)
  t.sub:SetPoint("BOTTOMLEFT", 12, 16)
  t.bar = Bar(t, w - 24, 3, color)
  t.bar:SetPoint("BOTTOMLEFT", 12, 9)
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
  local b = Panel(P.child, K.raised, 1, K.line, 1)
  b:SetPoint("TOPLEFT", 0, P.y)
  b:SetSize(CW, 46)
  local ba = b:CreateTexture(nil, "ARTWORK")
  ba:SetPoint("TOPLEFT", 1, -1); ba:SetPoint("BOTTOMLEFT", 1, 1); ba:SetWidth(2)
  ba:SetColorTexture(C3(K.accent))
  local bi = Framed(b, "Interface\\Icons\\Spell_Nature_Windfury", 24)
  bi:SetPoint("LEFT", 14, 0)
  local bt = Text(b, 10.5, K.water)
  bt:SetPoint("TOPLEFT", 50, -8)
  bt:SetText("Ahora te toca")
  L.hint = Text(b, 12, K.title)
  L.hint:SetPoint("TOPLEFT", 50, -23)
  L.hint:SetWidth(CW - 64)
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
    -- ranura plana: fondo oscuro; el borde de 1 px toma el color de la calidad del objeto
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(C3(K.edge))
    local _, emptyTex = GetInventorySlotInfo(SLOT_NAMES[s[1]] or "HeadSlot")
    btn.empty = emptyTex
    btn.qual = btn:CreateTexture(nil, "BORDER")
    btn.qual:SetAllPoints()
    btn.qual:SetColorTexture(1, 1, 1, 1)
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetPoint("TOPLEFT", 1, -1); btn.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.warn = btn:CreateTexture(nil, "OVERLAY")
    btn.warn:SetAllPoints()
    btn.warn:SetColorTexture(1, 0.25, 0.25, 0.18)
    btn.cap = Text(C.frame, 8.5, K.dim)
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
  local maxLevel = (GetMaxPlayerLevel and GetMaxPlayerLevel()) or 60
  if level >= maxLevel then
    -- en el tope no hay experiencia que juntar: barra llena y aviso en dorado
    L.lvl.bar:SetValue(1)
    L.lvl.sub:SetText("|cffffd100nivel máximo|r")
  else
    local xp, xpMax = UnitXP("player") or 0, UnitXPMax("player") or 1
    L.lvl.bar:SetValue(xpMax > 0 and xp / xpMax or 0)
    local rest = GetXPExhaustion and GetXPExhaustion() or 0
    L.lvl.sub:SetText(math.floor(xp / math.max(1, xpMax) * 100) .. "% del nivel" .. ((rest or 0) > 0 and ("  ·  descanso " .. math.floor(rest / math.max(1, xpMax) * 100) .. "%") or ""))
  end
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
  local btn = SkinButton(CreateFrame("Button", nil, C.frame, "UIPanelButtonTemplate"), "primary")
  btn:SetSize(120, 22)
  btn:SetPoint("TOPRIGHT", -12, -7)
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

----------------------------------------------------------------------
-- Pestaña Teclas: la propuesta dibujada como teclado y mouse, con capas por modificador
----------------------------------------------------------------------
local KEY_CATS = {
  { k = "ataque", t = "Ataques", c = { 1, 0.36, 0.34 } },
  { k = "choque", t = "Choques e interrupción", c = { 1, 0.6, 0.24 } },
  { k = "totem", t = "Tótems", c = { 0.79, 0.59, 0.35 } },
  { k = "buff", t = "Escudos e imbuiciones", c = { 0.71, 0.55, 1 } },
  { k = "cooldown", t = "Cooldowns", c = { 1, 0.83, 0.35 } },
  { k = "cura", t = "Curación", c = { 0.44, 0.82, 0.42 } },
  { k = "consumible", t = "Consumibles", c = { 0.25, 0.78, 0.72 } },
  { k = "movilidad", t = "Movilidad", c = { 0.44, 0.71, 1 } },
  { k = "otro", t = "Otros", c = { 0.49, 0.53, 0.6 } },
}
local KEY_ROWS = {
  { "`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" },
  { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" },
  { "A", "S", "D", "F", "G", "H", "J", "K", "L" },
  { "Z", "X", "C", "V", "B", "N", "M" },
}
local MOUSE_KEYS = { { "Mouse3", "Rueda" }, { "Mouse4", "Botón 4" }, { "Mouse5", "Botón 5" }, { "Rueda arriba", "Rueda ↑" }, { "Rueda abajo", "Rueda ↓" } }

local function BuildKeys(P)
  local map = NS.KEYMAP or { binds = {} }
  local catBy = {}
  for _, c in ipairs(KEY_CATS) do catBy[c.k] = c end
  local layers, seen = { "" }, { [""] = true }
  for _, b in ipairs(map.binds) do if not seen[b.layer] then seen[b.layer] = true; table.insert(layers, b.layer) end end
  local byLayer = {}
  for _, b in ipairs(map.binds) do
    byLayer[b.layer] = byLayer[b.layer] or {}
    byLayer[b.layer][b.key] = b
  end

  local C = P:Card("Tu teclado", "Interface\\Icons\\INV_Misc_Note_02", K.accent)
  -- selector de capa: Sin modificador / Shift / Ctrl
  local tabsBtn, cells = {}, {}
  local current = ""
  local function paint()
    for i, lb in ipairs(tabsBtn) do
      local on = layers[i] == current
      lb.bg:SetColorTexture(C3(on and K.accent or K.raised))
      lb.label:SetTextColor(C3(on and K.title or K.parch))
    end
    for _, cell in ipairs(cells) do
      local b = byLayer[current] and byLayer[current][cell.key]
      cell.bind = b
      if b then
        local cat = catBy[b.cat] or catBy.otro
        cell.icon:SetTexture(b.icon); cell.icon:Show()
        cell.bar:SetColorTexture(C3(cat.c)); cell.bar:Show()
        cell.edge:SetColorTexture(cat.c[1], cat.c[2], cat.c[3], 0.9)
        cell.label:SetTextColor(C3(K.title))
      else
        cell.icon:Hide(); cell.bar:Hide()
        cell.edge:SetColorTexture(C3(K.line))
        cell.label:SetTextColor(C3(K.dim))
      end
    end
  end
  local x = 14
  for i, l in ipairs(layers) do
    local count = 0
    for _ in pairs(byLayer[l] or {}) do count = count + 1 end
    local btn = CreateFrame("Button", nil, C.frame)
    btn:SetPoint("TOPLEFT", x, C.y)
    btn.bg = btn:CreateTexture(nil, "BACKGROUND"); btn.bg:SetAllPoints()
    btn.label = Text(btn, 11.5, K.parch)
    btn.label:SetPoint("CENTER", 0, 0)
    btn.label:SetText((l == "" and "Sin modificador" or (l .. " +")) .. "  " .. count)
    local w = math.floor(btn.label:GetStringWidth() + 24)
    btn:SetSize(w, 24)
    local hl = btn:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.06)
    btn:SetScript("OnClick", function() current = l; NS.Sound("tab"); paint() end)
    tabsBtn[i] = btn
    x = x + w + 6
  end
  C.y = C.y - 36

  local function Cell(parent, key, label, w, px, py)
    local cell = CreateFrame("Button", nil, parent)
    cell:SetSize(w, 40)
    cell:SetPoint("TOPLEFT", px, py)
    cell.key = key
    cell.edge = cell:CreateTexture(nil, "BACKGROUND", nil, -8); cell.edge:SetAllPoints()
    local inner = cell:CreateTexture(nil, "BACKGROUND", nil, -7)
    inner:SetPoint("TOPLEFT", 1, -1); inner:SetPoint("BOTTOMRIGHT", -1, 1); inner:SetColorTexture(C3(K.side))
    cell.icon = cell:CreateTexture(nil, "ARTWORK")
    cell.icon:SetPoint("TOPLEFT", 1, -1); cell.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    cell.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    cell.bar = cell:CreateTexture(nil, "OVERLAY")
    cell.bar:SetPoint("BOTTOMLEFT", 1, 1); cell.bar:SetPoint("BOTTOMRIGHT", -1, 1); cell.bar:SetHeight(3)
    cell.label = Text(cell, 9.5, K.dim, TITLE_FONT)
    cell.label:SetPoint("TOPRIGHT", -3, -3)
    cell.label:SetJustifyH("RIGHT")
    cell.label:SetShadowColor(0, 0, 0, 1)
    cell.label:SetText(label)
    cell:SetScript("OnEnter", function(self)
      local b = self.bind
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      local mod = current ~= "" and (current .. "+") or ""
      if b then
        local cat = catBy[b.cat] or catBy.otro
        GameTooltip:AddLine(b.spell, C3(K.title))
        GameTooltip:AddLine(mod .. label .. "  ·  " .. cat.t, cat.c[1], cat.c[2], cat.c[3])
        if b.note then GameTooltip:AddLine(b.note, 0.75, 0.78, 0.84, true) end
      else
        GameTooltip:AddLine(mod .. label .. ": libre", C3(K.mute))
      end
      GameTooltip:Show()
    end)
    cell:SetScript("OnLeave", GameTooltip_Hide)
    table.insert(cells, cell)
    return cell
  end
  -- teclado (las filas corren un poco a la derecha, como uno real)
  local size, gap = 40, 6
  for r, row in ipairs(KEY_ROWS) do
    for i, k in ipairs(row) do
      Cell(C.frame, k, k, size, 14 + (r - 1) * 12 + (i - 1) * (size + gap), C.y - (r - 1) * (size + gap))
    end
  end
  C.y = C.y - #KEY_ROWS * (size + gap) - 8
  local ml = Text(C.frame, 10.5, K.mute)
  ml:SetPoint("TOPLEFT", 14, C.y)
  ml:SetText("Mouse")
  C.y = C.y - 18
  for i, m in ipairs(MOUSE_KEYS) do Cell(C.frame, m[1], m[2], 64, 14 + (i - 1) * 70, C.y) end
  C.y = C.y - 50
  C:Text("Pasá el mouse por una tecla para ver qué hechizo va y por qué. El color de abajo es el tipo de hechizo.", 10, K.dim)
  C:Finish()
  paint()

  -- resumen: en qué teclas va cada tipo (todas las capas)
  local R = P:Card("Por tipo de hechizo", "Interface\\Icons\\INV_Misc_Book_09", K.accent)
  for _, cat in ipairs(KEY_CATS) do
    local keys = {}
    for _, b in ipairs(map.binds) do
      if b.cat == cat.k then table.insert(keys, (b.layer ~= "" and (b.layer .. "+") or "") .. b.key) end
    end
    if #keys > 0 then
      local sw = R.frame:CreateTexture(nil, "ARTWORK")
      sw:SetSize(8, 8)
      sw:SetPoint("TOPLEFT", 16, R.y - 4)
      sw:SetColorTexture(C3(cat.c))
      R:Text("|cfff2f4f8" .. cat.t .. "|r  " .. table.concat(keys, ", "), 11, K.parch, 32)
    end
  end
  R:Finish()

  if map.why then
    local W = P:Card("Por qué así", "Interface\\Icons\\INV_Misc_Note_01", K.accent)
    W:Text(map.why, 11, K.parch)
    W:Finish()
  end
end

----------------------------------------------------------------------
-- Pestaña Pantalla: diseños del Modo edición dibujados en chico, con su texto para copiar
-- (el Códice no los aplica: los importás vos desde el juego)
----------------------------------------------------------------------
local EM_POINTS = { [0] = "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
local EM_KIND = { [0] = "barra", [1] = "lanzamiento", [2] = "minimapa", [3] = "marco", [4] = "extra", [5] = "extra", [6] = "auras", [8] = "chat",
  [12] = "misiones", [13] = "menu", [14] = "menu", [15] = "experiencia", [16] = "menu", [20] = "reutilizacion", [23] = "medidor", [29] = "golpes" }
local EM_COLOR = {
  barra = { 0.18, 0.56, 1 }, marco = { 0.37, 0.83, 0.37 }, minimapa = { 0.79, 0.65, 0.31 }, chat = { 0.6, 0.64, 0.7 },
  misiones = { 1, 0.83, 0.35 }, auras = { 0.71, 0.55, 1 }, lanzamiento = { 1, 0.54, 0.24 }, menu = { 0.49, 0.53, 0.6 },
  experiencia = { 0.31, 0.82, 0.77 }, reutilizacion = { 1, 0.36, 0.34 }, extra = { 1, 0.62, 0.89 }, medidor = { 0.88, 0.88, 0.88 }, golpes = { 1, 0.7, 0.28 },
}
local EM_LEGEND = { { "barra", "Barras" }, { "marco", "Marcos" }, { "minimapa", "Minimapa" }, { "chat", "Chat" }, { "misiones", "Misiones" },
  { "auras", "Beneficios" }, { "lanzamiento", "Lanzamiento" }, { "reutilizacion", "Reutilización" }, { "golpes", "Golpes" }, { "medidor", "Medidor" },
  { "experiencia", "Experiencia" }, { "menu", "Menú y bolsas" } }
local EM_BARS = { [0] = "Barra 1", "Barra 2", "Barra 3", "Barra 4", "Barra 5", "Barra 6", "Barra 7", "Barra 8", [10] = "Posturas", [11] = "Mascota", [12] = "Posesión" }
local EM_UNITS = { [0] = "Personaje", "Objetivo", "Foco", "Grupo", "Banda", "Jefes", "Arena", "Mascota" }
local EM_AURAS = { [0] = "Beneficios", "Perjuicios", "Defensas" }
local EM_SWING = { [0] = "Golpe mano principal", "Golpe mano secundaria", "Golpe a distancia" }
local EM_OTHER = { [1] = "Lanzamiento", [2] = "Minimapa", [4] = "Encuentro", [5] = "Habilidad extra", [8] = "Chat", [12] = "Misiones",
  [13] = "Micromenú", [14] = "Bolsas", [16] = "Durabilidad", [23] = "Medidor de daño" }
-- ventana de referencia -> sistema:índice
local EM_REL = {
  MainActionBar = "0:0", MainMenuBar = "0:0", MultiBarBottomLeft = "0:1", MultiBarBottomRight = "0:2", MultiBarRight = "0:3", MultiBarLeft = "0:4",
  MultiBar5 = "0:5", MultiBar6 = "0:6", MultiBar7 = "0:7", StanceBar = "0:10", PetActionBar = "0:11", PossessActionBar = "0:12",
  PlayerFrame = "3:0", TargetFrame = "3:1", FocusFrame = "3:2", PartyFrame = "3:3", CompactRaidFrameContainer = "3:4", CompactRaidFrameManager = "3:4",
  BossTargetFrameContainer = "3:5", PetFrame = "3:7", MinimapCluster = "2:-1", Minimap = "2:-1", ChatFrame1 = "8:-1", ObjectiveTrackerFrame = "12:-1",
  MicroMenuContainer = "13:-1", MicroButtonAndBagsBar = "13:-1", BagsBar = "14:-1", BuffFrame = "6:0", DebuffFrame = "6:1",
  StatusTrackingBarManager = "15:0", MainStatusTrackingBarContainer = "15:0", SecondaryStatusTrackingBarContainer = "15:1",
  EncounterBar = "4:-1", ExtraAbilityContainer = "5:-1", PlayerCastingBarFrame = "1:-1", DurabilityFrame = "16:-1", DamageMeter = "23:-1",
  EssentialCooldownViewer = "20:0", UtilityCooldownViewer = "20:1", BuffIconCooldownViewer = "20:2", BuffBarCooldownViewer = "20:3",
  SwingTimerMainHandFrame = "29:0", SwingTimerOffHandFrame = "29:1", SwingTimerRangedFrame = "29:2",
}

-- ajustes: pares de caracteres, cada uno vale (código - 35)
local function EMSettings(s)
  local o = {}
  for i = 1, #s - 1, 2 do o[s:byte(i) - 35] = s:byte(i + 1) - 35 end
  return o
end
-- texto del Modo edición: encabezado ("3 59" en la beta, "5 0 59" ahora) y 10 datos por cada pieza
local function EMParse(str)
  local t = {}
  for w in str:gmatch("%S+") do t[#t + 1] = w end
  local out, i = {}, ((tonumber(t[1]) or 0) >= 5) and 4 or 3
  while i + 9 <= #t do
    out[#out + 1] = { sys = tonumber(t[i]), idx = tonumber(t[i + 1]), point = EM_POINTS[tonumber(t[i + 3])] or "CENTER",
      relPoint = EM_POINTS[tonumber(t[i + 4])] or "CENTER", rel = t[i + 5], x = tonumber(t[i + 6]) or 0, y = tonumber(t[i + 7]) or 0,
      set = EMSettings(t[i + 9] or "") }
    i = i + 10
  end
  return out
end
local function nz(v, d) return (v and v ~= 0) and v or d end
-- tamaño aproximado de cada pieza (unidades de interfaz) según sus ajustes
local function EMSize(s)
  local st, sys = s.set, s.sys
  if sys == 0 then
    if st[5] == 3 then return nil end -- barra oculta
    local small = s.idx >= 10
    local btn = (small and 30 or 45) * (st[3] and (50 + 10 * st[3]) / 100 or 1)
    local icons = st[2] and math.max(1, st[2]) or (small and 10 or 12)
    local rows = math.max(1, nz(st[1], 1))
    local pad = (st[4] or 2) + 2
    local a, b = math.ceil(icons / rows) * (btn + pad), rows * (btn + pad)
    if st[0] == 1 then return b, a end
    return a, b
  elseif sys == 1 then return 208, 14
  elseif sys == 2 then return 205, 225
  elseif sys == 3 then
    local k = st[16] and (1 + st[16] * 0.1) or 1
    local sz = ({ [0] = { 232, 100 }, { 232, 100 }, { 232, 100 }, { 120, 200 }, { 360, 220 }, { 200, 250 }, { 200, 250 }, { 120, 50 } })[s.idx]
    if not sz then return nil end
    return sz[1] * k, sz[2] * k
  elseif sys == 4 then return 300, 30
  elseif sys == 5 then return 90, 90
  elseif sys == 6 then
    if s.idx == 1 then return 280, 40 elseif s.idx == 2 then return 120, 40 end
    return 280, 80
  elseif sys == 8 then return nz(st[0], 4) * 100 + nz(st[1], 30), nz(st[2], 1) * 100 + nz(st[3], 80)
  elseif sys == 12 then return 250, (st[0] and st[0] ~= 0) and math.max(200, st[0] * 10) or 600
  elseif sys == 13 then if st[0] == 1 then return 36, 270 end return 270, 36
  elseif sys == 14 then return 200, 40
  elseif sys == 15 then return 570, 12
  elseif sys == 16 then return 60, 75
  elseif sys == 20 then return 300, 50
  elseif sys == 23 then return 300, 170
  elseif sys == 29 then return 200, 12
  end
  return nil
end
local function EMName(s)
  if s.sys == 0 then return EM_BARS[s.idx] or "Barra" end
  if s.sys == 3 then return EM_UNITS[s.idx] or "Marco" end
  if s.sys == 6 then return EM_AURAS[s.idx] or "Auras" end
  if s.sys == 15 then return s.idx == 0 and "Experiencia" or "Reputación" end
  if s.sys == 20 then return "Reutilización " .. (s.idx + 1) end
  if s.sys == 29 then return EM_SWING[s.idx] or "Golpes" end
  return EM_OTHER[s.sys] or ""
end
-- piezas que solo se ven a veces: grupo, banda, jefes, arena, mascota, posesión, encuentro, habilidad extra
local function EMSituational(s)
  return (s.sys == 3 and s.idx >= 3) or (s.sys == 0 and (s.idx == 11 or s.idx == 12)) or s.sys == 4 or s.sys == 5 or (s.sys == 6 and s.idx == 2)
end
local function EMAnchor(p, r)
  local x = p:find("LEFT") and r.l or (p:find("RIGHT") and r.r or (r.l + r.r) / 2)
  local y = p:find("TOP") and r.t or (p:find("BOTTOM") and r.b or (r.t + r.b) / 2)
  return x, y
end
-- rectángulos en unidades de interfaz (y hacia abajo) sobre una pantalla 16:9 del alto que usó el autor
local function EMRects(lay)
  local H = lay.uiH or 1080
  local W = H * 16 / 9
  local root = { l = 0, t = 0, r = W, b = H }
  local systems = EMParse(lay.string or "")
  local byKey, rects, busy = {}, {}, {}
  for _, s in ipairs(systems) do byKey[s.sys .. ":" .. s.idx] = s end
  local function rect(s)
    local key = s.sys .. ":" .. s.idx
    if rects[key] then return rects[key] end
    local w, h = EMSize(s)
    if not w or busy[key] then return nil end
    busy[key] = true
    local ref = root
    local rk = EM_REL[s.rel]
    if s.rel ~= "UIParent" and rk and byKey[rk] then ref = rect(byKey[rk]) or root end
    local ax, ay = EMAnchor(s.relPoint, ref)
    local tx, ty = ax + s.x, ay - s.y
    local l = s.point:find("LEFT") and tx or (s.point:find("RIGHT") and tx - w or tx - w / 2)
    local t = s.point:find("TOP") and ty or (s.point:find("BOTTOM") and ty - h or ty - h / 2)
    local r = { l = l, t = t, r = l + w, b = t + h }
    busy[key] = nil
    rects[key] = r
    return r
  end
  local boxes = {}
  for _, s in ipairs(systems) do
    local kind = EM_KIND[s.sys]
    if kind then
      local r = rect(s)
      if r then boxes[#boxes + 1] = { kind = kind, name = EMName(s), r = r, s = s } end
    end
  end
  return boxes, W, H, #systems
end

-- Cuadro de solo lectura con el texto a importar y un botón que lo deja seleccionado para Ctrl+C
local function CopyBox(parent, y, hintText)
  local box = Panel(parent, K.bg, 1, K.edge, 1)
  box:SetSize(CW - 28 - 118, 26)
  box:SetPoint("TOPLEFT", 14, y)
  local eb = CreateFrame("EditBox", nil, box)
  eb:SetPoint("TOPLEFT", 8, -4)
  eb:SetPoint("BOTTOMRIGHT", -8, 4)
  eb:SetFont(BODY_FONT, 11, "")
  eb:SetTextColor(C3(K.mute))
  eb:SetAutoFocus(false)
  if eb.SetMaxLetters then eb:SetMaxLetters(0) end
  eb.value = ""
  local hint = Text(parent, 10, K.dim)
  hint:SetPoint("TOPLEFT", 14, y - 32)
  hint:SetWidth(CW - 28)
  hint:SetText(hintText)
  eb:SetScript("OnTextChanged", function(self, user) if user then self:SetText(self.value); self:HighlightText() end end)
  eb:SetScript("OnEditFocusGained", function(self)
    self:HighlightText(); self:SetTextColor(C3(K.title))
    hint:SetText("|cff6fb2ffSeleccionado: apretá Ctrl+C para copiar y después Esc.|r")
  end)
  eb:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0); self:SetTextColor(C3(K.mute)); hint:SetText(hintText) end)
  eb:SetScript("OnEscapePressed", eb.ClearFocus)
  eb:SetScript("OnEnterPressed", eb.ClearFocus)
  local sel = SkinButton(CreateFrame("Button", nil, parent, "UIPanelButtonTemplate"), "primary")
  sel:SetSize(108, 26)
  sel:SetPoint("LEFT", box, "RIGHT", 10, 0)
  sel:SetText("Seleccionar")
  sel:SetScript("OnClick", function() eb:SetFocus(); eb:HighlightText(); NS.Sound("tab") end)
  function eb:SetValue(v) self.value = v or ""; self:SetText(self.value); if self.SetCursorPosition then self:SetCursorPosition(0) end end
  return eb, 32 + math.max(14, hint:GetStringHeight()) + 6
end

local function BuildLayouts(P)
  local list = NS.LAYOUTS or {}
  if #list > 0 then
    local C = P:Card("Diseños de jugadores de Forever", "Interface\\Icons\\INV_Misc_Spyglass_03", K.accent)
    local f = C.frame
    local cur, showSitu = 1, false
    local btns, Show = {}, nil
    -- selector de diseño (botones que pasan a otra fila si no entran)
    local x, rowY = 14, C.y
    for i, lay in ipairs(list) do
      local b = CreateFrame("Button", nil, f)
      b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints()
      b.label = Text(b, 11.5, K.parch)
      b.label:SetPoint("CENTER", 0, 0)
      b.label:SetText(lay.short or lay.name)
      local w = math.floor(b.label:GetStringWidth() + 24)
      if x + w > CW - 14 then x = 14; rowY = rowY - 30 end
      b:SetSize(w, 24)
      b:SetPoint("TOPLEFT", x, rowY)
      local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.06)
      b:SetScript("OnClick", function() cur = i; NS.Sound("tab"); Show() end)
      btns[i] = b
      x = x + w + 6
    end
    C.y = rowY - 36

    -- vista previa: la pantalla en 16:9, con un punto donde estaría tu personaje
    local PW = CW - 28
    local PH = math.floor(PW * 9 / 16)
    local prev = Panel(f, K.side, 1, K.line, 1)
    prev:SetSize(PW, PH)
    prev:SetPoint("TOPLEFT", 14, C.y)
    if prev.SetClipsChildren then prev:SetClipsChildren(true) end
    local me = prev:CreateTexture(nil, "BORDER")
    me:SetSize(8, 8)
    me:SetPoint("CENTER", 0, -math.floor(PH * 0.06))
    me:SetColorTexture(C3(K.title, 0.5))
    local meT = Text(prev, 8.5, K.dim, nil, "BORDER")
    meT:SetPoint("TOP", me, "BOTTOM", 0, -3)
    meT:SetText("tu personaje")
    C.y = C.y - PH - 8

    -- leyenda de colores
    local lx, ly = 14, C.y
    for _, it in ipairs(EM_LEGEND) do
      local lbl = Text(f, 10, K.mute)
      lbl:SetText(it[2])
      local w = 14 + lbl:GetStringWidth() + 14
      if lx + w > CW - 14 then lx = 14; ly = ly - 16 end
      local sw = f:CreateTexture(nil, "ARTWORK")
      sw:SetSize(8, 8)
      sw:SetPoint("TOPLEFT", lx, ly - 3)
      sw:SetColorTexture(C3(EM_COLOR[it[1]]))
      lbl:SetPoint("TOPLEFT", lx + 13, ly)
      lx = lx + w
    end
    C.y = ly - 22

    -- casilla: mostrar lo que aparece solo a veces
    local cb = SkinCheck(CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate"))
    cb:SetSize(22, 22)
    cb:SetPoint("TOPLEFT", 10, C.y + 3)
    local cbt = Text(f, 11, K.parch)
    cbt:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cbt:SetText("Mostrar lo que aparece solo a veces (grupo, banda, jefes, arena)")
    cb:SetScript("OnClick", function(self) showSitu = self:GetChecked() and true or false; Show() end)
    C.y = C.y - 28

    -- datos del diseño elegido
    local meta = Text(f, 10.5, K.mute)
    meta:SetPoint("TOPLEFT", 14, C.y)
    meta:SetWidth(CW - 28)
    C.y = C.y - 18
    local desc = Text(f, 11.5, K.parch)
    desc:SetPoint("TOPLEFT", 14, C.y)
    desc:SetWidth(CW - 28)
    desc:SetSpacing(2)
    local dh = 14
    for _, lay in ipairs(list) do desc:SetText(lay.desc or ""); dh = math.max(dh, desc:GetStringHeight()) end
    C.y = C.y - dh - 12
    local src = Text(f, 10, K.dim)
    src:SetPoint("TOPLEFT", 14, C.y)
    src:SetWidth(CW - 28)
    C.y = C.y - 20
    local eb, used = CopyBox(f, C.y, "Apretá Seleccionar y después Ctrl+C. Pegalo en Esc › Modo edición › Diseño › Importar, con un nombre nuevo.")
    C.y = C.y - used

    -- recuadros reutilizables
    local pool = {}
    local function Box(i)
      local b = pool[i]
      if not b then
        b = CreateFrame("Frame", nil, prev, BD)
        b:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, tile = false, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
        b.label = Text(b, 8, K.title)
        b.label:SetPoint("TOPLEFT", 2, -1)
        b.label:SetWordWrap(false)
        b:EnableMouse(true)
        b:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:AddLine(self.name or "", C3(K.title))
          GameTooltip:Show()
        end)
        b:SetScript("OnLeave", GameTooltip_Hide)
        pool[i] = b
      end
      return b
    end

    Show = function()
      local lay = list[cur]
      for i, b in ipairs(btns) do
        local on = i == cur
        b.bg:SetColorTexture(C3(on and K.accent or K.raised))
        b.label:SetTextColor(C3(on and K.title or K.parch))
      end
      local boxes, W, H = EMRects(lay)
      -- los grandes abajo y los chicos arriba, para que se puedan señalar
      table.sort(boxes, function(a, b) return (a.r.r - a.r.l) * (a.r.b - a.r.t) > (b.r.r - b.r.l) * (b.r.b - b.r.t) end)
      local sx, sy = PW / W, PH / H
      local n = 0
      for _, bx in ipairs(boxes) do
        if showSitu or not EMSituational(bx.s) then
          n = n + 1
          local b = Box(n)
          local c = EM_COLOR[bx.kind] or K.title
          local w, h = math.max(3, (bx.r.r - bx.r.l) * sx), math.max(3, (bx.r.b - bx.r.t) * sy)
          b:ClearAllPoints()
          b:SetPoint("TOPLEFT", prev, "TOPLEFT", bx.r.l * sx, -bx.r.t * sy)
          b:SetSize(w, h)
          b:SetBackdropColor(c[1], c[2], c[3], 0.2)
          b:SetBackdropBorderColor(c[1], c[2], c[3], 0.9)
          b:SetFrameLevel(prev:GetFrameLevel() + n)
          b.name = bx.name
          b.label:SetText(bx.name)
          b.label:SetWidth(math.max(1, w - 4))
          b.label:SetShown(w > 34 and h > 10)
          b:Show()
        end
      end
      for i = n + 1, #pool do pool[i]:Hide() end
      local bits = { lay.author }
      if lay.date and lay.date ~= "" then bits[#bits + 1] = lay.date end
      bits[#bits + 1] = lay.version
      meta:SetText("|cfff2f4f8" .. (lay.name or "") .. "|r   " .. table.concat(bits, " · "))
      desc:SetText(lay.desc or "")
      src:SetText("Publicado en " .. (lay.site or "") .. ":  " .. (lay.url or ""))
      eb:SetValue(lay.string)
    end
    C:Finish()
    Show()
  end

  -- antes de importar
  local A = P:Card("Antes de importar", "Interface\\Icons\\INV_Misc_Note_01", K.warn)
  A:Note("Guardá el tuyo: en Modo edición elegí tu diseño, Compartir › Copiar al portapapeles, y pegalo en la pestaña Notas.")
  A:Note("Importá siempre como diseño nuevo, con otro nombre. Si no te convence, volvés al tuyo desde la lista de diseños.")
  A:Note("La vista previa es aproximada: las posiciones son las del autor y los tamaños, estimados. Con otra resolución o escala de interfaz algo puede quedar corrido.")
  A:Note("En los foros de Forever un jugador contó que importar un diseño ajeno le rompió el Modo edición. Por eso el Códice no los aplica solo: los importás vos, fuera de combate.")
  A:Finish()

  -- Administrador de reutilización (no mueve nada de la pantalla)
  for _, c in ipairs(NS.CDM or {}) do
    local R = P:Card("Reutilización: " .. (c.name or ""), "Interface\\Icons\\Spell_Nature_Bloodlust", K.accent)
    R:Text("|cfff2f4f8" .. (c.author or "") .. "|r · " .. (c.date or ""), 10.5, K.mute)
    R:Text(c.desc or "", 11.5, K.parch)
    R:Text("No mueve nada de la pantalla: elige qué habilidades muestran los íconos de reutilización y en qué orden.", 11, K.mute)
    R:Text("Publicado en " .. (c.site or "") .. ":  " .. (c.url or ""), 10, K.dim)
    local ceb, used = CopyBox(R.frame, R.y, "Apretá Seleccionar y después Ctrl+C. En el juego escribí /cdm › Importar diseño, pegalo y elegilo.")
    ceb:SetValue(c.string)
    R.y = R.y - used
    R:Finish()
  end

  -- de dónde salen
  local D = P:Card("De dónde salen", "Interface\\Icons\\INV_Misc_Book_09", K.accent)
  for _, lay in ipairs(list) do
    D:Text("|cfff2f4f8" .. (lay.name or "") .. "|r  ·  " .. (lay.author or "") .. "  ·  " .. (lay.site or ""), 10.5, K.parch)
  end
  for _, c in ipairs(NS.CDM or {}) do
    D:Text("|cfff2f4f8Reutilización: " .. (c.name or "") .. "|r  ·  " .. (c.author or "") .. "  ·  " .. (c.site or ""), 10.5, K.parch)
  end
  D:Text("Los textos son de sus autores; el Códice solo los muestra con su nombre y de dónde salieron.", 10, K.dim)
  D:Finish()
end

local function BuildNotes(tab, parent)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetPoint("TOPLEFT", NAV_W + 22, -(HEAD_H + 16))
  holder.__a = { NAV_W + 22, -(HEAD_H + 16), -18, 14 }
  holder:SetPoint("BOTTOMRIGHT", -18, 14)
  holder:Hide()
  local t = Text(holder, 19, K.title, TITLE_FONT)
  t:SetPoint("TOPLEFT", 0, 0)
  t:SetText("Notas")
  local l = Text(holder, 11.5, K.mute)
  l:SetPoint("TOPLEFT", 0, -27)
  l:SetText(tab.lead)
  -- hoja oscura con borde fino, como un editor
  local paper = Panel(holder, K.card, 1, K.line, 1)
  paper:SetPoint("TOPLEFT", 0, -50)
  paper:SetPoint("BOTTOMRIGHT", 0, 0)
  local scroll = CreateFrame("ScrollFrame", nil, paper, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 14, -12)
  scroll:SetPoint("BOTTOMRIGHT", -30, 12)
  local eb = CreateFrame("EditBox", nil, scroll)
  eb:SetMultiLine(true)
  eb:SetFont(BODY_FONT, 13, "")
  eb:SetTextColor(C3(K.parch))
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
  if tab.keys then BuildKeys(P) end
  if tab.layouts then BuildLayouts(P) end

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
      b.sel:SetShown(on); b.accent:SetShown(on); if rawget(b, "glow") then b.glow:SetShown(on) end
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
  -- marco liso con borde de 1 px
  f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, tile = false, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
  f:SetBackdropColor(K.bg[1], K.bg[2], K.bg[3], 0.98)
  f:SetBackdropBorderColor(C3(K.edge))
  f:Hide()
  tinsert(UISpecialFrames, "PiolinCodexFrame")

  -- línea azul arriba que se desvanece hacia la derecha
  local topLine = f:CreateTexture(nil, "ARTWORK")
  topLine:SetPoint("TOPLEFT", 1, -1); topLine:SetPoint("TOPRIGHT", -1, -1); topLine:SetHeight(2)
  Grad(topLine, "HORIZONTAL", K.accent, 1, K.accent, 0)

  -- retrato, título y personaje
  local por = f:CreateTexture(nil, "ARTWORK")
  por:SetSize(36, 36)
  por:SetPoint("TOPLEFT", 16, -15)
  SetPortraitTexture(por, "player")
  f.portrait = por

  local title = Text(f, 17, K.title, TITLE_FONT)
  title:SetPoint("TOPLEFT", 62, -16)
  title:SetText("Códice de Piolin")
  f.sub = Text(f, 11.5, K.mute)
  f.sub:SetPoint("TOPLEFT", 62, -37)

  -- progreso total a la derecha
  f.pctText = Text(f, 16, K.title, TITLE_FONT)
  f.pctText:SetPoint("TOPRIGHT", -54, -15)
  f.pctText:SetJustifyH("RIGHT")
  local pl = Text(f, 10.5, K.mute)
  pl:SetPoint("RIGHT", f.pctText, "LEFT", -8, 0)
  pl:SetText("Guía completada")
  pl:SetJustifyH("RIGHT")
  f.pctBar = Bar(f, 170, 4, K.accent)
  f.pctBar:SetPoint("TOPRIGHT", -54, -41)
  f.pctBar.text:Hide()

  -- cerrar: botón cuadrado con borde fino
  local close = CreateFrame("Button", nil, f)
  close:SetSize(26, 26)
  close:SetPoint("TOPRIGHT", -16, -20)
  local cbg = Panel(close, K.bg, 1, K.edge, 1)
  cbg:SetAllPoints()
  close.x = Text(cbg, 15, K.mute)
  close.x:SetPoint("CENTER", 0, 1)
  close.x:SetText("×")
  local chl = close:CreateTexture(nil, "HIGHLIGHT")
  chl:SetAllPoints(); chl:SetColorTexture(1, 1, 1, 0.06)
  close:SetScript("OnClick", function() f:Hide() end)

  local div = f:CreateTexture(nil, "ARTWORK")
  div:SetPoint("TOPLEFT", 1, -HEAD_H); div:SetPoint("TOPRIGHT", -1, -HEAD_H); div:SetHeight(1)
  div:SetColorTexture(C3(K.line))

  -- navegación lateral
  local side = Panel(f, K.side, 1, K.side, 1)
  side:SetPoint("TOPLEFT", 1, -(HEAD_H + 1))
  side:SetPoint("BOTTOMLEFT", 1, 1)
  side:SetWidth(NAV_W)
  local sideLine = side:CreateTexture(nil, "ARTWORK")
  sideLine:SetPoint("TOPRIGHT", 0, 0); sideLine:SetPoint("BOTTOMRIGHT", 0, 0); sideLine:SetWidth(1)
  sideLine:SetColorTexture(C3(K.line))
  for i, tab in ipairs(NS.TABS) do
    local st = TAB_STYLE[tab.key] or { K.gold, tab.icon }
    local b = CreateFrame("Button", nil, side)
    b:SetSize(NAV_W - 16, 36)
    b:SetPoint("TOPLEFT", 8, -10 - (i - 1) * 38)
    b.sel = b:CreateTexture(nil, "BACKGROUND")
    b.sel:SetAllPoints()
    b.sel:SetColorTexture(0.08, 0.114, 0.165, 1)
    b.accent = b:CreateTexture(nil, "ARTWORK")
    b.accent:SetPoint("TOPLEFT", 0, -6); b.accent:SetPoint("BOTTOMLEFT", 0, 6); b.accent:SetWidth(2)
    b.accent:SetColorTexture(C3(K.accent))
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.04)
    local ic = Framed(b, st[2], 20)
    ic:SetPoint("LEFT", 10, 0)
    b.label = Text(b, 12.5, K.parch)
    b.label:SetPoint("LEFT", ic, "RIGHT", 10, 0)
    b.label:SetText(tab.key == "ruta" and "Ruta 20-60" or tab.label)
    b.count = Text(b, 10.5, K.dim)
    b.count:SetPoint("RIGHT", -10, 0)
    b.count:SetJustifyH("RIGHT")
    b:SetScript("OnClick", function() NS.Sound("tab"); NS.ShowTab(i) end)
    Tooltip(b, tab.key == "ruta" and "Ruta 20-60" or tab.label, { tab.lead })
    nav[i] = b
  end
  local hint = Text(side, 10, K.dim)
  hint:SetPoint("BOTTOMLEFT", 18, 14)
  hint:SetWidth(NAV_W - 30)
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
