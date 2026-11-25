# Códice de Piolin

Addon personal de guía para **Piolin Jijolin** (Enano Chamán Mejora, Alianza, WoW Forever, reino Normal US).
Misiones, ruta 20-60, profesiones, macros, avisos antes de pelear, ayudante de subasta e instructores. Se abre con `/piolin`.

Versión actual: **4.0.1**.

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
