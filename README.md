# Códice de Piolin

Addon personal de guía para **Piolin Jijolin** (Enano Chamán Mejora, Alianza, WoW Forever, reino Normal US).
Misiones, ruta 20-60, profesiones, macros, avisos antes de pelear, ayudante de subasta e instructores. Se abre con `/piolin`.

La pestaña **Pantalla** muestra diseños del Modo edición que compartieron jugadores de Forever (Zilbur Whillbur, Stereo, papi, Luxthos y uno sin nombre, de wowforeverui.com, wow4ever.quest y wago.io) y el Administrador de reutilización de chamán Mejora de Luxthos. Los textos son de sus autores; el addon los muestra con su nombre y no los aplica solo: se importan desde el juego.

Al subir de nivel aparece un cartel con lo que subió (vida, maná, estadísticas y talento) y lo nuevo en el instructor, con la sugerencia de qué comprar para Mejora. La lista de hechizos por nivel de Forever sale de Conquest Capped. Se prueba con `/piolin nivel 20`.

Si tenés [Questie](https://github.com/Questie/Questie) instalado, el Códice usa su base de datos para las flechas: las misiones de la guía tienen botón "Ir" (a quien la da, al objetivo que falta o a quien la entrega) y la pestaña Misiones lleva a la entrega o al objetivo más cercano. Sin Questie, todo funciona igual.

Versión actual: **4.3.0**.

## Contenido

- `PiolinCodex/`: la carpeta del addon tal cual va en `Interface/AddOns/`.
- `harness/`: pruebas que cargan el addon en un Lua simulado.

## Instalar

- **WowUp**: *Get Addons → Install from URL* con la dirección de este repositorio. Toma el zip del último release (`PiolinCodex-<versión>-forever.zip`).
- **A mano**: bajar el zip del release y descomprimirlo en `World of Warcraft/_classic_/Interface/AddOns/` (o la carpeta de AddOns de Forever).

## Pruebas

Requieren Python con `lupa` (`pip install lupa`). Desde `harness/`:

```
python run.py ../PiolinCodex          # simula Classic
python run_retail.py ../PiolinCodex   # simula Forever (motor moderno)
```

## Publicar una versión

1. Subir `## Version:` en `PiolinCodex/PiolinCodex.toc`.
2. Correr las dos pruebas.
3. Armar `PiolinCodex-<versión>-forever.zip` con la carpeta `PiolinCodex/` adentro (WowUp necesita que el nombre termine en `-forever`).
4. Crear el release `v<versión>` en GitHub y adjuntar el zip.
