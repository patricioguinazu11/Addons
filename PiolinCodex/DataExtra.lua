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
