# Cambios

## 5.0.0: rediseño

El Códice pasa a verse y comportarse como un addon de los más usados: menos pantalla, todo en su lugar y lo importante a la vista.

### Diseño
- **Sistema de diseño**: grises, un azul para acciones y progreso, un dorado para "lo que importa ahora". Verde y rojo solo para estados (listo o falta). Antes había unos 10 colores de acento.
- **Letra en 5 tamaños** (18, 13, 12, 10,5 y 9). Antes había 19 tamaños distintos.
- Etiquetas de tareas en gris; el color queda para el estado ("entregar", "en registro").
- Opción de usar la letra del juego o una de LibSharedMedia, para convivir con ElvUI.

### Ventana
- **De 10 pestañas a 6**: Hoy, Guía, Oficios, Combate, Interfaz y Notas.
  - Guía junta Misiones y Ruta 20-60.
  - Oficios junta Peletería, Desuello, Pesca, Cocina y Campamento.
  - Combate junta rotación, equipo, talentos, macros y teclas.
- **Portada "Hoy"**: nivel, oro y talentos; las tres próximas tareas de la guía (se tildan con un clic, con estado y botón "Ir"); y lo del próximo nivel y el instructor.
- Ventana más chica (740×530), con **escala** configurable y botón ≡ de configuración en la cabecera.

### HUD de combate
- Reemplaza a la barra de tótems y al cartel grande de "te falta": **escudo, imbuición y los cuatro tótems** en un solo marco.
- Lo que falta se marca en rojo; al seleccionar un enemigo parpadea y suena en lugar de tapar el centro de la pantalla.
- Siempre, solo en combate u oculto; atenuado cuando no hay nada que mirar. Escala propia. `/piolin hud`.

### Tooltip
- Un solo bloque "CÓDICE" en vez de hasta tres: precio y conveniencia en una línea, tramo de Peletería y cuánto tenés en otra, comparación de equipo en otra. El detalle, con Shift.

### Configuración
- **Siete secciones** (General, Combate, Misiones y mapa, Comercio, Oficios y pesca, Sonido y Perfil), descripciones cortas y **Restablecer** por sección y general.
- **Bloquear marcos**: el HUD, el mini estado, la flecha y el cartel de nivel se mueven solo con los marcos destrabados.
- `/piolin config` y el botón ≡ abren la configuración.

### Preferencias
- **Por personaje** (`PiolinCodexCharDB`). La primera vez se copian solas las tildes, notas y opciones que tenías.
- Los **precios** de la subasta quedan en la cuenta y se comparten entre personajes.
- **Perfil**: copiar las preferencias de otro personaje.

### Idiomas
- Interfaz en **español e inglés** (en un cliente que no está en español sale en inglés). La guía sigue solo en español.

### Rendimiento y código
- El motor de animaciones ya no corre en cada cuadro cuando no hay animaciones.
- Los eventos de unidad (inventario, hechizos, auras) se escuchan solo para el jugador: en grupo o banda ya no se disparan por cada compañero.
- `BAG_UPDATE` pasa a `BAG_UPDATE_DELAYED`.
- El latido del botón del minimapa ya no crea una tabla por cuadro.
- Se borraron unas 380 líneas de una ventana vieja que ya no se usaba.

### Quitado
- La barra de tótems sola (ahora es parte del HUD) y el cartel grande de "te falta" mientras el HUD está prendido.
- En la configuración: "Probar un aviso" y "Quitar la flecha" (siguen en `/piolin probar` y en el clic derecho de la flecha). "Borrar todas las tildes" pasa a Perfil.

## 4.5.0
- Pescar con doble clic derecho.

## 4.4.0
- Temporizadores de tótems, tooltip "Para Peletería" y revisión de la ventana.
