-- Códice de Piolin: datos de las funciones automáticas
local ADDON, NS = ...

-- Mapas (uiMapID) para TomTom
local LOCH_MODAN, REDRIDGE, ARATHI = 1432, 1433, 1417

-- Puntos de ruta: id del ítem -> { mapa, x, y, título }
NS.WAYPOINTS = {
  tc1  = { REDRIDGE, 9.6, 71.0, "Marcy Baker (Tres Esquinas)", { "Montañas Crestagrana", "Redridge Mountains" } },
  tc2  = { REDRIDGE, 10.0, 72.6, "Daniel Hilvanante (Tres Esquinas)", { "Montañas Crestagrana", "Redridge Mountains" } },
  tr4  = { LOCH_MODAN, 41.9, 19.0, "Norric Lochthane (misión de Agua)", { "Loch Modan" } },
  r30b = { ARATHI, 59.8, 27.6, "Veyric Thundervein (misión de Aire)", { "Tierras Altas de Arathi", "Arathi Highlands" } },
}

-- Tildes automáticas
NS.AUTO = {
  -- misión completada (ID del juego clásico)
  quest = {
    dm1 = 168,   -- Recolección de recuerdos
    dm2 = 167,   -- Oh, hermano...
    dm3 = 2040,  -- Asalto subterráneo
    dm4 = 214,   -- Pañuelos de seda roja
    dm7 = 166,   -- La Hermandad Defias (VanCleef)
    dm9 = 373,   -- La carta sin enviar
  },
  -- nivel alcanzado
  level = { r20d = 25, r30b = 30, r30c = 32, r30g = 40, mt1 = 40, r50e = 60, mt2 = 60 },
  -- habilidad de profesión: { profesión, valor, "rank" o "max" }
  skill = {
    lw1 = { "Peletería", 90 }, lw2 = { "Peletería", 100 }, lw3 = { "Peletería", 115 },
    lw4 = { "Peletería", 125 }, lw5 = { "Peletería", 151, "max" }, lw6 = { "Peletería", 130 },
    lw7 = { "Peletería", 143 }, lw8 = { "Peletería", 155 },
    f1a = { "Pesca", 151, "max" }, f1b = { "Cocina", 151, "max" },
    f2d = { "Cocina", 175 }, f3a = { "Pesca", 225 }, f4a = { "Pesca", 226, "max" },
    lp2 = { "Desuello", 151, "max" },
  },
}

-- Nombres posibles de cada profesión en el cliente en español
NS.SKILL_ALIASES = {
  ["Peletería"] = { "Peletería" },
  ["Pesca"] = { "Pesca" },
  ["Cocina"] = { "Cocina" },
  ["Desuello"] = { "Desuello", "Desollar" },
  ["Primeros auxilios"] = { "Primeros auxilios" },
}

-- Cartel al subir de nivel
NS.LEVEL_TIPS = {
  [21] = "Punto en Armas elementales (1/3).",
  [22] = "Armas elementales 2/3. Entrená en Forjaz: rangos de Choque de llamas y Lengua de fuego.",
  [23] = "Armas elementales 3/3.",
  [24] = "Anticipación 1/3. Mañana: Golpe de tormenta.",
  [25] = "¡GOLPE DE TORMENTA! Primer punto de legado. Agregá la macro PC Tormenta a tu barra.",
  [26] = "Lobo fantasmal mejorado 1/2. Excavación: Los Humedales por el Heavehammer.",
  [27] = "Lobo fantasmal mejorado 2/2: ya es instantáneo.",
  [28] = "Ráfaga 1/5. Defensor de Dalaran en Ciudad de Dalaran.",
  [29] = "Ráfaga 2/5. Corpsemaker en Horado Rajacieno.",
  [30] = "¡ARMA VIENTO FURIOSO! Cambiá la imbuición. Regreso astral y misión de Aire en Arathi. Gnomeregan: Manual Crowd Pummeler.",
  [32] = "Cadena de relámpagos y Tótem Viento furioso.",
  [35] = "Misión de Artesano de pesca con Nat Pagle (Marjal Revolcafango).",
  [40] = "¡MONTURA! Equitación (100 oro) y el oso del pack. Malla y doble especialización.",
  [42] = "Fortaleza Krol'dok: Bigger Rock on Bigger Stick.",
  [50] = "Beastslayer en Un'Goro.",
  [60] = "¡NIVEL 60! Ira del Clarividente, Equitación de oficial y tu Garrazul cerúleo.",
}

-- Ventana del instructor de chamán
NS.TRAINER = {
  buy = {
    "Choque de tierra y Choque de llamas (todos los rangos)",
    "Escudo de relámpagos (todos los rangos)",
    "Nova de fuego y Tótem abrasador",
    "Tótem Fuerza de la tierra",
    "Ola de sanación y Descarga de relámpagos (rangos pares)",
    "Arma Lengua de fuego hasta el 30; después Arma Viento furioso",
    "Lobo fantasmal, Llamada de los elementos, Regreso astral",
  },
  skip = {
    "Tótems de resistencia (escarcha, fuego, naturaleza)",
    "Caminar sobre el agua y Respiración acuática",
    "Rangos altos de Garra de piedra, Nexo terrestre, Temblor y Choque de escarcha (rango 1 alcanza)",
    "Arma Muerdepiedras (salvo para tanquear)",
  },
}

-- Tramos de Peletería con materiales (ID de objeto, cantidad, nombre)
NS.LW_TIERS = {
  { min = 80,  max = 90,  recipe = "Piel media curada x10", mats = { { 4232, 10, "Piel media" }, { 4289, 10, "Sal" } } },
  { min = 90,  max = 100, recipe = "Cinturón de cuero fino x19", mats = { { 2318, 114, "Cuero ligero" }, { 2320, 38, "Hilo burdo" } } },
  { min = 100, max = 115, recipe = "Pantalones de cuero ligero x24", mats = { { 2318, 240, "Cuero ligero" }, { 4231, 24, "Piel ligera curada" }, { 2321, 24, "Hilo fino" } } },
  { min = 115, max = 125, recipe = "Cinturón de cuero oscuro x10", mats = { { 4246, 10, "Cinturón de cuero fino" }, { 4233, 10, "Piel media curada" }, { 2321, 20, "Hilo fino" }, { 4340, 10, "Tinte gris" } } },
  { min = 125, max = 130, recipe = "Cuero pesado x7", mats = { { 2319, 35, "Cuero medio" } } },
  { min = 130, max = 143, recipe = "Piel pesada curada x30", mats = { { 4235, 30, "Piel pesada" }, { 4289, 90, "Sal" } } },
  { min = 143, max = 155, recipe = "Guantes de cuero de montañés x17", mats = { { 2319, 238, "Cuero medio" }, { 2321, 68, "Hilo fino" } } },
}

NS.MOUNT_GOAL = 100 * 10000  -- 100 de oro, en cobre

-- Ranuras de equipo a revisar
NS.SLOTS = {
  { 1, "Cabeza" }, { 2, "Cuello" }, { 3, "Hombros" }, { 15, "Espalda" }, { 5, "Pecho" },
  { 9, "Muñecas" }, { 10, "Manos" }, { 6, "Cintura" }, { 7, "Piernas" }, { 8, "Pies" },
  { 11, "Anillo 1" }, { 12, "Anillo 2" }, { 13, "Abalorio 1" }, { 14, "Abalorio 2" },
  { 16, "Arma" }, { 18, "Reliquia" },
}

-- Teclas: propuesta para Mejora en Forever, armada con el criterio de jugadores reales
-- (se genera desde la vista; layer = modificador, key = tecla o botón del mouse)
NS.KEYMAP = {
  why = "Ataques en 1-5 sin modificador, como las cuatro configuraciones de Mejora. Choques de llamas y escarcha juntos porque comparten tiempo de reutilización (WarcraftMaps). La interrupción siempre en Q sin modificador (WarcraftMaps, Undying) y el control urgente al lado, en E. Tótems por elemento en el mouse con Shift y Ctrl para las variantes (GrooveMaster, ograymic): agua en el botón 4, aire en el 5, tierra con la rueda hacia arriba, fuego hacia abajo, y el clic de la rueda baja todos los tótems. Escudos e imbuiciones duran mucho en Forever, así que van en Z y X, lejos (Sujezz, GrooveMaster). Curas con Shift sobre los números (Sujezz, WarcraftMaps). Lobo fantasmal en T (GrooveMaster) y montura en ` (ograymic). Si tu mouse no tiene botones laterales, los tótems de agua y aire pueden ir a G y V con las mismas variantes. Los nombres en inglés son hechizos que no aparecen en los datos del addon, para no inventar la traducción.",
  binds = {
    { layer = "", key = "1", spell = "Golpe de tormenta", cat = "ataque", icon = "Interface\\Icons\\ability_shaman_stormstrike", note = "macro con /startattack (como ograymic y Sujezz)" },
    { layer = "", key = "2", spell = "Choque de llamas", cat = "choque", icon = "Interface\\Icons\\spell_fire_flameshock", note = "al lado de escarcha: comparten tiempo de reutilización" },
    { layer = "", key = "3", spell = "Choque de escarcha", cat = "choque", icon = "Interface\\Icons\\spell_frost_frostshock", note = "frenar al que huye" },
    { layer = "", key = "4", spell = "Descarga de relámpagos", cat = "ataque", icon = "Interface\\Icons\\spell_nature_lightning", note = "para tirar antes de que llegue" },
    { layer = "", key = "5", spell = "Cadena de relámpagos", cat = "ataque", icon = "Interface\\Icons\\spell_nature_chainlightning" },
    { layer = "Shift", key = "1", spell = "Ola de sanación inferior", cat = "cura", icon = "Interface\\Icons\\spell_nature_healingwavelesser", note = "cura rápida" },
    { layer = "Shift", key = "2", spell = "Ola de sanación", cat = "cura", icon = "Interface\\Icons\\spell_nature_magicimmunity", note = "cura grande entre peleas" },
    { layer = "", key = "Q", spell = "Choque de tierra", cat = "choque", icon = "Interface\\Icons\\spell_nature_earthshock", note = "interrupción: siempre la misma tecla" },
    { layer = "Shift", key = "Q", spell = "Purge", cat = "choque", icon = "Interface\\Icons\\spell_nature_purge", note = "quitar beneficios al enemigo (nombre en inglés)" },
    { layer = "", key = "E", spell = "Tótem Nexo terrestre", cat = "totem", icon = "Interface\\Icons\\spell_nature_strengthofearthtotem02", note = "control urgente, a mano" },
    { layer = "Shift", key = "E", spell = "Tótem derribador", cat = "totem", icon = "Interface\\Icons\\spell_nature_groundingtotem", note = "se come un hechizo enemigo" },
    { layer = "Ctrl", key = "E", spell = "Tótem Garra de piedra", cat = "totem", icon = "Interface\\Icons\\spell_nature_stoneclawtotem", note = "defensa de emergencia" },
    { layer = "", key = "R", spell = "Ira del Clarividente", cat = "cooldown", icon = "Interface\\Icons\\INV_Misc_QuestionMark", note = "desde el 50 (talento); ícono desconocido" },
    { layer = "", key = "T", spell = "Lobo fantasmal", cat = "movilidad", icon = "Interface\\Icons\\spell_nature_spiritwolf" },
    { layer = "", key = "`", spell = "Montura", cat = "movilidad", icon = "Interface\\Icons\\ability_mount_mountainram" },
    { layer = "", key = "F", spell = "Poción de vida", cat = "consumible", icon = "Interface\\Icons\\inv_potion_54" },
    { layer = "Shift", key = "F", spell = "Poción de maná", cat = "consumible", icon = "Interface\\Icons\\inv_potion_76" },
    { layer = "", key = "G", spell = "Comida o bebida", cat = "consumible", icon = "Interface\\Icons\\inv_misc_food_15", note = "fuera de combate" },
    { layer = "", key = "Z", spell = "Escudo de relámpagos", cat = "buff", icon = "Interface\\Icons\\spell_nature_lightningshield", note = "antes de pelear" },
    { layer = "Shift", key = "Z", spell = "Escudo de agua", cat = "buff", icon = "Interface\\Icons\\ability_shaman_watershield" },
    { layer = "", key = "X", spell = "Arma Lengua de fuego", cat = "buff", icon = "Interface\\Icons\\spell_fire_flametounge", note = "imbuición de los niveles 10-29" },
    { layer = "Shift", key = "X", spell = "Arma Viento furioso", cat = "buff", icon = "Interface\\Icons\\spell_nature_cyclone", note = "imbuición desde el 30" },
    { layer = "Ctrl", key = "X", spell = "Arma Muerdepiedras", cat = "buff", icon = "Interface\\Icons\\spell_nature_rockbiter", note = "para tanquear" },
    { layer = "", key = "C", spell = "Regreso astral", cat = "movilidad", icon = "Interface\\Icons\\spell_nature_astralrecal" },
    { layer = "", key = "Mouse4", spell = "Tótem Corriente de sanación", cat = "totem", icon = "Interface\\Icons\\inv_spear_04", note = "agua" },
    { layer = "Shift", key = "Mouse4", spell = "Mana Spring Totem", cat = "totem", icon = "Interface\\Icons\\spell_nature_manaregentotem", note = "agua (nombre en inglés)" },
    { layer = "", key = "Mouse5", spell = "Tótem Viento furioso", cat = "totem", icon = "Interface\\Icons\\spell_nature_windfury", note = "aire, en grupo" },
    { layer = "Shift", key = "Mouse5", spell = "Grace of Air Totem", cat = "totem", icon = "Interface\\Icons\\spell_nature_invisibilitytotem", note = "aire (nombre en inglés)" },
    { layer = "", key = "Rueda arriba", spell = "Tótem Fuerza de la tierra", cat = "totem", icon = "Interface\\Icons\\spell_nature_earthbindtotem", note = "tierra" },
    { layer = "Shift", key = "Rueda arriba", spell = "Tótem Piel de piedra", cat = "totem", icon = "Interface\\Icons\\spell_nature_stoneskintotem", note = "tierra, cuando te pegan fuerte" },
    { layer = "Ctrl", key = "Rueda arriba", spell = "Tótem Temblor", cat = "totem", icon = "Interface\\Icons\\spell_nature_tremortotem", note = "contra miedo y sueño" },
    { layer = "", key = "Rueda abajo", spell = "Tótem abrasador", cat = "totem", icon = "Interface\\Icons\\spell_fire_searingtotem", note = "fuego, peleando solo" },
    { layer = "Shift", key = "Rueda abajo", spell = "Tótem Nova de fuego", cat = "totem", icon = "Interface\\Icons\\spell_fire_sealoffire", note = "fuego, 3 o más enemigos" },
    { layer = "Ctrl", key = "Rueda abajo", spell = "Magma Totem", cat = "totem", icon = "Interface\\Icons\\spell_fire_selfdestruct", note = "fuego (nombre en inglés)" },
    { layer = "", key = "Mouse3", spell = "Llamada de los elementos", cat = "totem", icon = "Interface\\Icons\\spell_shaman_dropall_01", note = "clic de la rueda: baja tu juego de tótems" },
    { layer = "Shift", key = "Mouse3", spell = "Retirada totémica", cat = "totem", icon = "Interface\\Icons\\spell_shaman_totemrecall", note = "levanta los tótems" },
  },
}
