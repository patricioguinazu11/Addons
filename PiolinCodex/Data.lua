-- Códice de Piolin: contenido de la guía
local ADDON, NS = ...

local G = "|cffd9a93f"   -- dorado
local H = "|cfff3cf6b"   -- dorado claro
local B = "|cff69ccf0"   -- azul (coordenadas, niveles)
local M = "|cffc0c0c0"   -- plata (precios)
local E = "|r"

NS.colors = { G = G, H = H, B = B, M = M, E = E }

-- Cada pestaña: key, label (botón), icon, lead, sections = { { h = título, icon = textura, items = { { id = "x", t = "texto" } | { t = "texto" } } } }
-- Los ítems con id se pueden tildar y se guardan en tu cuenta.
NS.TABS = {
  {
    key = "personaje", label = "Personaje", icon = "Interface\\Icons\\INV_Misc_Head_Dwarf_01",
    lead = "Datos en vivo de tu personaje y lo que te toca ahora.",
    live = "char",
    sections = {
      { h = "Talentos (guía NickTew)", icon = "Interface\\Icons\\Spell_Nature_LightningShield", items = {
        { t = "Golpes de trueno 5/5 · Maña mental 3/3 · Conocimiento ancestral 2/5 · Enfoque chamánico 1/1" },
        { id = "t21", t = "21-23: Armas elementales 3/3" },
        { id = "t24", t = "24: Anticipación 1/3" },
        { id = "t25", t = H .. "25: Golpe de tormenta" .. E .. " (tu gran salto)" },
        { id = "t26", t = "26-27: Lobo fantasmal mejorado 2/2" },
        { id = "t28", t = "28-29: Ráfaga 2/5" },
        { t = "Nunca tomes Escudo de agua temprano: retrasa Golpe de tormenta." },
      }},
      { h = "Espacios vacíos", icon = "Interface\\Icons\\INV_Helmet_04", items = {
        { id = "eq1", t = "Cabeza: capucha del Camorrista (Peletería 100, Daniel Hilvanante)" },
        { id = "eq2", t = "Cuello: Gargantilla efímera (Sala de los Thanes) o un collar \"del oso/tigre\" de la subasta" },
        { id = "eq3", t = "Segundo anillo y abalorios: subasta o recompensas de misión" },
      }},
    },
  },
  {
    key = "misiones", label = "Misiones", icon = "Interface\\Icons\\INV_Misc_Note_01",
    lead = "Lo próximo: Minas de la Muerte con todas sus misiones, entrenar y compras.",
    sections = {
      { h = "Minas de la Muerte (Villa Luna, 17-26)", icon = "Interface\\Icons\\INV_Misc_Bandana_03", items = {
        { id = "dm1", t = "Juntar afuera 4 tarjetas del Sindicato Minero (Recolección de recuerdos)" },
        { id = "dm2", t = "Recuperar afuera el distintivo de Cardortiga (Oh, hermano...)" },
        { id = "dm3", t = "Adentro: pieza de la trituradora de Sneed (Asalto subterráneo)" },
        { id = "dm4", t = "Pañuelos de seda roja (Exploradora Riell, torre de Colina del Centinela)" },
        { id = "dm5", t = "Destrucción en Minas de la Muerte (Alba Fairmoon)" },
        { id = "dm6", t = "Hablar con Wiley en la posada de Villa del Lago y volver a Gryan" },
        { id = "dm7", t = "Matar a Edwin VanCleef y llevar su cabeza a Gryan: elegir la " .. H .. "Túnica de Páramos de Poniente" .. E },
        { id = "dm8", t = "Pedir necesidad por el " .. H .. "Martillo poderoso de Smite" .. E .. " (Mr. Smite)" },
        { id = "dm9", t = "Entregar La carta sin enviar a Baros Alexston (Ventormenta)" },
      }},
      { h = "Entrenar (Forjaz o Kharanos)", icon = "Interface\\Icons\\Spell_Nature_SpiritWolf", items = {
        { id = "tr1", t = "Lobo fantasmal, Choque de escarcha, Ola de sanación inferior" },
        { id = "tr2", t = "Llamada de los elementos y Retirada totémica" },
        { id = "tr3", t = "Rango nuevo de Arma Lengua de fuego" },
        { id = "tr4", t = "Misión de Agua: Norric Lochthane, Loch Modan " .. B .. "(41.9, 19.0)" .. E },
      }},
      { h = "Subasta (unos 2,2 de oro)", icon = "Interface\\Icons\\INV_Misc_Coin_01", items = {
        { id = "ah1", t = "Pesca experta: la lubina y tú " .. M .. "1 oro 5 pl" .. E },
        { id = "ah2", t = "Libro de cocina para expertos " .. M .. "96 pl" .. E },
        { id = "ah3", t = "6 abalorios relucientes (+75 pesca) " .. M .. "2,77 pl c/u" .. E },
        { id = "ah4", t = "Bolsa de lana verde, 10 espacios " .. M .. "19 pl" .. E },
      }},
      { h = "Tres Esquinas (Crestagrana)", icon = "Interface\\Icons\\INV_Crate_01", items = {
        { id = "tc1", t = "Llenar el Cajón arrebatado (20 cueros ligeros) y entregarlo a Marcy Baker " .. B .. "(9.6, 71.0)" .. E },
        { id = "tc2", t = "Comprar a Daniel Hilvanante el cinturón o los guantes del Camorrista (30 Favor)" },
      }},
    },
  },
  {
    key = "ruta", label = "Ruta", icon = "Interface\\Icons\\INV_Misc_Map_01",
    lead = "Ruta del 20 al 60. Andá con gente de tu nivel: más de 12 niveles de diferencia y no da experiencia.",
    sections = {
      { h = "20-30 · Golpe de tormenta", icon = "Interface\\Icons\\Ability_Shaman_Stormstrike", items = {
        { id = "r20a", t = "Zonas: Montañas Crestagrana, Bosque del Ocaso, Vallefresno" },
        { id = "r20b", t = "Mazmorras: Mazmorras de Ventormenta, Excavación: Los Humedales, Cavernas de Brazanegra, Castillo de Colmillo Oscuro" },
        { id = "r20c", t = "Armas: Heavehammer " .. B .. "(26-30)" .. E .. ", Defensor de Dalaran " .. B .. "(28-32)" .. E },
        { id = "r20d", t = "Primer punto de legado " .. B .. "(25)" .. E },
      }},
      { h = "30-40 · Viento furioso y montura", icon = "Interface\\Icons\\Spell_Nature_Cyclone", items = {
        { id = "r30a", t = "Zonas: Los Humedales, Tierras Altas de Arathi, Vega de Tuercespina, Las Mil Agujas" },
        { id = "r30b", t = "30: Arma Viento furioso, Regreso astral, Tótem derribador; misión de Aire en Arathi " .. B .. "(59.8, 27.6)" .. E },
        { id = "r30c", t = "32: Cadena de relámpagos y Tótem Viento furioso" },
        { id = "r30d", t = "Gnomeregan: " .. H .. "Manual Crowd Pummeler" .. E .. ", la mejor arma incluso al 60 " .. B .. "(30)" .. E },
        { id = "r30e", t = "Dalaran, Horado Rajacieno (Corpsemaker), Monasterio Escarlata (Ravager, Bonebiter)" },
        { id = "r30f", t = "Talentos: Golpe de tormenta mejorado 2/2, Armas de espíritu, Ráfaga 4/5, Arma vórtice 1/5" },
        { id = "r30g", t = "40: Equitación (100 oro) y el oso del pack; malla; doble especialización" },
      }},
      { h = "40-50 · Vórtice", icon = "Interface\\Icons\\Spell_Fire_FlameShock", items = {
        { id = "r40a", t = "Zonas: sur de Vega de Tuercespina, Tanaris, Feralas, Tierras del Interior" },
        { id = "r40b", t = "Fortaleza Krol'dok: " .. H .. "Bigger Rock on Bigger Stick" .. E .. " (te dura hasta el 60)" },
        { id = "r40c", t = "Uldaman, Zul'Farrak, Prisión de Alcaz, Maraudon" },
        { id = "r40d", t = "Talentos: Enfoque de las mareas 5/5, Conciencia plena 3/3, Enfoque totémico 2/5, Escudo de agua" },
      }},
      { h = "50-60 · El final", icon = "Interface\\Icons\\INV_Hammer_09", items = {
        { id = "r50a", t = "Zonas: Tanaris, Tierras Ardientes, Un'Goro, Frondavil, Estepas Ardientes, Cuna del Invierno, Tierras de la Peste" },
        { id = "r50b", t = "Templo Sumergido, Profundidades de Roca Negra y las de 60" },
        { id = "r50c", t = "Talentos: Arma vórtice 3/5, Presteza mental 2/2, " .. H .. "Ira del Clarividente" .. E .. ", Ráfaga 5/5, Concusión 5/5" },
        { id = "r50d", t = "Armas: Beastslayer " .. B .. "(50-55)" .. E .. ", Bonecrusher " .. B .. "(58-60)" .. E },
        { id = "r50e", t = "60: Equitación de oficial (1000 oro) y tu Garrazul cerúleo" },
      }},
    },
  },
  {
    key = "pesca", label = "Pesca", icon = "Interface\\Icons\\Trade_Fishing",
    lead = "Pesca + Cocina juntas (guía Wow-Professions adaptada): todo lo que pescás se cocina.",
    live = "fish",
    sections = {
      { h = "1 · Desbloquear expertos", icon = "Interface\\Icons\\INV_Misc_Book_09", items = {
        { id = "f1a", t = "Leer Pesca experta: la lubina y tú (subasta). Pide nivel 20 y Pesca 125." },
        { id = "f1b", t = "Leer el Libro de cocina para expertos (subasta). Sin él, Cocina se traba en 150." },
      }},
      { h = "2 · Pesca 150-205, Cocina 125-175", icon = "Interface\\Icons\\INV_Misc_Fish_06", items = {
        { id = "f2a", t = "Receta de siluro bigotudo con Catherine Leland (Ventormenta)" },
        { id = "f2b", t = "Pescar siluro bigotudo en el lago de Villa del Lago o el lago Mystral (Vallefresno)" },
        { id = "f2c", t = "Usar abalorios relucientes (+75), uno cada 10 minutos" },
        { id = "f2d", t = "Cocinar todo el siluro hasta Cocina 175" },
      }},
      { h = "3 · Pesca 205-225", icon = "Interface\\Icons\\INV_Fishingpole_02", items = {
        { id = "f3a", t = "Seguir en Vallefresno o pasar al Marjal Revolcafango" },
      }},
      { h = "4 · Artesano (nivel 35)", icon = "Interface\\Icons\\INV_Misc_Fish_14", items = {
        { id = "f4a", t = "Misión Nat Pagle, pescador extremo (Marjal Revolcafango)" },
        { id = "f4b", t = "Pez de la costa oeste de Vega de Tuercespina" },
        { id = "f4c", t = "Pez de la costa de Desolace" },
        { id = "f4d", t = "Pez de la costa este del Pantano de las Penas" },
        { id = "f4e", t = "Pez del río Verdantis (Feralas)" },
      }},
      { h = "5 · Pesca 225-300", icon = "Interface\\Icons\\INV_Misc_Fish_21", items = {
        { id = "f5a", t = "Feralas, Tanaris, Un'Goro o Tierras de la Peste, con abalorios relucientes" },
        { t = "Extra: el Pargo de barro mandíbula larga cocinado da +10 poder de ataque y +5% de experiencia." },
      }},
    },
  },
  {
    key = "oficios", label = "Oficios", icon = "Interface\\Icons\\Trade_LeatherWorking",
    lead = "Peletería por tramos. Recetas con Fimble Finespindle (Forjaz) o Simon Tanner (Ventormenta).",
    live = "mats",
    sections = {
      { h = "Peletería por tramos", icon = "Interface\\Icons\\INV_Misc_LeatherScrap_02", items = {
        { id = "lw1", t = "80-90: Piel media curada x10 (10 pieles medias, 10 sal). Guardarlas." },
        { id = "lw2", t = "90-100: Cinturón de cuero fino x19 (114 cueros ligeros, 38 hilos burdos). Guardar 10." },
        { id = "lw3", t = "100-115: Pantalones de cuero ligero x24 (240 cueros ligeros, 24 pieles ligeras curadas, 24 hilos finos)" },
        { id = "lw4", t = "115-125: Cinturón de cuero oscuro x10 (10 cinturones finos, 10 pieles medias curadas, 20 hilos finos, 10 tintes grises)" },
        { id = "lw5", t = "Antes de pasar 125: rango Experto con Telonis (Darnassus)" },
        { id = "lw6", t = "125-130: Cuero pesado x7 (35 cueros medios)" },
        { id = "lw7", t = "130-143: Piel pesada curada x30 (30 pieles pesadas, 90 sal). Guardarlas." },
        { id = "lw8", t = "143-155: Guantes de cuero de montañés x17 (238 cueros medios, 68 hilos finos)" },
      }},
      { h = "Pendientes", icon = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01", items = {
        { id = "lp1", t = "Peletería 125: plano del Bastidor de curtir (9 oro en la subasta)" },
        { id = "lp2", t = "Desollar 125: rango Experto (Maris Granger en Ventormenta o Jayla en Vallefresno)" },
        { id = "lp3", t = "Desollar 140: plano de la Guía de campo (1 oro), enseña Rastrear bestias" },
        { id = "lp4", t = "Primeros auxilios: vendas con tela de lino y lana" },
        { t = "Vendé pieles curadas y cuero sobrante en la subasta, no al comerciante." },
      }},
    },
  },
  {
    key = "combate", label = "Combate", icon = "Interface\\Icons\\Spell_Nature_EarthShock",
    lead = "Fuerza primero y arma lenta a dos manos. Solo, el único tótem que vale el maná es el Abrasador.",
    macros = true,
    sections = {
      { h = "Rotación 20-24", icon = "Interface\\Icons\\Spell_Fire_SearingTotem", items = {
        { t = "1. Escudo de relámpagos antes de pelear" },
        { t = "2. Choque de llamas para abrir" },
        { t = "3. Tótem abrasador antes de que llegue el enemigo" },
        { t = "4. Nova de fuego con 3 o más enemigos" },
        { t = "5. Choque de tierra cuando esté listo, o para interrumpir" },
        { t = "Desde el 25: Golpe de tormenta siempre que esté listo; Descarga de relámpagos con 5 cargas de Arma vórtice." },
      }},
    },
  },
  {
    key = "campamento", label = "Campamento", icon = "Interface\\Icons\\Spell_Fire_Fire",
    lead = "Hoguera básica + tienda de campaña cada hora; juntá oro para la Equitación del 40.",
    live = "camp",
    sections = {
      { h = "Monturas", icon = "Interface\\Icons\\Ability_Mount_MountainRam", items = {
        { id = "mt1", t = "Nivel 40: Equitación por 100 de oro y el oso del pack" },
        { id = "mt2", t = "Nivel 60: Equitación de oficial por 1000 de oro y tu Garrazul cerúleo" },
      }},
    },
  },
  {
    key = "teclas", label = "Teclas", icon = "Interface\\Icons\\INV_Misc_Note_02",
    lead = "Propuesta de teclas para Mejora en Forever, armada con el criterio de jugadores reales. Solo para mirar: no cambia tus barras.",
    keys = true,
    sections = {},
  },
  {
    key = "pantalla", label = "Pantalla", icon = "Interface\\Icons\\INV_Misc_Spyglass_03",
    lead = "Diseños del Modo edición que compartieron jugadores de Forever. Mirá cómo acomodan la pantalla y, si te gusta uno, copiá su texto e importalo vos desde el juego.",
    layouts = true,
    sections = {},
  },
  {
    key = "notas", label = "Notas", icon = "Interface\\Icons\\INV_Misc_Book_11",
    lead = "Escribí lo que quieras: se guarda solo en tu cuenta.",
    notes = true,
    sections = {},
  },
}

-- Macros que el botón crea (por personaje). Nombres de hasta 16 caracteres, sin tildes.
NS.MACROS = {
  { name = "PC Preparacion", body = "#showtooltip\n/castsequence reset=60 Escudo de relámpagos, Arma Lengua de fuego" },
  { name = "PC Llamas",      body = "#showtooltip\n/startattack\n/cast [@mouseover,harm,nodead][] Choque de llamas" },
  { name = "PC Interrumpir", body = "#showtooltip\n/stopcasting\n/cast [@mouseover,harm,nodead][] Choque de tierra" },
  { name = "PC Curacion",    body = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] Ola de sanación inferior" },
  { name = "PC Tormenta",    body = "#showtooltip Golpe de tormenta\n/startattack\n/cast Golpe de tormenta" },
}

-- Consejo según tu nivel actual
NS.HINTS = {
  { max = 19, t = "Llegá al 20 en Crestagrana y entrená Lobo fantasmal." },
  { max = 24, t = "Minas de la Muerte, Armas elementales y juntar para el 25." },
  { max = 29, t = "Golpe de tormenta y Lobo fantasmal mejorado. Heavehammer en Los Humedales." },
  { max = 39, t = "Viento furioso en el 30, Gnomeregan por el Manual Crowd Pummeler, y oro para la montura." },
  { max = 49, t = "Krol'dok por el Bigger Rock on Bigger Stick." },
  { max = 60, t = "Ira del Clarividente y a terminar el 60." },
}
