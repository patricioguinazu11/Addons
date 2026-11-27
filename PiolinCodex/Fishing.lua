-- Códice de Piolin: pescar con doble clic derecho
-- Con la caña equipada y fuera de combate, un doble clic derecho en el mundo lanza Pesca.
-- Para recoger, clic derecho en el corcho como siempre. Es la técnica de los addons de pesca:
-- en el segundo clic se presta el botón derecho a un botón seguro con Pesca, y se devuelve enseguida.
local ADDON, NS = ...

local function DB() return NS.db end

local DOUBLE = 0.4      -- segundos entre los dos clics
local FISHING_ID = 7620 -- Pesca (rango 1); el juego lanza el mejor rango que tengas

local owner = CreateFrame("Frame")
local btn, lastDown, armed

local function FishingName()
  local name = GetSpellInfo and GetSpellInfo(FISHING_ID)
  return name or "Pesca"
end

local function PoleEquipped()
  local mh = GetInventoryItemID("player", 16)
  if not mh then return false end
  local _, _, _, _, _, _, _, _, _, _, _, classID, subID = GetItemInfo(mh)
  return classID == 2 and subID == 20
end

-- ¿Está pescando ahora? (si ya hay corcho, el clic derecho es para recogerlo)
local function Channeling()
  local name = UnitChannelInfo and UnitChannelInfo("player")
  return name ~= nil and name == FishingName()
end

local function Disarm()
  if not armed then return end
  if InCombatLockdown() then return end
  armed = nil
  ClearOverrideBindings(owner)
end
NS.FishDisarm = Disarm

local function CanCast()
  if not NS.db or DB().noFishClick then return false end
  if InCombatLockdown() then return false end
  if not PoleEquipped() then return false end
  if Channeling() then return false end
  if IsMounted and IsMounted() then return false end
  if UnitExists("mouseover") then return false end
  return true
end

local function Build()
  btn = CreateFrame("Button", "PiolinCodexFishButton", UIParent, "SecureActionButtonTemplate")
  btn:SetSize(1, 1)
  btn:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10, 10)
  btn:RegisterForClicks("AnyUp", "AnyDown")
  btn:SetAttribute("type", "spell")
  btn:SetAttribute("spell", FishingName())
  btn:SetScript("PostClick", function() Disarm() end)
  btn:Hide(); btn:Show()
end

-- Segundo clic derecho rápido: el botón derecho lanza Pesca al soltarlo
local function OnWorldMouseDown(_, button)
  if button ~= "RightButton" then return end
  local now = GetTime()
  if lastDown and now - lastDown <= DOUBLE and CanCast() then
    lastDown = nil
    armed = true
    SetOverrideBindingClick(owner, true, "BUTTON2", "PiolinCodexFishButton")
    -- por si el clic no llega a soltarse sobre el mundo
    C_Timer.After(1, Disarm)
  else
    lastDown = now
  end
end

local ev = CreateFrame("Frame")
NS.SafeEvents(ev, { "PLAYER_LOGIN", "PLAYER_REGEN_DISABLED", "SPELLS_CHANGED" })
ev:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    if not pcall(Build) then return end
    WorldFrame:HookScript("OnMouseDown", OnWorldMouseDown)
  elseif event == "PLAYER_REGEN_DISABLED" then
    -- al entrar en combate se devuelve el botón derecho sí o sí
    armed = true
    pcall(ClearOverrideBindings, owner)
    armed = nil
  elseif event == "SPELLS_CHANGED" and btn and not InCombatLockdown() then
    btn:SetAttribute("spell", FishingName())
  end
end)
