# Códice de Piolin

**Guía de Chamán Mejora para WoW Forever.** Abrís el Códice y en 10 segundos sabés qué te toca, cuánto te falta y qué entrenar. En combate, un HUD chico te muestra escudo, imbuición y tótems con su tiempo.

Hecho para **Piolin Jijolin** (Enano Chamán Mejora, Alianza, reino Normal US), pero sirve para cualquier chamán Mejora de Forever. Se abre con `/piolin`.

Versión actual: **5.0.0**.

---

## Qué hace

**Hoy.** La portada: nivel, oro y talentos sin gastar; las tres próximas tareas de la guía (con su estado en el registro de misiones y un botón "Ir"); y lo que viene en el próximo nivel y en el instructor.

**HUD de combate.** Un solo marco con Escudo de relámpagos, imbuición del arma y los cuatro tótems con su tiempo. Lo que falta se marca en rojo, y al seleccionar un enemigo te avisa si te falta algo (con sonido, sin tapar la pantalla). Se puede ver siempre, solo en combate u ocultarlo; se mueve, se escala y se bloquea.

**Guía.** Misiones de Minas de la Muerte, entrenamiento y la ruta del 20 al 60, con casillas que se tildan solas cuando cumplís algo. Con [Questie](https://github.com/Questie/Questie) instalado, las misiones de la guía tienen flecha a quien la da, al objetivo que falta o a quien la entrega.

**Oficios.** Peletería por tramos con lo que te falta comprar, desuello, pesca y cocina. Pescás con doble clic derecho (con la caña equipada y fuera de combate).

**Tooltips.** Un solo bloque "CÓDICE" en cada objeto: precio de subasta contra vendedor, en qué tramo de Peletería lo usás y si es mejora para Mejora. Con Shift, el detalle.

**Combate.** Rotación de un vistazo, tótems, equipo, talentos, macros listas para arrastrar y una propuesta de teclas armada con el criterio de jugadores reales.

**Interfaz.** Diseños del Modo edición que compartieron jugadores de Forever (Zilbur Whillbur, Stereo, papi, Luxthos y uno sin nombre, de wowforeverui.com, wow4ever.quest y wago.io) y el Administrador de reutilización de chamán Mejora de Luxthos. Los textos son de sus autores; el Códice los muestra con su nombre y no los aplica solo: se importan desde el juego.

**Además.** Cartel al subir de nivel (qué subió y qué entrenar; la lista de hechizos por nivel de Forever sale de Conquest Capped), mini estado junto al minimapa (bolsas, durabilidad, piedra de hogar, tienda), venta de basura y reparación automáticas, lista de compras en el vendedor y la subasta, y ayudante para vender.

## Capturas sugeridas

1. La portada **Hoy** con las tres tareas y el próximo nivel.
2. El **HUD de combate** con un tótem por terminar y el escudo en rojo.
3. Un **tooltip** de Cuero ligero (precio y tramo de Peletería).
4. La **configuración**, sección Combate.
5. La pestaña **Guía** con la ruta y la tarjeta "Estás acá".

## Comandos

| Comando | Qué hace |
|---|---|
| `/piolin` | Abre y cierra el Códice (también `/codice` o el botón del minimapa). |
| `/piolin config` | Abre la configuración. |
| `/piolin hud` | Muestra el HUD con datos de ejemplo durante 20 segundos. `/piolin hud centrar` lo devuelve a su lugar. |
| `/piolin nivel 20` | Muestra el cartel de subida de nivel de ese nivel. |
| `/piolin ir 50 50` | Flecha y marca en el mapa hacia esas coordenadas. |
| `/piolin macros` | Crea las macros del Códice. |
| `/piolin instructor [oficio]` | Flecha al instructor más cercano. |
| `/piolin basura [objeto]` | Marca un objeto para venderlo solo. |
| `/piolin ayuda` | Lista todos los comandos. |

## Configuración

En **Opciones › AddOns › Códice de Piolin**, en el botón ≡ de la ventana o con `/piolin config`. Siete secciones (General, Combate, Misiones y mapa, Comercio, Oficios y pesca, Sonido y Perfil), cada opción con una descripción corta, y **Restablecer** por sección o todo junto.

- **Bloquear marcos**: con los marcos destrabados se arrastran el HUD, el mini estado, la flecha y el cartel de nivel. La posición se guarda.
- **Escala** de la ventana y del HUD, y **letra** (Inter, la del juego o una de LibSharedMedia si la tenés por otro addon).
- **Perfil**: las preferencias son de cada personaje y podés copiar las de otro. Los precios de la subasta se comparten entre personajes.

## Idiomas

Español e inglés: en un cliente que no está en español, la interfaz sale en inglés. El contenido de la guía (misiones, rutas y consejos) está solo en español.

## Compatibilidad

- WoW Forever (motor moderno) y WoW Classic.
- Opcionales: **Questie** (flechas a las misiones), **TomTom** (usa su flecha si está), **LibSharedMedia** (más letras).
- No trae librerías propias: el Códice es liviano y no pisa las versiones de Ace3 de otros addons.
- Lo de combate solo muestra información, así que no hay taint. Pescar con doble clic, las macros y las teclas solo se tocan fuera de combate.

## Instalar

- **WowUp**: *Get Addons → Install from URL* con la dirección de este repositorio. Toma el zip del último release (`PiolinCodex-<versión>-forever.zip`).
- **A mano**: bajar el zip del release y descomprimirlo en `World of Warcraft/_forever_/Interface/AddOns/` (o la carpeta de AddOns de tu cliente).

## Para desarrollar

- `PiolinCodex/`: la carpeta del addon tal cual va en `Interface/AddOns/`.
- `harness/`: pruebas que cargan el addon en un Lua simulado. Requieren Python con `lupa` (`pip install lupa`). Desde `harness/`:

```
python run.py ../PiolinCodex          # simula Classic
python run_retail.py ../PiolinCodex   # simula Forever (motor moderno)
```

Para publicar: subir `## Version:` en el toc, correr las dos pruebas, armar `PiolinCodex-<versión>-forever.zip` con la carpeta `PiolinCodex/` adentro (WowUp necesita que el nombre termine en `-forever`) y crear el release `v<versión>` con el zip.

Los cambios de cada versión están en [CHANGELOG.md](CHANGELOG.md).
