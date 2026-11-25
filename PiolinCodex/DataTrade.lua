-- Códice de Piolin: datos de oficios, precios y venta
local ADDON, NS = ...

-- Materiales que el botón "Escanear" busca en la casa de subastas
-- { itemID, nombre de respaldo }
NS.SCAN_ITEMS = {
  { 2318, "Cuero ligero" }, { 2319, "Cuero medio" }, { 4234, "Cuero pesado" }, { 4304, "Cuero grueso" },
  { 783, "Pellejo ligero" }, { 4232, "Pellejo medio" }, { 4235, "Pellejo pesado" }, { 8169, "Pellejo grueso" },
  { 2934, "Restos de cuero estropeado" },
  { 4231, "Pellejo ligero curado" }, { 4233, "Pellejo medio curado" }, { 4236, "Pellejo pesado curado" },
  { 4246, "Cinturón de cuero fino" },
  { 2321, "Hilo fino" }, { 4340, "Tinte gris" }, { 4289, "Sal" },
  { 6532, "Abalorios relucientes" },
  { 6308, "Siluro bigotudo crudo" }, { 6289, "Pargo de barro mandíbula larga crudo" },
  { 6317, "Frenesí del lago crudo" }, { 6358, "Boca negra aceitosa" }, { 6359, "Pargo aleta de fuego" },
  { 6361, "Albacora aleta de arco iris cruda" }, { 6362, "Bacalao escama de roca crudo" },
  { 6522, "Pez desviado" }, { 8365, "Trucha cabeza de mitril cruda" },
  { 2589, "Paño de lino" }, { 2592, "Paño de lana" }, { 4306, "Paño de seda" },
}

-- Materiales que venden los vendedores de oficios (para la lista de compras)
NS.VENDOR_MATS = { [2320] = true, [2321] = true, [4340] = true, [4289] = true, [4291] = true, [6529] = true, [6532] = true }

-- Zonas para desollar según la habilidad
NS.SKIN_ZONES = {
  { max = 75,  t = "Dun Morogh, Loch Modan o Bosque de Elwynn" },
  { max = 150, t = "Los Humedales, Montañas Crestagrana o Páramos de Poniente" },
  { max = 225, t = "Tierras Altas de Arathi, Vega de Tuercespina, Tierras Inhóspitas o Laderas de Trabalomas" },
  { max = 300, t = "Feralas, Tanaris, Cráter de Un'Goro o Cuna del Invierno" },
}

-- Aviso al acercarte al tope de un oficio: [profesión][tope] = qué hacer
NS.CAP_TIPS = {
  ["Pesca"] = {
    [150] = "Comprá Pesca experta: la lubina y tú en la subasta (o al Viejo Heming en Bahía del Botín).",
    [225] = "Misión de artesano con Nat Pagle en el Marjal Revolcafango (nivel 35).",
  },
  ["Cocina"] = {
    [150] = "Comprá el Libro de cocina para expertos en la subasta.",
    [225] = "Artesano de cocina con Dirge Quikcleave en Gadgetzan (nivel 35).",
  },
  ["Peletería"] = {
    [150] = "Entrená Peletería experta con el instructor de Forjaz (pide nivel 20).",
    [225] = "Artesano con Drakk Stonehand en Nido Aquilino, Tierras del Interior (nivel 35).",
  },
  ["Desuello"] = {
    [150] = "Entrená Desuello experto con un instructor de desuello.",
    [225] = "Entrená Desuello artesano con un instructor de desuello (nivel 35).",
  },
  ["Primeros auxilios"] = {
    [150] = "Comprá el manual de Primeros auxilios expertos a Deneb Walker (Stromgarde, Arathi).",
    [225] = "Misión Triaje en Theramore con Doctor Gustaf VanHowzen (nivel 35).",
  },
}

-- Precios de wowauctions.net (Normal US, Alianza) tomados el 24/11/2026:
-- [itemID] = { compra ya más barata, mediana de 30 días, cantidad publicada } en cobre
NS.SEED_DATE = "24/11"
NS.SEED_TIME = 1795537800
NS.SEED_PRICES = {
  [783] = { 79, 172, 1330 },
  [2318] = { 36, 36, 13993 },
  [2319] = { 98, 98, 6904 },
  [2320] = { 13, 14, 5953 },
  [2321] = { 102, 108, 2567 },
  [2589] = { 25, 28, 20559 },
  [2592] = { 140, 133, 8479 },
  [2934] = { 11, 13, 5610 },
  [4231] = { 175, 238, 1402 },
  [4232] = { 349, 328, 817 },
  [4233] = { 480, 442, 444 },
  [4234] = { 230, 220, 3705 },
  [4235] = { 894, 1020, 716 },
  [4236] = { 1162, 1214, 368 },
  [4246] = { 309, 256, 208 },
  [4289] = { 51, 63, 3525 },
  [4304] = { 805, 630, 1396 },
  [4306] = { 208, 202, 8231 },
  [4340] = { 325, 392, 623 },
  [6289] = { 3, 4, 10509 },
  [6308] = { 7, 12, 4029 },
  [6317] = { 3, 6, 1731 },
  [6358] = { 49, 49, 8054 },
  [6359] = { 15, 29, 3420 },
  [6361] = { 7, 6, 1831 },
  [6362] = { 5, 8, 4021 },
  [6522] = { 216, 252, 2640 },
  [6529] = { 23, 48, 291 },
  [6532] = { 285, 324, 51 },
  [8169] = { 600, 594, 2716 },
  [8365] = { 73, 88, 2891 },
}
