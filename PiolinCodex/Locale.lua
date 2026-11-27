-- Códice de Piolin: traducciones
-- Las claves son el texto en español. En un cliente que no está en español se usa la tabla
-- en inglés; si una frase no está traducida, se muestra en español (nunca queda vacía).
-- El contenido de la guía (misiones, rutas, consejos) está solo en español.
local ADDON, NS = ...

local loc = GetLocale and GetLocale() or "esES"
local spanish = loc == "esES" or loc == "esMX"

local EN = {
  -- ventana
  ["Hoy"] = "Today", ["Guía"] = "Guide", ["Oficios"] = "Professions", ["Combate"] = "Combat",
  ["Interfaz"] = "Interface", ["Notas"] = "Notes",
  ["Tus números y lo que te toca ahora."] = "Your numbers and what to do next.",
  ["Misiones y ruta del 20 al 60."] = "Quests and the 20-60 route.",
  ["Peletería, desuello, pesca, cocina y campamento."] = "Leatherworking, skinning, fishing, cooking and camp.",
  ["Rotación, tótems, equipo, talentos, macros y teclas."] = "Rotation, totems, gear, talents, macros and keybinds.",
  ["Diseños del Modo edición que compartieron jugadores de Forever."] = "Edit Mode layouts shared by Forever players.",
  ["Escribí lo que quieras: se guarda en tu personaje."] = "Write anything: it is saved on this character.",
  ["Guía completada"] = "Guide completed", ["Configuración"] = "Settings", ["Cerrar"] = "Close",
  ["Nivel"] = "Level", ["Oro"] = "Gold", ["Talentos"] = "Talents",
  ["Ahora te toca"] = "Up next", ["Para el próximo nivel"] = "For your next level",
  ["sin gastar"] = "unspent", ["todos gastados"] = "all spent", ["nivel máximo"] = "max level",
  ["%d%% del nivel"] = "%d%% of level", ["descanso %d%%"] = "rested %d%%",
  ["montura del 40: %d%%"] = "level 40 mount: %d%%",
  ["¡Guía al día! No queda nada pendiente."] = "Guide done! Nothing left to do.",
  ["Ir"] = "Go", ["entregar"] = "turn in", ["en registro"] = "in log",
  ["Ver en la guía"] = "Show in guide", ["Tildar"] = "Check off",
  ["Pasá el mouse por una fila para ver el detalle."] = "Hover a row for details.",
  ["Nivel %d"] = "Level %d", ["En el instructor"] = "At the trainer",
  -- HUD
  ["Escudo de relámpagos"] = "Lightning Shield", ["Imbuición del arma"] = "Weapon imbue",
  ["falta"] = "missing", ["Te falta"] = "Missing", ["Le quedan %s"] = "%s left",
  ["Tierra"] = "Earth", ["Fuego"] = "Fire", ["Agua"] = "Water", ["Aire"] = "Air",
  ["Ninguno puesto"] = "None placed", ["Tótem de %s"] = "%s totem",
  ["Destrabá los marcos en la configuración para moverlo."] = "Unlock frames in the settings to move it.",
  ["Arrastrá para mover"] = "Drag to move",
  -- tooltip
  ["Subasta %s · vendedor %s"] = "AH %s · vendor %s", ["Subasta %s"] = "AH %s", ["Vendedor %s"] = "Vendor %s",
  ["→ subasta"] = "→ AH", ["→ vendedor"] = "→ vendor", ["sin precio de subasta"] = "no AH price",
  ["Peletería %s: %d"] = "Leatherworking %s: %d", ["tenés %d"] = "you have %d",
  ["Ya pasaste los tramos que lo usan"] = "You are past the tiers that use it",
  ["Shift: más detalle"] = "Shift: more detail",
  -- configuración
  ["General"] = "General", ["Misiones y mapa"] = "Quests and map", ["Comercio"] = "Trading",
  ["Oficios y pesca"] = "Professions and fishing", ["Sonido"] = "Sound", ["Perfil"] = "Profile",
  ["Restablecer sección"] = "Reset section", ["Restablecer todo"] = "Reset all",
  ["Bloquear marcos"] = "Lock frames", ["Destrabalos para moverlos; vale para todos los del Códice."] = "Unlock them to move; applies to all Codex frames.",
  ["Escala de la ventana"] = "Window scale", ["Escala del HUD"] = "HUD scale",
  ["Letra"] = "Font", ["La del Códice (Inter)"] = "Codex font (Inter)", ["La del juego"] = "Game font",
  ["Se aplica al recargar la interfaz (/reload)."] = "Applies after reloading the UI (/reload).",
  ["HUD de combate"] = "Combat HUD", ["Escudo, imbuición y tótems con su tiempo."] = "Shield, imbue and totems with their timers.",
  ["Mostrar el HUD"] = "Show HUD", ["Siempre"] = "Always", ["Solo en combate"] = "Combat only", ["En combate"] = "In combat", ["Oculto"] = "Hidden",
  ["Las preferencias son de este personaje. Copiá las de otro:"] = "Settings belong to this character. Copy another's:",
  ["Todavía no hay otros personajes con el Códice."] = "No other characters with the Codex yet.",
  ["Copiar"] = "Copy", ["Abrir el Códice"] = "Open the Codex", ["Probar un aviso"] = "Test an alert",
  ["Crear macros"] = "Create macros", ["Quitar la flecha"] = "Clear arrow", ["Borrar todas las tildes"] = "Clear all checks",
  ["Tecla para abrir el Códice"] = "Key to open the Codex", ["Elegir tecla"] = "Set key", ["Quitar"] = "Clear",
  ["Opciones de sonido"] = "Sound options",
}

local L = setmetatable({}, { __index = function(_, k) return k end })
if not spanish then
  for k, v in pairs(EN) do rawset(L, k, v) end
end
NS.L = L
NS.isSpanish = spanish
