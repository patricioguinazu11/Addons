-- Códice de Piolin: pistas de desuello en el tooltip de las bestias
local ADDON, NS = ...

local function DB() return NS.db end

-- Tipos de criatura que se pueden desollar (nombres del cliente en español y en inglés)
local SKINNABLE = { ["bestia"] = true, ["beast"] = true, ["dragonante"] = true, ["dragonkin"] = true, ["dragón"] = true }

-- Desuello necesario según el nivel de la criatura (regla del juego clásico)
--   nivel 1-10: 1 · nivel 11-20: (nivel - 10) x 10 · nivel 21 o más: nivel x 5
function NS.SkinRequired(level)
  if level <= 10 then return 1 end
  if level <= 20 then return (level - 10) * 10 end
  return level * 5
end

-- Dificultad, como en la recolección: naranja, amarillo, verde, gris
local function Difficulty(skill, req)
  if skill < req then return "red" end
  local d = skill - req
  if d < 25 then return "orange" end
  if d < 50 then return "yellow" end
  if d < 100 then return "green" end
  return "gray"
end
local TEXT = {
  red = { "|cffff4040", "No la podés desollar todavía" },
  orange = { "|cffff8040", "Te da un punto seguro" },
  yellow = { "|cffffff00", "Casi siempre te da punto" },
  green = { "|cff40c040", "A veces te da punto" },
  gray = { "|cff9d9d9d", "Ya no te da puntos" },
}

local function Secret(v) return NS.IsSecret and NS.IsSecret(v) end

local function AddLines(tt)
  if not NS.db or DB().noSkinTips then return end
  local ok, _, unit = pcall(tt.GetUnit, tt)
  if not ok or not unit or Secret(unit) then unit = "mouseover" end
  if not UnitExists(unit) or UnitIsPlayer(unit) then return end
  local ctype = UnitCreatureType(unit)
  if not ctype or Secret(ctype) or not SKINNABLE[ctype:lower()] then return end
  local level = UnitLevel(unit)
  if not level or Secret(level) then return end
  local skill = NS.Skill("Desuello")
  if not skill then return end
  if level < 0 then
    tt:AddLine("|cffd9a93fCódice|r · Desuello: nivel desconocido (calavera)", 0.7, 0.7, 0.7)
    tt:Show()
    return
  end
  local req = NS.SkinRequired(level)
  local diff = Difficulty(skill, req)
  local t = TEXT[diff]
  tt:AddLine("|cffd9a93fCódice|r · Desuello: necesitás " .. req .. ", tenés " .. skill, 1, 1, 1)
  if diff == "red" then
    tt:AddLine(t[1] .. t[2] .. " (te faltan " .. (req - skill) .. ")|r")
  else
    tt:AddLine(t[1] .. t[2] .. "|r")
  end
  tt:Show()
end

if NS.HookUnitTooltip then NS.HookUnitTooltip(AddLines) end
