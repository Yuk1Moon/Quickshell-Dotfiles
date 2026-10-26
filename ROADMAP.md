# Roadmap del shell

Estado actual del bar: app launcher, workspaces, now playing, apps abiertas, reloj, bandeja del sistema, red, brillo, volumen, batería, campana de notificaciones.
Notificaciones: implementadas pero **sin cerrar** — ver sección abajo.
Patrón: servicio singleton en `services/` → widget con `PillContainer` en `widgets/` → sección en `panels/Bar.qml`.
Popups: `PopupContainer`/`PopupWindow`, ver `widgets/appLauncher/AppLauncher.qml` como referencia.

## Widgets de bar

- [x] **Volumen** — `Quickshell.Services.Pipewire`. Scroll = subir/bajar, click = mute. Nivel con `RingIndicator`.
- [x] **Brillo** — sysfs + eventos udev (sin polling), escribe vía `brightnessctl`. Scroll = subir/bajar.
- [x] **Apps abiertas** — 5 slots fijos, una app por slot (ventanas agrupadas por `appId`), orden por recencia. Click = su ventana si tiene una sola; si tiene varias, una lista para elegir cuál (`widgets/windows/WindowsMenu.qml`). Click derecho = la lista siempre.
- [ ] **Bluetooth** en la barra de arriba (widget) — la barra lateral ya tiene botón y pestaña de dispositivos.
- [ ] **CPU/RAM/temperatura** — `Process` + `Timer` leyendo `/proc/stat` y `/proc/meminfo` (igual que `nmcli` en `Network.qml`).
- [x] **Bandeja del sistema** — `Quickshell.Services.SystemTray` (`widgets/TrayWidget.qml`), antes de la red; se oculta sin apps. Click = abrir la app, click derecho = su menú con el estilo del menú de energía (`widgets/tray/`), click medio = acción secundaria.
- [ ] Probar la bandeja con una app real (Steam) y clicks reales: solo se probó con apps falsas y llamando al menú directo.
- [x] **Now playing** — `services/Media.qml` (MPRIS) + `widgets/MediaWidget.qml`, después de los workspaces: carátula, título · artista, ⏮ ⏯ ⏭. Se oculta sin reproductor.
- [ ] Probar now playing con un reproductor real (Brave, Spotify) y clicks reales: se probó con un reproductor falso en un bus privado.
- [ ] **Indicador de teclado** — si usas más de un layout en Hyprland.

### Pulido de widgets existentes

- [ ] `BrightnessWidget` sin ícono: al lado de `VolumeWidget` son dos anillos con porcentaje difíciles de distinguir. Un `Text` con `brightness_6` de Material Symbols lo resuelve.
- [x] Tooltips en todos los widgets de la barra (`components/Tooltip.qml`), con el estilo de los toasts.
- [x] Tooltips en la barra lateral: botones rápidos, apagado, pestañas y botones del calendario (`below` en `Tooltip`).
- [x] `WindowsWidget` agrupa por app: dos kitty = un slot con dos puntos debajo del ícono (`Windows.apps`).
- [ ] Probar la lista de ventanas con clicks reales: abrirla, elegir una fila, Esc y click afuera (se probó con clicks y foco simulados en una copia).
- [ ] Scroll del brillo es lineal y las media keys de Hyprland usan `-e4` (exponencial): mismo "5%" mueve distinto. Revisable.

## Popups

- [x] **OSD** de volumen, micrófono y brillo (`panels/Osd.qml`). Solo responde a las teclas, no a los controles de la shell.
- [x] **Toasts de advertencia** (`Notifications.warn()`): notificaciones de la propia shell, con símbolo de Material. Por ahora, batería al 20% y al 10% (crítica); se van al enchufar.
- [ ] Probar los avisos de batería con una descarga real (se probaron con el nivel simulado en una copia).
- [ ] Más avisos con `Notifications.warn()`: disco lleno, temperatura... (ideas, nada pedido todavía).
- [x] OSD de multimedia: las teclas multimedia van por `qs ipc call media ...` (sin `playerctl`) y muestran qué suena.
- [x] **Menú de energía** — desplegable bajo el botón de apagado de la barra lateral (suspend, log out, reboot, shut down; lock si hay bloqueador).
- [x] **Calendario** — en el popup de abajo de la barra lateral (`widgets/calendar/MonthCalendar.qml`). Revisable: que el click en `ClockWidget` abra la barra lateral.
- [x] **Quick settings** — botones de wifi/bluetooth/volumen/brillo/no molestar en la barra lateral.

## Centro de configuración (barra lateral)

- [x] Dos popups separados (arriba grande, abajo chico), alineados a los gaps de Hyprland.
- [x] Popup de arriba: hora + botón de apagado, y el cuadro de notificaciones debajo.
- [x] Botones rápidos: wifi, bluetooth, volumen (mute), brillo (atenuar). Círculos con aro dentro de una barrita.
- [x] BlueZ instalado y `bluetooth.service` habilitado (2026-09-24). El botón necesita un reinicio de `qs` la primera vez.
- [ ] Probar el botón de wifi con un click real (no se probó: apagarlo corta la sesión de prueba).
- [ ] El ícono `brightness_low` (brillo atenuado) se parece a un engranaje — revisable.
- [x] `PowerButton` abre el menú de energía.
- [ ] Bloqueo de pantalla: no hay bloqueador instalado. Instalar `hyprlock` (aparece solo en el menú) o hacer uno propio con `WlSessionLock` + `Quickshell.Services.Pam`.
- [x] Popup de abajo: calendario del mes.
- [x] Estilo tipo end-4: `IconButton` redondos, tarjetas de notificación con hora y expandir, pie con contador, calendario con píldora.
- [x] Toasts con el mismo estilo que el historial (`NotificationContent` compartido).
- [x] App launcher con el mismo estilo (panel, buscador en píldora, tarjetas, selección con anillo), más teclado: ↑↓, Enter, Esc.
- [x] Atajo: SUPER+R abre el launcher de la shell (`qs ipc call launcher toggle`), en lugar de `hyprlauncher`.
- [x] Pestaña de Wi-Fi junto a "Notifications": lista de redes, conectar (con contraseña), desconectar, olvidar.
- [ ] Probar con uso real: conectar a una red nueva con contraseña, contraseña incorrecta, desconectar y olvidar.
- [x] Pestaña de Bluetooth junto a Wi-Fi: dispositivos cercanos, emparejar + conectar, desconectar, olvidar.
- [ ] Probar Bluetooth con un dispositivo real (emparejar, conectar, batería).
- [ ] Agente de emparejamiento para dispositivos que piden PIN o confirmación (hoy solo "Just Works").
- [ ] Llenar los `EmptySlot` (círculos vacíos que guardan lugar): 2 en el encabezado, 2 en la barrita de botones, 1 pestaña junto a notificaciones/Wi-Fi/Bluetooth, 1 vista en el riel del calendario.
- [x] No molestar: círculo en la barrita de botones; solo las críticas muestran toast. Se guarda en disco; `qs ipc call dnd toggle`.
- [ ] Renombrar `NotificationCenter` / `Notifications.centerOpen` cuando deje de ser solo de notificaciones.
- [x] Toasts alineados con la barra lateral (debajo de la barra, a `Theme.margins` del borde); se ocultan con la barra lateral abierta.

## Notificaciones — pendiente de cerrar

Código escrito y funcionando en las pruebas, pero **no dado por terminado**.
Archivos: `services/Notifications.qml`, `panels/NotificationPopups.qml`,
`panels/NotificationCenter.qml`, `widgets/NotificationCenterButton.qml`,
`widgets/notifications/`. Historial completo de bugs en `CHANGELOG.md`.

Verificación con click humano:

- [x] Historial: cerrar (x) de cada entrada, "Limpiar" y abrir/cerrar con la campana — confirmado por el usuario (2026-09-24).
- [ ] Botón de cerrar (x) del toast.
- [ ] Botones de acción de los toasts (los que manda la app, tipo "Responder").

Mejoras pendientes:

- [x] Hit-target del ícono de cerrar — `IconButton` de 24x24 en toasts e historial.
- [x] Fallback de ícono: símbolo `notifications`/`priority_high` en vez de `dialog-information`
      (que no existe en el tema), en toasts e historial.
- [x] `notification.image`: una foto llena la insignia redonda; un ícono (`image://icon/...`) se usa como ícono. Sin probar con `image-data` crudo.
- [x] Respuesta rápida (`sendInlineReply`): botón "Reply" y campo en píldora, en toasts e historial.
- [x] Acciones en el historial: la notificación queda abierta cuando se va el toast, así que sus botones siguen funcionando.
- [x] Historial guardado en disco (`Quickshell.statePath("notifications.json")`): sobrevive recargas y reinicios.
- [x] Historial con referencias muertas (`null` a los 5s): ahora guarda copias planas, no los objetos. Ver `CHANGELOG.md`.
- [x] Atajo: SUPER+N (`qs ipc call sidebar toggle`).

## Pulido / arquitectura

- [x] `config/Settings.qml` para valores no-tema, separado de `Theme.qml`.
- [x] Binding loop de `implicitWidth` en `components/BarContainer.qml` — arreglado 2026-09-24, ver `CHANGELOG.md`.
- [ ] Borrar o archivar `Draft/` (código muerto, no se usa desde `shell.qml`).
- [ ] Ampliar `Settings.qml` con flags de qué widgets mostrar por sección (hoy siguen hardcodeados en `panels/Bar.qml`).
- [ ] Sin forma de simular clicks/scroll para probar (`ydotool`/`wtype`/`dotool` no instalados) — todo se prueba llamando al servicio directo.
      Capturas sí se pueden: `grim -g "x,y wxh" archivo.png` anda sin sudo.
