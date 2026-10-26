# Changelog

## 2026-10-14 — Now playing, teclas multimedia y su OSD

**Archivos:**
- `services/Media.qml` — nuevo: el reproductor (MPRIS) y sus controles, más un `IpcHandler` con target `media` (`playPause`, `next`, `previous`).
- `widgets/MediaWidget.qml` — nuevo: la píldora de la barra.
- `panels/Bar.qml` — `MediaWidget {}` después de `WorkspacesWidget`.
- `panels/Osd.qml` — tipo `"media"`.
- `components/InfoCard.qml`, `components/Tooltip.qml` — propiedad `picture`: una imagen que llena la insignia redonda (la carátula).
- `config/Settings.qml` — `media.maxWidth` (220).
- `~/.config/hypr/hyprland.lua` — las teclas multimedia llaman a `qs ipc call media ...` en vez de `playerctl`, que no estaba instalado. Copia previa en `hyprland.lua.bak.20261014-164049`.

**Qué reproductor:** el que está sonando. Si ninguno suena, el último que sonó, así pausar no lo cambia por otro. Si nunca sonó ninguno, el primero abierto.

**La píldora** (sección izquierda, después de los workspaces; se oculta sin reproductor):
- **Carátula** en un cuadrito redondeado de 20 px; una nota (`music_note`) si no hay o no carga.
- **"Título · Artista"**, cortado con "…" pasados 220 px. En gris mientras está en pausa.
- **⏮ ⏯ ⏭** con `IconButton`. Se atenúan cuando el reproductor no los permite (por ejemplo, ⏮ en la primera canción).
- **Tooltip** sobre la carátula y el título:
  - la carátula llena la insignia;
  - título, "1:06 / 4:03", artista · álbum;
  - barra de progreso.
- El tiempo se vuelve a pedir cada segundo mientras suena, porque los reproductores solo avisan cuando la posición salta.

**Teclas y OSD:**
- XF86AudioPlay/Pause/Next/Prev pasan por el target `media`. Así funcionan sin `playerctl` y además muestran el OSD: carátula, título, "Playing"/"Paused", artista y progreso.
- Como el resto del OSD, solo responde a las teclas: los botones de la barra no lo muestran.
- Después de next/previous, el reproductor manda la canción nueva un momento más tarde, y la tarjeta se actualiza en el lugar.
- Sin reproductor, las teclas no hacen nada ni muestran el OSD.

**Bug encontrado en la prueba:** en la insignia del tooltip, el ícono ▶ quedaba dibujado encima de la carátula. La imagen va ahora por encima (`z: 1`).

**Verificado** en una copia sobre un bus DBus privado, con un reproductor MPRIS falso (Python + `dbus-next`) que registra cada llamada:
- **Barra:** carátula, "Midnight City · M83", ⏮ atenuado. Sin carátula, la nota. Un título largo, cortado.
- **Tooltip:** el tiempo avanzó de 0:57 a 1:06.
- **Teclas** (`qs ipc call media ...`, lo mismo que corren los binds):
  - el reproductor recibió `Next`, `Pause`, `Play` y `Previous`;
  - en la última canción, `next` no mandó nada;
  - capturas del OSD en "Playing" y en "Paused".
- **Reproductor cerrado:** la píldora desapareció, y una tecla no mostró nada ni dio errores.
- **Instalación en vivo:** Settings, InfoCard, Tooltip, Media, MediaWidget, Osd y Bar, en ese orden. Cada uno recargó sin errores, y `qs ipc show` lista `media`.
- **Hyprland:** `hyprctl configerrors` vacío.

**Sin probar:**
- un reproductor real (Brave, Spotify);
- clicks reales en los botones;
- las teclas físicas.

## 2026-10-12 — SUPER+R abre el launcher de la shell

- `widgets/AppLauncherButton.qml`: `IpcHandler` con target `launcher` (`toggle`, `open`, `close`). Pasa por `launcher.toggle()`, que calcula la posición antes de mostrarlo.
- `~/.config/hypr/hyprland.lua`: `local menu` pasa de `"hyprlauncher"` a `"qs ipc call launcher toggle"`. El bind de SUPER+R (`hl.dsp.exec_cmd(menu)`) no cambió. Copia previa en `hyprland.lua.bak.20261012-120343`.
- **Verificado:**
  - recargó sin errores y `qs ipc show` lista `launcher`;
  - `qs ipc call launcher toggle` lo abrió en su lugar (captura) y `close` lo cerró;
  - `hyprctl configerrors` vacío.
- **Sin probar:** apretar SUPER+R.

## 2026-10-08 — Volumen: ícono en vez de "Muted"

- `widgets/VolumeWidget.qml`: en silencio, la píldora muestra el símbolo `volume_off` (en rojo, como el anillo) en vez del texto "Muted". El tooltip sigue diciendo "Muted".
- La píldora queda más angosta en silencio, así que la red se corre un poco a la derecha.
- **Verificado:** recargó sin errores. Captura de la barra silenciando la salida con `wpctl` y devolviéndola enseguida a como estaba (30%, sin silencio).

## 2026-10-01 — Toasts de advertencia: batería baja

**Archivos:**
- `services/Notifications.qml` — `warn()`, `clearWarning()` y `warningKey()`. El historial guarda `warning` y `symbol`.
- `widgets/notifications/NotificationContent.qml` — la insignia muestra el símbolo que trae el aviso.
- `services/Battery.qml` — cuándo avisar (`warningLevel`, `pluggedIn`, `checkWarnings()`) y `duration()`, que antes estaba en el widget.
- `widgets/BatteryWidget.qml` — usa `Battery.duration()`. El ícono `battery_alert` aparece en `criticalThreshold` en vez de un 10 fijo.
- `config/Settings.qml` — `battery.criticalThreshold` (10).

### Los avisos
- **Batería baja (20%, `lowThreshold`):** toast normal con `battery_2_bar`, "Battery low · 20% · 1 h 30 min left". Se va solo como cualquier toast.
- **Batería muy baja (10%, `criticalThreshold`):** toast crítico con `battery_alert` y la insignia de acento, "Battery very low · 9% · Plug in now". **No se va solo**: queda hasta cerrarlo o enchufar.
- El tiempo restante solo aparece si UPower ya lo calculó.
- **Una vez por descarga:** cada aviso sale una sola vez. Si el nivel sube y baja alrededor del umbral sin cargar, no se repite (la estimación de UPower hace eso).
- **Al enchufar,** el aviso sale del toast y del historial: ya no aplica. Se vuelve a avisar en la próxima descarga.
- El crítico **reemplaza** al de 20%: queda uno solo.
- **No molestar:** el de 20% va directo al historial; el crítico aparece igual.
- Las recargas no repiten el aviso: lo ya avisado se guarda en un `PersistentProperties`. Un reinicio completo con la batería baja sí avisa de nuevo.

### Cómo funciona
- **Notificaciones reales:** `Notifications.warn()` las manda con `notify-send` a la propia shell. Así tienen toast, historial, guardado en disco y paso por encima de no molestar sin código aparte.
- **Dos hints:**
  - `x-quickshell-warning`: la clave del aviso ("battery"), para reemplazarlo o quitarlo (`clearWarning()`);
  - `x-quickshell-symbol`: el símbolo de Material para la insignia, en vez del ícono del tema (breeze-dark), que no combina con la shell.
- El reemplazo se hace cuando el aviso nuevo **llega** al servidor y no cuando se manda: uno todavía en camino se salvaría.
- Sirve para más avisos más adelante: `Notifications.warn(clave, título, texto, símbolo, crítico)`.

### Bugs encontrados en la prueba
- **Aviso viejo después de reiniciar con el cargador puesto:** al arrancar, UPower todavía no está listo y el nivel marca 0 con o sin cargador. Al enchufarse, `warningLevel` no cambiaba y nadie revisaba. Ahora también se revisa cuando cambia `pluggedIn`.
- **Aviso que volvía después de borrarlo:** `restore()` pone `restored = true` y después vuelve a agregar las notificaciones abiertas que vienen de antes de la recarga. Revisar justo en ese momento borraba el aviso y la línea siguiente lo agregaba otra vez. Ahora la revisión se difiere (`Qt.callLater`).
- "Battery critically low" no cabía en el título del toast y se cortaba. Pasó a ser "Battery very low".
- `battery_low` es una batería horizontal; la barra usa verticales. Se cambió a `battery_2_bar`, la que muestra la barra al 20%.

**Verificado** en una copia de la config sobre un bus DBus privado (la copia era el servidor de notificaciones), con el nivel y la carga simulados por un gancho:
- **Bajada:** 25% → nada. 20% → "Battery low". 21% → 20% → no se repite. 9% → "Battery very low", que reemplazó al otro.
- **Cargador:** al enchufar, el aviso salió del toast y del historial. Desenchufar al 9% avisó de nuevo enseguida.
- **No molestar:** el de 20% fue solo al historial; el crítico mostró toast.
- **Recarga** con la batería al 20%: no repitió el aviso, y la entrada siguió enlazada en el historial.
- **Reinicio con el cargador puesto** y un aviso guardado en disco: se borró cuando UPower informó la carga.
- **Capturas:** los dos toasts.
- **Instalación en vivo:** Settings, NotificationContent, Notifications, Battery y BatteryWidget, en ese orden. Cada uno recargó sin errores ni advertencias. El historial real (18 entradas) quedó igual.

**Sin probar:** una descarga real. La batería estaba cargando (41%) durante toda la prueba.

## 2026-10-01 — Apps abiertas: elegir la ventana de una lista

**Archivos:**
- `widgets/windows/WindowsMenu.qml` — nuevo: la lista de ventanas de una app.
- `widgets/WindowsWidget.qml` — los clicks abren la lista; el tooltip usa títulos cortos.
- `services/Windows.qml` — `shortTitle()` nuevo; se quita `focusApp()`.
- `config/Settings.qml` — `windows.menuMinWidth` (200) y `windows.menuMaxWidth` (340).

**Antes:** con varias ventanas de una app, cada click iba a la siguiente. No se podía ir directo a una ventana.

**Ahora:**
- **Click en una app con varias ventanas:** abre una lista debajo del ícono para elegir cuál.
- **Click en una app con una sola ventana:** la enfoca directo, como antes.
- **Click derecho:** abre la lista siempre, también con una sola ventana.
- Se quitó el paso de ventana en ventana con clicks seguidos, porque la lista lo reemplaza.

**La lista:**
- Con el estilo del menú de la bandeja: panel con borde degradado y filas de 36 px. Cuelga debajo de la barra, centrada en el ícono y sin pasarse de los bordes de la barra.
- Cada fila tiene el título de la ventana y, a la derecha, su workspace en un cuadrito como los del widget de workspaces. Los workspaces especiales pierden el prefijo `special:` ("magic").
- La ventana con el foco lleva un punto de acento y el título en peso medio.
- **Orden:** el orden en que se abrieron las ventanas, no la recencia. Por recencia, las filas cambiarían de lugar cada vez que se elige una.
- Esc o un click afuera la cierran. Una sola lista abierta a la vez. Mientras está abierta, los tooltips de las apps no aparecen.
- **Se cierra sola** si la app se cierra, o si otra app pasa a ocupar esa casilla (por ejemplo, al abrirse una ventana nueva). Si no, mostraría las ventanas de otra app.

**Títulos cortos (`Windows.shortTitle()`):**
- Se quita el " - Brave" o " - Visual Studio Code" del final del título: al lado del ícono de la app no dice nada.
- Se usan en la lista, en el tooltip de una ventana y en el de varias.
- Ejemplos: "Osd.qml - quickshell - Visual Studio Code" → "Osd.qml - quickshell"; "LinuxTools - Claude - Brave" → "LinuxTools - Claude".
- Obsidian queda igual, porque su título termina con la versión ("Obsidian 1.13.7").

**Verificado** en una copia de la config, con las ventanas reales y el foco y los clicks simulados por un gancho que llama al mismo código del `MouseArea`:
- **Una ventana:** el click en VS Code la enfocó sin abrir la lista.
- **Click derecho:** en Brave abrió la lista con una fila. Al elegirla, se enfocó y la lista se cerró.
- **Tres ventanas:** en la copia se agruparon las 3 ventanas como una sola app, porque ahora ninguna app tiene dos. La casilla mostró tres puntos y la lista las tres filas, en el orden en que se abrieron, con el punto en la activa. Elegir una fila enfocó esa ventana.
- **Cambio de app en la casilla con la lista abierta:** la lista se cerró.
- **Capturas:** la lista de una ventana y la de tres.
- **Instalación en vivo:** Settings, servicio, menú y widget, en ese orden. Cada uno recargó sin errores.

**Sin probar:**
- clicks reales;
- el hover de las filas;
- Esc y click afuera (en la copia `grabFocus` estaba apagado, para no tomar el teclado).

## 2026-09-28 — Apps abiertas: una por app, no por ventana

**Archivos:**
- `services/Windows.qml` — `apps`, `appId()` y `focusApp()`. `recent` ya no se corta en `Settings.windows.limit` (ahora se corta `apps`).
- `widgets/WindowsWidget.qml` — cada slot es una app.

**Antes:** cada ventana ocupaba un slot. Con dos kitty y dos Brave abiertos, 4 de los 5 slots eran dos apps repetidas, y la sexta ventana (VS Code) no entraba.

**Ahora:**
- **Agrupadas por app:** las ventanas se juntan por `wayland.appId` (con la clase de Hyprland mientras no llega el handle de Wayland). Cada app queda donde está su ventana enfocada más reciente.
- **Puntos:** una app con más de una ventana muestra un punto por ventana debajo del ícono, hasta tres, como en un dock. Con una sola ventana se ve igual que antes.
- **Resaltado:** el slot se pinta con `selected` si cualquiera de las ventanas de la app tiene el foco.
- **Click:**
  - si la app no tiene el foco, va a su ventana más reciente;
  - si ya lo tiene, pasa a su siguiente ventana. "Siguiente" sigue el orden en que se abrieron y no la recencia: por recencia, la siguiente siempre sería la que se acaba de dejar, y una tercera ventana nunca aparecería.
- **Tooltip:**
  - una ventana: igual que antes (título / app · workspace);
  - varias: el nombre de la app, "2 windows" a la derecha y los títulos de sus ventanas debajo, la más reciente primero.

**Verificado** en una copia de la config, con las ventanas reales abiertas y el foco simulado: `focus()` en la copia solo anotaba la ventana en vez de enfocarla, para no mover el foco real.
- **Grupos:** 6 ventanas → 4 apps (Brave ×2, Obsidian, kitty ×2, VS Code).
- **Clicks:** kitty sin foco → su ventana más reciente. Clicks seguidos → alternan entre sus dos ventanas. Lo mismo con Brave.
- **Capturas:** la barra (Brave activo con dos puntos, kitty con dos puntos) y los tooltips de kitty y de VS Code.
- **Instalación en vivo:** primero el servicio y después el widget, cada uno recargó sin errores.

**Sin probar:**
- clicks reales;
- el ciclo con tres ventanas de una misma app (no había ninguna así abierta).

## 2026-09-28 — Bandeja del sistema

**Archivos:**
- `widgets/TrayWidget.qml` — nuevo: la píldora con los íconos.
- `widgets/tray/TrayMenu.qml`, `widgets/tray/TrayMenuRow.qml` — nuevos: el menú de cada app.
- `panels/Bar.qml` — `TrayWidget {}` al principio de la sección derecha, antes de la red.
- `config/Settings.qml` — `tray.menuMinWidth` / `tray.menuMaxWidth`.

### La bandeja
- **Qué es:** los íconos de las apps que siguen corriendo en segundo plano (Steam, Discord, Telegram...), las que usan StatusNotifierItem.
- **Dónde:** una píldora en la sección derecha de la barra, antes de la red. **Se oculta cuando no hay ninguna app.**
- **Íconos:** en cuadritos de 24 px como los de apps abiertas, con fondo al pasar el mouse o con su menú abierto. Si la app pide atención (`NeedsAttention`), aparece un punto de acento en la esquina.
- **Clicks:** izquierdo abre la app (o el menú, si la app solo tiene menú); derecho, su menú; medio, la acción secundaria. La rueda se pasa a la app.
- **Tooltip:** el título y la descripción que manda la app, o su nombre si no manda nada. Con un menú abierto, los tooltips de la bandeja no aparecen, para no taparlo.
- La shell ahora es el `org.kde.StatusNotifierWatcher` de la sesión: las apps que ya estaban abiertas se registran solas.

### El menú
- **Antes:** no había forma de ver el menú de una app de la bandeja.
- **Ahora:** las entradas que manda la app (DBusMenu) se dibujan con el estilo del menú de energía: panel con borde degradado, filas de 36 px, separadores. Cuelga debajo de la barra, centrado en el ícono y sin pasarse de los bordes de la barra.
- Checkboxes y radios con símbolos de Material (`check_box`, `radio_button_checked`...). Las entradas deshabilitadas se ven atenuadas y no responden.
- **Submenús:** reemplazan la lista, con una fila arriba (flecha + nombre) para volver.
- Un solo menú abierto a la vez. Esc o un click afuera lo cierran.
- El menú se carga solo mientras está abierto, así la app lo actualiza cada vez que se abre.
- **Bug encontrado en la prueba:** al entrar a un submenú se seguía viendo el menú principal. Quickshell descarta las entradas de un menú en cuanto nadie lo tiene abierto, y el submenú es una de ellas. Ahora cada nivel tiene su propio `QsMenuOpener` (con `Variants`) y todos quedan cargados mientras se navega.

**Verificado** en una copia de la config sobre un bus DBus privado, con dos apps de bandeja falsas (Python + `dbus-next` en un venv del scratchpad) y un `IpcHandler` de prueba que hace lo que harían los clicks:
- **Barra:** los dos íconos aparecen en la píldora; el que pide atención lleva el punto. Sin apps, la píldora no se ve.
- **Menú:** ícono, separadores, checkbox, flecha de submenú y un texto largo cortado con "…". Los guiones bajos de atajo ya los quita Quickshell ("_Open" → "Open", "Test__App" → "Test_App").
- **Submenú:** "Status" con tres radios, uno deshabilitado; volver funciona.
- **Clicks:** la app recibe `Event <id> clicked`. El checkbox y el radio cambian al reabrir el menú, con `ItemsPropertiesUpdated` como mandan las apps reales.
- **Uno a la vez:** abrir el menú de la otra app cerró el primero.
- **App que se cierra con su menú abierto:** el ícono desaparece, el menú se cierra y no hay errores.
- **Instalación en vivo:** recargó sin errores, y `busctl` muestra a `qs` como `StatusNotifierWatcher` con el host registrado.
- **Sin probar:** clicks reales (no hay `ydotool`), Esc y click afuera (en la copia `grabFocus` estaba apagado para no tomar el teclado), y una app real.
- **Detalle de Quickshell:** si una app pide atención pero no manda ícono de atención, Quickshell muestra un ícono roto en vez del normal. Pasó con la app falsa; con apps reales es raro.

## 2026-09-25 — No molestar, atajo para la barra lateral, historial guardado, acciones en el historial y respuesta rápida

**Archivos:**
- `services/Notifications.qml` — casi todo el cambio.
- `widgets/notifications/NotificationContent.qml` — acciones y respuesta a partir de la notificación viva.
- `widgets/notifications/NotificationToast.qml`, `NotificationHistoryEntry.qml`.
- `panels/NotificationPopups.qml`, `panels/NotificationCenter.qml` — foco de teclado mientras se responde.
- `widgets/quickSettings/QuickToggles.qml` — círculo de no molestar.
- `widgets/NotificationCenterButton.qml` — ícono de no molestar.
- `~/.config/hypr/hyprland.lua` — SUPER+N.

### No molestar
- **Dónde:** el primer círculo vacío de la barrita de botones rápidos (quedan 2). Ícono `do_not_disturb_on`/`off`, relleno de acento cuando está activo, y tooltip "Do not disturb · On / Only critical notifications pop up".
- **Qué hace:** las notificaciones nuevas no muestran toast y van directo al historial. **Las críticas sí aparecen**: un aviso de batería baja no se puede perder.
- **Indicador:** mientras está activo, el botón del centro de control en la barra cambia a `do_not_disturb_on`, porque ningún toast lo va a recordar. Su tooltip agrega "Do not disturb".
- Se guarda en disco junto con el historial.
- También por IPC: `qs ipc call dnd toggle|on|off`.

### Atajo
- **SUPER+N** abre y cierra la barra lateral: `hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call sidebar toggle"))`, junto a los otros binds.
- `IpcHandler` con target `sidebar`: `toggle`, `open`, `close`.

### Historial guardado en disco
- En `Quickshell.statePath("notifications.json")` (`~/.local/state/quickshell/by-shell/<id>/`). Se escribe medio segundo después del último cambio, así una ráfaga de notificaciones escribe una sola vez.
- **Sobrevive recargas y reinicios.** Antes se perdía con cada recarga.
- Cada entrada tiene su propia `key`. El id del servidor se reinicia con `qs` y ya no alcanza para identificarlas.
- Las imágenes que llegan como datos crudos solo existen mientras la notificación está abierta; no se guardan, y después de un reinicio la insignia usa el ícono de la app.
- No se guarda nada hasta haber leído el archivo, para no pisarlo con lo que llegue mientras tanto.

### Acciones en el historial
- **Antes:** el toast cerraba la notificación (`expire()`) al terminar su tiempo, así que el historial solo guardaba una copia sin botones.
- **Ahora:** al terminar el tiempo, el toast solo sale de pantalla (`hidePopup()`) y la notificación sigue abierta. Su entrada del historial mantiene los botones de la app, y la respuesta, hasta que la app la cierra o la quitas.
- Excepciones, que se cierran con el toast: las **transitorias** (ni siquiera entran al historial) y las que traen **su propio tiempo de expiración**.
- Quitar una entrada o "Clear" cierra la notificación. Si el historial se llena, las más viejas se cierran al salir.
- Al activar una acción, Quickshell cierra la notificación (salvo las `resident`). La entrada queda, sin botones.

### Respuesta rápida
- `inlineReplySupported: true`. Si la app la ofrece, aparece un botón **"Reply"** antes de las acciones, en el toast y en el historial.
- Al tocarlo, los botones se reemplazan por un campo en píldora como el de la contraseña del Wi-Fi, con el texto de sugerencia de la app y una flecha para enviar. Enter o la flecha envían; Esc cancela. Quickshell cierra la notificación al enviar.
- Una sola respuesta abierta a la vez (`Notifications.replyingTo`). Mientras está abierta:
  - la ventana que la muestra (toasts o barra lateral) pide el teclado (`Exclusive`), como con la contraseña del Wi-Fi;
  - el toast no se va.

### Recargas en vivo
- **El problema:** con `keepOnReload`, Quickshell vuelve a emitir las notificaciones que seguían abiertas, con `lastGeneration: true`. Sin manejarlo, el historial se **duplicaba** en cada recarga (se vio en la prueba: 6 entradas en vez de 3).
- **La solución:** ahora se enlazan con su entrada guardada (`relink()`), sin importar si llegan antes o después de que se lea el archivo.
- Las que no tienen entrada, porque llegaron justo antes de la recarga o porque no había archivo (la primera vez), **se agregan al historial** (`adopt()`) en vez de cerrarse.

**Verificado** en una copia de la config sobre un bus DBus privado, con `notify-send` reales y un `IpcHandler` de prueba que hace lo que harían los clics:
- **Toasts:** simple, con dos acciones ("Open", "Later") y con respuesta rápida ("Reply"). Pasado el tiempo salen de pantalla y quedan abiertas en el historial (`live: true`, 2 acciones).
- **Barra lateral abierta por IPC:** el historial muestra los botones y "Reply"; al responder aparece el campo en píldora con la flecha.
- **Respuesta:** DBus emite `NotificationReplied "On my way!"` y después `NotificationClosed` (motivo 2). La entrada queda, sin botones. El primer intento dio "Cannot close destroyed notification" porque además se llamaba `dismiss()` después de enviar; se quitó, y la repetición no tuvo errores.
- **Acción:** `ActionInvoked "open"`, `notify-send` recibió "open", y la notificación se cerró sola.
- **No molestar:** una normal no mostró toast y entró al historial; una crítica sí mostró toast. El botón de la barra cambió de ícono.
- **Reinicio completo:** volvieron las 5 entradas (sin enlace) y no molestar seguía activo.
- **Recargas:** dos seguidas → 3 entradas, sin duplicados, todas enlazadas. Sin archivo + recarga → las abiertas se agregaron con su acción.
- **Instalación en vivo:** los 8 archivos pasaron juntos en un solo comando, después de comprobar que ninguno se había editado desde la copia. Recargó sin errores y `qs ipc show` lista `sidebar` y `dnd`. `qs ipc call sidebar toggle` abrió y cerró la barra lateral.
- **Hyprland:** tomó el cambio (`hyprctl configerrors` vacío) y `hyprctl binds` muestra SUPER+N.

**Sin probar** (necesitan teclado o mouse reales):
- apretar SUPER+N;
- tocar el círculo de no molestar, "Reply", un botón de acción o la X;
- escribir una respuesta con el foco de teclado real (en la copia estaba forzado a `None`).

## 2026-09-25 — App launcher con el estilo de la barra lateral

El launcher ahora se arma con las mismas piezas que la barra lateral, los toasts y los tooltips.

**Antes:**
- Muy transparente: se leía la ventana de atrás.
- Buscador rectangular con la fuente por defecto de Qt.
- Íconos de 16 px en filas separadas por líneas.
- No se veía qué app se abría, y Enter no hacía nada.

**Archivos:**
- `widgets/appLauncher/AppLauncher.qml` — reescrito.
- `widgets/appLauncher/AppEntry.qml` — reescrito. La señal `launched` pasa a llamarse `activated`, y el launcher hace el `execute()`.
- `widgets/AppLauncherButton.qml` — abre con `launcher.toggle()`, que calcula la posición antes de mostrar.
- `config/Settings.qml` — `appLauncher.padding` (14) y `appLauncher.spacing` (12), los mismos valores que la barra lateral.

**Diseño:**
- **Panel:** el mismo `PopupContainer` que la barra lateral: `Theme.radiusPanel` y 14 px de relleno. Es su espejo del otro lado de la pantalla: el borde superior a la misma altura (debajo de la barra, a `Theme.margins`) y el izquierdo alineado con el extremo de la barra.
- **Buscador:** una píldora como el campo de contraseña del Wi-Fi (`surfaceHigh`, anillo de 2 px `selected` con foco), con lupa a la izquierda y un `IconButton` redondo para borrar. Maple Mono, como el resto.
- **Lista:** dentro de un `CardContainer`, como las notificaciones. Cada app es una tarjeta como las de Wi-Fi o Bluetooth:
  - ícono de 22 px en una insignia redonda de 36;
  - el nombre en peso medio;
  - debajo, en gris, el tipo de app ("Web Browser", "File Manager"): el `GenericName`, o el comentario si no hay, salvo que solo repita el nombre, como el de Obsidian.
- **Seleccionada** (la que abre Enter): el relleno suave de una tarjeta destacada más el anillo de un campo con foco. Solo el relleno casi no se distinguía de las demás tarjetas. Va encima del fondo normal y no en su lugar: `container` solo es muy transparente, y justo esa tarjeta dejaba ver la ventana de atrás.
- **Sin resultados:** ícono `search_off` y "No apps found", como "No notifications".
- **Pie:** "13 apps" a la izquierda, como el contador de notificaciones, y "↑↓ move · Enter open" en gris a la derecha.
- Entra con un fundido mientras baja 4 px, como los tooltips.
- El texto del buscador ("What's the matter...") no cambió.

**Comportamiento nuevo:**
- **Teclado:** Enter abre la seleccionada, ↑/↓ la mueven (la lista se desplaza para mantenerla a la vista) y Esc cierra. Al escribir, la selección vuelve a la primera.
- **Búsqueda, de mejor a peor coincidencia:**
  - el nombre empieza con lo escrito;
  - una palabra del nombre empieza con lo escrito;
  - el nombre lo contiene;
  - solo el tipo o las palabras clave lo contienen ("browser" encuentra Brave).
- **Orden alfabético sin distinguir mayúsculas:** el locale del sistema es `C`, y antes "kitty" quedaba después de "XAMPP".

**Corte de la shell durante el cambio:**
- **Qué pasó:** `AppEntry.qml` (con la señal renombrada) se escribió antes que `AppLauncher.qml`. La recarga automática tomó el estado intermedio y falló con `Cannot assign to non-existent property "onLaunched"`. A las 15:13 se reinició `qs`, que volvió a fallar con el mismo error, y la shell quedó sin barra.
- **Arreglo:** con los dos archivos ya coherentes, se relanzó como lo hace Hyprland (`hyprctl dispatch 'hl.dsp.exec_cmd("qs")'`). Cargó sin errores.
- **Lección:** en cambios que tocan varios archivos, cada escritura tiene que dejar la config en un estado que cargue.

**Verificado** en una copia, con el launcher abierto por código (`grabFocus: false`) y un gancho por archivo para escribir en el buscador y mover la selección:
- capturas del launcher completo, de la búsqueda "b" (Brave, Obsidian, Dolphin), "browser" (Brave) y "zzz" (pantalla vacía);
- la selección bajando a la tercera y a la décima, con la lista desplazada;
- posición: y=58 y x=8, igual que la barra lateral en el otro lado;
- instancia en vivo recargada sin errores después de cada cambio posterior al corte.

**Sin probar** (necesita teclado y mouse reales):
- abrir con el botón;
- escribir, Enter, Esc y abrir una app con clic;
- el hover sobre las tarjetas.

## 2026-09-25 — OSD para las teclas de volumen, micrófono y brillo

Al usar las teclas de volumen, silencio, micrófono o brillo aparece una tarjeta debajo de la barra, centrada, con el mismo diseño que los tooltips. Se va sola a los 1,5 s de la última pulsación.

**Qué OSD hacen falta.** Salen de los binds de `hyprland.lua`:
- **Volumen** (`XF86AudioRaiseVolume`/`LowerVolume`/`Mute`): corren `wpctl` directo, sin ninguna respuesta visible.
- **Micrófono** (`XF86AudioMicMute`): la shell no muestra el micrófono en ningún lado, así que no había forma de saber si quedó silenciado.
- **Brillo** (`XF86MonBrightnessUp`/`Down`): corren `brightnessctl`.
- **No se hicieron:** multimedia (`playerctl` no está instalado, así que esas teclas hoy no hacen nada; un OSD de qué suena va mejor junto con el widget de now playing), Caps Lock (los teclados tienen luz) y luz del teclado (no hay en `/sys/class/leds`).

**Archivos:**
- `panels/Osd.qml` (nuevo) — el OSD.
- `components/InfoCard.qml` (nuevo) — la tarjeta que antes estaba dentro de `Tooltip.qml`: insignia, título con valor, detalle, barra de nivel y el fundido. La comparten los tooltips y el OSD.
- `components/Tooltip.qml` — usa `InfoCard`; sin cambios visibles.
- `services/Audio.qml`:
  - micrófono: `source`, `micReady`, `micMuted`, `micDevice`;
  - `PwObjectTracker` sigue también la entrada por defecto;
  - `localChangeAt`, que marcan `setVolume()` y `toggleMute()`.
- `services/Brightness.qml` — `localChangeAt`, que marca `write()`.
- `config/Settings.qml` — `Settings.osd`: `width` 300, `timeout` 1500 ms.
- `shell.qml` — `Osd {}`.

**Contenido** (título · valor / detalle):
- **Volumen:** "Volume" · "5%" o "Muted" / "Speaker", con barra (gris si está silenciado).
- **Micrófono:** "Microphone" · "Muted" u "On" / "Digital Microphone".
- **Brillo:** "Brightness" · "82%", con barra.

**Cómo funciona:**
- **Capa `Overlay`**, así aparece también sobre ventanas en pantalla completa. Namespace `quickshell:osd`, por si hace falta un `layerrule` propio.
- Anclada solo arriba, así el compositor la centra. A la misma distancia del borde que los toasts y la barra lateral.
- **Ancho fijo**, para que no tiemble al mantener una tecla. El contenido se actualiza en vivo.
- No recibe input (`mask: Region {}`).
- **Solo cuenta un valor que se movió en el mismo dispositivo que ya conocía.** Un dispositivo que aparece (la shell arrancando, Pipewire tarde) o que cambia (enchufar audífonos) también mueve los valores, y no es una tecla. Las comprobaciones se difieren con `Qt.callLater`, porque al aparecer un dispositivo cambian varias propiedades juntas.
- **Los cambios hechos desde la shell no lo muestran:** el scroll sobre el volumen o el brillo de la barra y los botones rápidos de la barra lateral. Esos controles ya muestran el valor. Pipewire y udev informan igual un cambio propio que uno de las teclas; por eso se descarta lo que llega hasta 500 ms después de un `localChangeAt`.

**Verificado:**
- Contra la instancia en vivo, con los mismos comandos que corren las teclas y el estado restaurado después:
  - `wpctl set-volume … 5%+` → "Volume · 5%";
  - `wpctl set-mute … toggle` → "Muted";
  - `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` → "Microphone · Muted";
  - `brightnessctl -e4 -n2 set 5%-` → "Brightness · 82%";
  - desaparece a los ~1,5 s.
- Al recargar la configuración no aparece.
- **Eco de los controles propios**, en una copia con log en `show()`:
  - `Audio.setVolume()` (0 → 0.05 → 0) y `Brightness.decrease()`/`setLevel()` (400 → 380 → 400) se aplicaron y no lo mostraron;
  - dos `wpctl set-volume` externos, como control, sí lo mostraron.
- Instancia en vivo recargada sin errores.

**Sin probar:**
- Las teclas físicas en sí (los comandos son los mismos de los binds).
- Mantener una tecla apretada.
- Enchufar audífonos o cambiar de salida.

## 2026-09-25 — Tooltips en la barra lateral

Los controles de la barra lateral que son solo un ícono ahora también tienen tooltip, con el mismo diseño que los de la barra de arriba.

**Archivos:**
- `components/Tooltip.qml`:
  - `below`: el ítem del que cuelga el tooltip. Por defecto sigue siendo la ventana entera, o sea la barra de arriba.
  - `windowVisible`: se oculta si se esconde la ventana del widget.
  - El centrado ahora se ajusta a los lados de la ventana (antes, a los extremos de la barra).
- `widgets/quickSettings/QuickToggles.qml` — los cuatro botones rápidos.
- `widgets/PowerButton.qml` — el botón de apagado.
- `components/ChipTabs.qml` — las pestañas redondas (la actual ya muestra su nombre).
- `widgets/calendar/MonthCalendar.qml` — hoy, mes anterior y mes siguiente. `monthLabel(delta)` arma "September 2026", y el título del mes ahora también lo usa.

**Contenido** (título · valor / detalle):
- **Wi-Fi:** "Wi-Fi" · "On"/"Off" / "Connected to Tec" o "Not connected".
- **Bluetooth:** "Bluetooth" · "On"/"Off" / "No devices connected", "Connected to X" o "N devices connected".
- **Volumen:** "Volume" · "65%"/"Muted" / "Speaker", con barra.
- **Brillo:** "Brightness" · "100%" (/ "Dimmed" si está atenuado), con barra.
- **Apagado:** "Power" / las opciones del menú ("Suspend, log out, reboot, shut down"). Se arma desde el menú, así que "Lock" aparece solo cuando haya un bloqueador instalado. Espacios no separables dentro de cada opción, para que la línea no se corte entre "shut" y "down".
- **Pestañas:** "Wi-Fi", "Bluetooth" o "Notifications", solo en las redondas.
- **Calendario:** "Today" / "Friday, 25 September"; "Previous month" / "August 2026"; "Next month" / "October 2026".

**Cómo funciona:**
- Los de los botones rápidos cuelgan debajo de la barrita entera, no de cada botón, así quedan todos a la misma altura, como los de arriba debajo de la barra. Los demás cuelgan debajo de su botón.
- Dentro de la barra lateral quedan centrados bajo el botón, sin pasarse de los lados de la barra lateral.
- El de apagado no aparece con el menú abierto. El de "hoy" se oculta al volver al mes actual, junto con su botón.
- **Si la barra lateral se cierra con un tooltip a la vista**, se oculta. `QsWindow.window.visible` del widget entra en la condición para mostrarse; sin eso, el tooltip quedaba como "a la vista" y reaparecía al volver a abrir la barra lateral.

**Verificado:**
- Capturas de los diez tooltips nuevos en una copia de la config con la barra lateral abierta, forzados por archivo.
- Log de la copia: al cerrar la barra lateral, los diez pasan a `windowVisible: false`, y al abrirla, a `true`. Al crearse, `QsWindow.window` todavía es `null`; por eso el valor por defecto es `true`.
- Instancia en vivo recargada sin errores.

**Sin probar:**
- Hover real en la barra lateral: la prueba con el puntero se mezcló con el mouse del usuario, que se estaba moviendo al mismo tiempo.
- El tooltip de "hoy", que solo aparece después de cambiar de mes (necesita un clic).
- El de Bluetooth con el adaptador no disponible: el botón queda deshabilitado, y un ítem deshabilitado no recibe hover, así que no se muestra.

## 2026-09-25 — Tooltips en la barra de arriba

Cada widget de la barra muestra una tarjeta al dejar el puntero encima, con el mismo diseño que los toasts de notificación.

**Archivos:**
- `components/Tooltip.qml` (nuevo) — el tooltip: `PopupWindow` con `PopupContainer` (borde en degradado, `Theme.radiusCard`), insignia redonda, título con un valor a la derecha (donde la notificación pone la hora), una línea de detalle en gris y una barra de nivel opcional.
- `components/TooltipState.qml` (nuevo, singleton) — cuál está en pantalla y cuándo se ocultó el último.
- `components/PopupContainer.qml` — `surface`: el color de fondo, por defecto `Theme.colors.surface` (los demás popups no cambian).
- `config/Settings.qml` — `Settings.tooltip`: `delay` 500 ms, `grace` 300 ms, `minWidth` 180, `maxWidth` 300.
- `services/Time.qml` — `Time.week` (semana ISO 8601).
- `services/Audio.qml` — `Audio.device`: nombre corto de la salida ("Speaker"), o la descripción completa si no hay.
- `services/Battery.qml` — `Battery.pending` (enchufada sin cargar) y `Battery.rate` (W).
- `services/Windows.qml` — `appName()` y `appIcon()` de una ventana, a partir de su entrada `.desktop`.
- Los nueve widgets de la barra.

**Contenido** (título · valor / detalle):
- **Apps:** "Applications" / "Search and launch".
- **Espacios de trabajo** (uno por número): "Workspace 3" / "2 windows · kitty, Firefox", o "Empty".
- **Ventanas** (una por casilla): el título de la ventana, cortado con "…", con el ícono de la app en la insignia / "Visual Studio Code · Workspace 1".
- **Reloj:** "Friday" · "Week 39" / "25 September 2026".
- **Red:** nombre de la red · señal ("69%") / "Wi-Fi · 10.48.105.240". Sin conexión: "Offline" en alerta, con "Not connected" o "Wi-Fi is off".
- **Brillo:** "Brightness" · "100%", con barra.
- **Volumen:** "Volume" · "65%" o "Muted" / "Speaker", con barra (gris si está silenciado).
- **Batería:** "Battery" · "80%" / "Fully charged", "Plugged in, not charging", "Charging · full in 1 h 20 min" o "2 h 15 min left · 8.4 W". Barra verde enchufada, roja con batería baja (y la tarjeta en alerta), de acento si no.
- **Centro de control:** "Control center" / "3 notifications".

**Cómo funciona:**
- Aparece a los 500 ms de hover. Usa un `HoverHandler` sobre el widget, que no le quita eventos a sus `MouseArea`.
- Si ya hay uno a la vista, o el último se ocultó hace menos de 300 ms, el siguiente aparece al instante: recorrer la barra no hace esperar en cada widget. Nunca hay dos a la vez.
- **Posición:** debajo de la barra a `Theme.margins`, a la misma altura que los toasts y la barra lateral. Centrado bajo el widget, pero sin pasarse de los extremos de la barra: el de la batería queda alineado con el borde derecho de la barra lateral.
- Entra con un fundido mientras baja 4px (140 ms), y sale igual.
- No recibe input (`mask: Region {}`): un click sobre un tooltip que se está yendo llega a la ventana de abajo.
- **Fondo casi opaco** (95 %), a diferencia de los toasts: con la transparencia normal, en la primera captura se leía el texto de VS Code a través de la tarjeta.
- El de apps no aparece con el launcher abierto, ni el del centro de control con la barra lateral abierta (caería encima de ella).
- El contenido es en vivo: cambiar el volumen con scroll mientras está abierto actualiza el valor y la barra.

**Fix aparte: íconos genéricos en las apps abiertas al arrancar**
- **Síntoma:** en un arranque de la copia de prueba, la casilla de VS Code mostró el ícono genérico y el tooltip decía "com.microsoft.VSCode". En otro arranque de la misma copia salió bien.
- **Causa:** las entradas `.desktop` se escanean en segundo plano al arrancar, y `DesktopEntries.heuristicLookup()` es una llamada que un binding no puede observar. Una ventana consultada antes de que terminara el escaneo quedaba así hasta que otra cosa volviera a evaluar el binding. Ya pasaba antes con el ícono de la barra; el tooltip lo hizo visible con el nombre.
- **Fix:** `Windows.entry()` lee `DesktopEntries.applications.values` antes de buscar, y eso vuelve a evaluar los bindings cuando la lista se llena.

**Verificado:**
- Capturas de cada tooltip en una copia de la config, forzados a mostrarse con un archivo que la copia vigila: diseño, título largo cortado, variante de alerta forzada.
- **Hover real**, moviendo el puntero con `hyprctl dispatch 'hl.dsp.cursor.move({ x = …, y = … })'` sobre la barra de la copia:
  - a los 200 ms no hay nada; a los 900 ms aparece;
  - al salir de la barra se va;
  - la casilla de ventana, que tiene su propio `MouseArea` con hover, también lo muestra;
  - salir y entrar en el widget vecino dentro de los 300 ms lo muestra al instante; pasados los 300 ms, vuelve a esperar.
- Arranque en frío de la copia después del fix: ícono y nombre de VS Code correctos.
- Instancia en vivo recargada sin errores.

**Sin probar:**
- Pasar de un widget al vecino sin salir de la barra. El salto de puntero de Hyprland dentro de una misma superficie no manda movimiento: sin ningún tooltip abierto, saltar de batería a volumen dejó el de batería. Solo se puede probar con el mouse, y es el caso normal de uso.
- Que se oculten al abrir el launcher o la barra lateral (necesita un click).
- Los textos de batería descargando y de "Offline" con datos reales: el cargador está enchufado y hay red.

## 2026-09-24 — Menú de energía

El botón de apagado de la barra lateral (que no hacía nada) ahora abre un menú desplegable debajo, alineado a la derecha.

**Archivos:**
- `services/Session.qml` (nuevo) — `lock()`, `suspend()`, `logout()`, `reboot()`, `poweroff()`, y `locker` (primer bloqueador encontrado entre `hyprlock`, `swaylock`, `gtklock`).
- `widgets/powerMenu/PowerMenu.qml` (nuevo) — el menú: `PopupWindow` con `grabFocus` (se cierra al hacer click afuera o con Esc).
- `widgets/PowerButton.qml` — abre/cierra el menú, se pinta de acento mientras está abierto, y cierra el menú cuando se cierra la barra lateral.

**Opciones:**
- **Lock** — solo aparece si hay un bloqueador instalado. Hoy no hay ninguno, así que no se muestra.
- **Suspend** → `systemctl suspend`, al primer click.
- **Log out** → `hyprctl dispatch 'hl.dsp.exit()'`, el mismo comando que el bind Super+M (la config de Hyprland es Lua).
- **Reboot** → `systemctl reboot`; **Shut down** → `systemctl poweroff`.
- Log out, Reboot y Shut down piden un segundo click: el primero pinta la fila de acento con "Reboot now?" y similares; si no llega el segundo en 3 s, vuelve a la normalidad.
- Antes de ejecutar, se cierran el menú y la barra lateral.
- Comandos con `Quickshell.execDetached`, para que no mueran con el shell.

**Medido:** logind responde `yes` a `CanPowerOff`, `CanReboot`, `CanSuspend` y `CanHibernate`, y `systemctl {poweroff,reboot,suspend} --dry-run` sale con 0 (no hace falta contraseña). Hibernar no se ofrece: logind dice que se puede, pero no está comprobado que el sistema tenga swap y `resume` configurados para volver.

**Verificado** (copia con cada `execDetached` reemplazado por `console.log`, así que nada se ejecutó):
- Suspend lanza `[systemctl, suspend]` al primer click; Log out `[hyprctl, dispatch, hl.dsp.exit()]`, Reboot `[systemctl, reboot]` y Shut down `[systemctl, poweroff]` solo al segundo.
- La confirmación se cancela sola a los 3 s.
- Sin bloqueador, el menú muestra 4 opciones (sin Lock).
- Capturas del menú abierto y de la fila "Reboot now?". Para la captura, la copia usó `grabFocus: false`: un popup con grab necesita que su ventana haya recibido un click real, y abierto por código Qt se niega a crearlo ("Failed to create grabbing popup"). Con un click del usuario funciona como el app launcher.

**Sin probar:** ninguna acción de verdad, ni el click real en el botón.

## 2026-09-24 — Pestaña de Bluetooth en la barra lateral

Tercera pestaña, junto a Wi-Fi: "Notifications", "Wi-Fi", "Bluetooth" y un `EmptySlot`.

**Archivos:**
- `widgets/bluetooth/BluetoothPanel.qml` (nuevo) — encabezado ("Bluetooth" + qué está conectado + interruptor), lista, estados vacíos ("Bluetooth is off", "Bluetooth is unavailable", "Searching for devices…").
- `widgets/bluetooth/BluetoothDeviceEntry.qml` (nuevo) — tarjeta por dispositivo, mismo estilo que las de Wi-Fi.
- `services/Bluetooth.qml` — `scanning` (→ `adapter.discovering`), `devices`, `connectedDevices`, `deviceIcon()`, `pairAndConnect()`.
- `panels/NotificationCenter.qml` — pestaña y vista nuevas.

**Cómo funciona:**
- **Lista:** conectados primero, después emparejados, después por nombre. Se ocultan los dispositivos sin nombre (medido: 10 de 14 al buscar eran beacons de baja energía que solo muestran la dirección), salvo que estén emparejados.
- **Tarjeta:** ícono según el tipo que reporta BlueZ (auriculares, parlante, mouse, teclado, control, teléfono, computadora, TV…; `bluetooth` si no hay), nombre y estado: "Connected · 80%" (batería si la reporta), "Paired", "Not paired", "Pairing…", "Connecting…".
- **Click:** emparejado → conecta. Nuevo → lo marca de confianza (para que se reconecte solo), lo empareja y, al terminar, lo conecta. Emparejando → cancela. Conectado → cajón con "Disconnect" y "Forget".
- **Errores:** BlueZ no da motivos, así que si un intento termina sin conexión se muestra "Couldn't pair" o "Couldn't connect".
- **Búsqueda:** `adapter.discovering` solo mientras la pestaña está a la vista y el panel abierto, igual que el escaneo de Wi-Fi.
- **Sin agente de emparejamiento:** solo se pueden emparejar desde acá los dispositivos que no piden PIN ni código de confirmación (la mayoría de auriculares, parlantes y mouses). Los que sí lo piden necesitan `bluetoothctl`.
- Las tarjetas leen el dispositivo con `?.` desde el principio: BlueZ lo quita al salir de alcance, igual que las redes de Wi-Fi.

**Verificado:**
- Sonda: 14 dispositivos al buscar, 4 con nombre; `discovering` vuelve a `false` al terminar.
- Captura de una copia con la pestaña abierta: 6 dispositivos con nombre, íconos por tipo, fila de pestañas con el chip "Bluetooth".
- Búsqueda: se prende al abrir la pestaña, se apaga al pasar a Wi-Fi y al cerrar el panel (`discovering` leído del adaptador en cada paso; `bluetoothctl show` → "Discovering: no" al final).
- Instancia en vivo recargada sin errores; después del reinicio del usuario, el botón de bluetooth de la barrita ya se ve encendido.

**Sin probar:** emparejar, conectar, desconectar y olvidar un dispositivo real, y el valor de batería (ningún dispositivo cercano la reporta).

## 2026-09-24 — Bluetooth: BlueZ instalado

El usuario instaló `bluez` + `bluez-utils` 5.87 y habilitó `bluetooth.service`. El adaptador `hci0` ("notarch", `C4:0F:08:A9:D5:E3`) queda encendido y visible en `org.bluez`.

**Sin cambios de código** salvo el comentario de `services/Bluetooth.qml`: el botón de la barrita ya dependía de `Bluetooth.available`/`powered`.

**Medido:**
- Una instancia nueva de `qs` ve el adaptador (`Bluetooth.available` y `powered` en `true`), pero recién ~1 s después del primer acceso al módulo: una lectura inmediata da `null`.
- La instancia que ya corría antes de arrancar `bluetoothd` **no** lo ve, ni después de recargar la configuración (captura de la barrita con el panel abierto un momento: ícono tachado y deshabilitado). El módulo de Quickshell busca BlueZ una sola vez, al iniciar el proceso, y no reintenta. Hace falta reiniciar `qs`.

## 2026-09-24 — IP actual en el servicio de red + fix de las tarjetas de Wi-Fi

### `Network.ip`

**Archivo:** `services/Network.qml`

- `Network.ip`: la IPv4 que el sistema usa ahora para salir a internet, o `""` sin conexión.
- Sale de `ip -j -4 route get 1.1.1.1` (el `prefsrc` de la ruta por defecto): sigue sola a la interfaz que lleva el tráfico, wifi o cable. Es solo una consulta a la tabla de rutas, no manda nada a 1.1.1.1.
- Se lee en el mismo sondeo que el nombre de la conexión (`Settings.network.pollInterval`, 3 s).
- `NetworkDevice.address` de `Quickshell.Networking` no sirve para esto: es la MAC (medido: `C4:0F:08:A9:D5:DF` en `wlo1`).
- Solo IPv4: en esta red no hay ruta IPv6 a internet (`ip -6 route get` → "Network is unreachable").

**Verificado:** en una copia, `Network.ip` = `192.168.10.166`, igual que `ip route get`; salida vacía (sin red) → `""`; una salida de ejemplo → su `prefsrc`.

### Fix: avisos de las tarjetas de Wi-Fi al desaparecer una red

**Archivos:** `widgets/network/WifiNetworkEntry.qml`, `services/Network.qml`

**Síntoma:** en el log de la instancia en vivo, tandas de `TypeError: Cannot read property 'connected' of null` (y `name`, `signalStrength`, `stateChanging`, `security`) en `WifiNetworkEntry.qml`, después de cambiar de red.

**Causa:** Quickshell destruye el objeto de una red en cuanto sale de alcance, un momento antes de que la lista quite su tarjeta; la tarjeta seguía leyendo `root.network.*` directo.

**Fix:** la tarjeta lee la red a través de propiedades que toleran `null` (`isConnected`, `isKnown`, `networkName`, `signal`, `security`), las acciones comprueban la red antes de llamarla, e `isSecured()`/`needsPassword()`/`supportsPassword()` aceptan `null`.

**Verificado:** tarjeta con una red falsa que se destruye mientras la tarjeta sigue viva: sin avisos, y `activate()` sobre la red nula no rompe.

**Aparte:** en el mismo log había avisos de `config/Theme.qml` líneas 45–46 ("Too many arguments", "Unable to assign [undefined] to QColor"), de una edición del usuario en curso; la versión actual del archivo ya no los produce.

## 2026-09-24 — Pestaña de Wi-Fi en la barra lateral

El primer círculo vacío junto al chip "Notifications" pasa a ser una pestaña de Wi-Fi: el cuadro de abajo muestra notificaciones o redes según la pestaña.

**Archivos:**
- `components/ChipTabs.qml` (nuevo) — fila de pestañas: la actual es un chip con ícono + nombre, las demás `IconButton` redondos; `placeholders` rellena con `EmptySlot`.
- `components/PillButton.qml` (nuevo) — botón de texto en píldora (mismo estilo que las acciones de las notificaciones).
- `widgets/network/WifiPanel.qml` (nuevo) — encabezado ("Wi-Fi" + red actual + interruptor), lista de redes, estados vacíos ("Wi-Fi is off", "Searching for networks…").
- `widgets/network/WifiNetworkEntry.qml` (nuevo) — tarjeta por red.
- `services/Network.qml` — `wifiDevice`, `wifiNetworks`, `scanning`, `isSecured()`, `needsPassword()`, `supportsPassword()`, `failReason()`.
- `widgets/notifications/NotificationHistory.qml` — la fila de pestañas sale de acá.
- `panels/NotificationCenter.qml` — `ChipTabs` + `StackLayout` (notificaciones / Wi-Fi) dentro del cuadro; foco de teclado.

**Cómo funciona:**
- Todo sale de `Quickshell.Networking` (NetworkManager por DBus), no de `nmcli`.
- **Lista:** conectada primero, después las guardadas, después por señal (en cuartos, para que no se reordene con cada fluctuación), después por nombre. Las redes ocultas (sin nombre) no aparecen. Cada tarjeta: ícono de señal en círculo (acento si está conectada), nombre, candado si tiene seguridad, y estado: "Connected", "Connecting…", "Saved · WPA2", "WPA2", "Open", o el error.
- **Click en una red:** guardada o abierta → conecta directo. Conectada → cajón con "Disconnect" y "Forget". Nueva con contraseña (WPA/WPA2/WPA3-SAE/WEP) → cajón con campo de contraseña (con ojo para mostrarla), Enter o "Connect" → `connectWithPsk`; Esc lo cierra. Empresarial (EAP) → aviso de usar `nm-connection-editor`, porque un campo de contraseña no alcanza.
- **Errores** (`connectionFailed`): "Wrong password", "Network out of range" o "Couldn't connect", en rojo en la tarjeta. Al conectar, el cajón se cierra y se borra la contraseña escrita.
- **Escaneo:** solo mientras la pestaña de Wi-Fi está a la vista y el panel abierto (`Network.scanning` → `scannerEnabled` del dispositivo), para no gastar batería.
- **Teclado:** la barra lateral pide foco de teclado (`WlrLayershell.keyboardFocus: Exclusive`) solo mientras hay un campo de contraseña abierto; el resto del tiempo `None`, así no le quita el foco a las ventanas.

**Verificado:**
- Sonda contra el hardware real: 14 redes con escaneo activo, `signalStrength` en 0–1, `WifiSecurityType.toString()` da "WPA2"/"WPA3"/"Open".
- Capturas de una copia con el panel abierto (y el foco de teclado forzado a `None` para no quitarle el teclado al usuario durante la prueba): pestaña de notificaciones con el ícono de Wi-Fi al lado; pestaña de Wi-Fi con la red conectada arriba; cajón de contraseña abierto sobre una red WPA2.
- Escaneo: se prende al pasar a la pestaña de Wi-Fi, se apaga al volver a notificaciones y al cerrar el panel (`scannerEnabled` leído del dispositivo en cada paso).
- La instancia en vivo carga sin errores (la primera recarga falló porque agarró `widgets/network/` a medio crear; la siguiente cargó bien).

**Sin probar:** conectar, desconectar y olvidar de verdad (cambiarían la conexión del usuario), escribir una contraseña con el foco de teclado real, y el mensaje de error de contraseña incorrecta.

## 2026-09-24 — Botones rápidos con fondo `surfaceHigh`

**Archivo:** `widgets/quickSettings/QuickToggle.qml` — `baseColor: Theme.colors.surfaceHigh`

Los círculos de la barrita tenían fondo transparente cuando estaban apagados; ahora usan `surfaceHigh` (`iron`). Encendidos se siguen rellenando con `accent`. Los `EmptySlot` de la misma barrita no cambian.

**Verificado:** captura de la barrita en una copia con el panel abierto; instancia en vivo recargada.

## 2026-09-24 — Interfaz en inglés

La barra de arriba ya estaba en inglés ("Thu 24 Sep", "Muted", por el locale `C` del sistema) y la barra lateral en español. Todo pasa a inglés.

**Archivos:** `widgets/notifications/NotificationHistory.qml`, `widgets/notifications/NotificationContent.qml`, `panels/NotificationCenter.qml`, `config/Settings.qml`, `widgets/calendar/MonthCalendar.qml` (solo comentarios)

**Cambios:**
- "Notificaciones" → "Notifications", "Sin notificaciones" → "No notifications", "N notificaciones" → "N notifications", "Limpiar" → "Clear", "Calendario" → "Calendar", "Ayer" → "Yesterday".
- `Settings.calendar.locale`: `es_MX` → `en_US`. Sigue empezando la semana en domingo; `en_GB` la empieza en lunes. Afecta el mes del calendario ("September 2026"), los días ("Su Mo Tu…") y las fechas viejas de las notificaciones ("22 Sep").

**Verificado:** captura de la barra lateral en una copia con bus DBus privado y dos `notify-send` reales; sin textos en español en la interfaz. Instancia en vivo recargada con `touch shell.qml`.

## 2026-09-24 — Toasts: la hora queda pegada a los botones

**Archivo:** `widgets/notifications/NotificationContent.qml`

**Problema:** el fix del congelamiento dejó el botón de expandir siempre en el layout (invisible con `opacity: 0`), así que en las notificaciones cortas quedaba un hueco de 24px entre la hora y la X.

**Fix:** hora, expandir y cerrar pasan a un `Item` con ancho fijo (el de su estado más ancho: hora + dos botones) y se ubican con anclas, no con el `RowLayout`. La hora se ancla al botón visible más cercano: la X si no hay nada que expandir, la flecha si la hay. Como el ancho del grupo no cambia, mostrar u ocultar la flecha no reacomoda la fila ni cambia el tamaño del cuerpo, así que el ciclo `truncated` → layout → `truncated` sigue cortado. El espacio sobrante pasa a quedar entre el título y la hora, donde no se nota.

**Verificado:** copia de la config en un bus DBus privado con tres `notify-send` reales (cuerpo corto — el caso que antes congelaba —, largo con flecha, crítica): 0s de CPU, y la captura muestra la hora junto a la X en las cortas y junto a la flecha en la larga.

**Ajuste:** la hora iba con `rightMargin: Theme.spacing` contra el botón, y sumada al aire del círculo de 24px y al margen propio del glifo quedaban ~11px hasta la X. Sin el margen, el círculo del botón hace de separación (~7px).

**Ojo con la recarga:** los archivos que se cargan tarde (como este, que solo se instancia al llegar una notificación) quedan en caché y el vigilante de archivos de `qs` no los recarga al editarlos. La instancia en vivo siguió mostrando la versión vieja hasta forzar una recarga con `touch shell.qml`. Verificado después con `notify-send` reales sobre la instancia en vivo y captura.

## 2026-09-24 — Fix: la shell entera se congelaba al llegar una notificación con cuerpo de una línea

**Archivo:** `widgets/notifications/NotificationContent.qml`

**Síntoma:** después de un `notify-send`, la shell dejaba de responder: el reloj de la barra quedó en 12:30 con la hora real en 12:36, `qs` al 100% de CPU en el hilo principal, y `notify-send` terminaba en `Timeout was reached` porque el servidor nunca contestaba. El log no mostraba nada.

**Causa:** el botón de expandir tenía `visible: body.truncated || root.expanded`. Mostrarlo u ocultarlo reacomodaba la fila del título, eso volvía a dimensionar el cuerpo, y eso cambiaba `truncated` otra vez: un ciclo de polish sin fin dentro de los layouts anidados. Solo pasaba con cuerpos cortos, de una línea. Con cuerpo largo (siempre recortado) o sin cuerpo, el ciclo se estabilizaba. Por eso las pruebas anteriores, con cuerpos largos, no lo agarraron.

**Fix:** el botón queda siempre en el layout y se muestra u oculta con `opacity`/`enabled`, que no tocan el layout. Reserva 24px en la fila del título aunque no se muestre.

**Cómo se encontró** (sin poder engancharse al proceso en vivo: `ptrace_scope = 1`):
- Una copia de la config en un bus de DBus privado (`dbus-run-session --config-file` con un `busconfig` sin `servicedir`, así no arranca portales, y `unix:abstract=` porque la ruta del scratchpad es demasiado larga para un socket) puede ser dueña de `org.freedesktop.Notifications` sin tocar la shell real.
- La copia corrió como proceso hijo de `gdb`, así que se puede inspeccionar. El backtrace después de un `notify-send`: `onNotification` → asignar `popups` → la ventana de toasts se hace visible → `QQuickWindowPrivate::polishItems` → 4 niveles de `QQuickGridLayoutBase::rearrange` → `QQuickText::geometryChange` → `QTextLayout`.
- Bisección con variantes: con y sin acciones, con y sin ícono → se congela igual; cuerpo largo o sin cuerpo → no se congela; quitar el binding de `visible` del botón o el recorte del cuerpo → no se congela.

**Verificado:** en la misma copia con bus privado, cinco `notify-send` que antes congelaban o eran casos borde (cuerpo corto, con acción, con ícono, largo, sin cuerpo): 0s de CPU en todos. Captura: el toast corto con acción, sin flecha de expandir, y el largo con flecha.

**Pendiente del usuario:** la instancia que ya estaba congelada no se recupera sola (el hilo principal no atiende la recarga por cambio de archivo); hay que matarla y volver a arrancar `qs`.

## 2026-09-24 — Toasts con el mismo estilo que el historial

**Archivos:**
- `widgets/notifications/NotificationContent.qml` (nuevo) — el interior de la tarjeta, compartido por toasts e historial
- `widgets/notifications/NotificationToast.qml`, `NotificationHistoryEntry.qml` — ahora solo ponen la tarjeta alrededor de `NotificationContent`
- `panels/NotificationPopups.qml` — posición, separación, se ocultan con la barra lateral abierta
- `components/PopupContainer.qml` — `tint` (color encima de la superficie, dentro del borde)
- `services/Notifications.qml` — la copia del historial guarda también `appName` e `image`

**Cambios:**
- **Un solo diseño:** insignia redonda, título en peso medio, hora, cuerpo recortado a 2 líneas con expandir, cerrar. El toast lo monta sobre un `PopupContainer` (borde en degradado, `Theme.radiusCard`); el historial, sobre una tarjeta lisa. Las críticas van teñidas con `Theme.colors.container` en los dos.
- **Acciones** (solo en toasts, como antes): píldoras que se reparten el ancho, en vez de texto en color acento.
- **Pausa al pasar el mouse:** el timer de auto-cierre se detiene mientras el puntero está encima (`HoverHandler`) y arranca de nuevo completo al salir.
- **Posición:** los toasts estaban en `Theme.mVertical`/`mHorizontal` (4/10) con `ExclusionMode.Ignore`, o sea encima de la barra. Ahora usan los mismos bordes que la barra lateral: debajo de la barra y a `Theme.margins` del borde. Separación entre toasts 4 → 8.
- **Con la barra lateral abierta no se muestran:** ocupan la misma esquina, y el historial ya muestra cada notificación nueva.
- **Insignia, en orden:** una foto adjunta (típicamente un avatar) llena el círculo; si no, ícono de `appIcon`, o el que llega en `image` como `image://icon/<nombre>`, o el del desktop entry de `appName`; si no, un símbolo. Una foto que no carga (`Image.Error`) cae al ícono.

**Medido:** con `notify-send -i kitty`, Quickshell entrega `appIcon=""` e `image="image://icon/kitty"` (log temporal en `onNotification`, ya removido). Por eso antes todas las notificaciones de `notify-send` mostraban el ícono de respaldo.

**Verificado:**
- Tres `notify-send` reales (normal larga, crítica, con dos acciones) contra la instancia en vivo: el log no suma líneas, y como la barra lateral estaba abierta, la captura mostró las tres en el historial con el estilo nuevo (primera prueba real del fix de las copias planas).
- Toasts: captura de una copia de la config con tres notificaciones falsas en `popups` — ícono por `image://icon/kitty`, crítica sin ícono (tinte + `priority_high`), foto (`file://` de un PNG local) + dos acciones. Sin warnings nuevos.

**Sin probar:** clicks reales en acciones/cerrar/expandir; la pausa al pasar el mouse; imágenes que llegan como datos crudos (`image-data`, típico de apps de mensajería) — si su URL deja de resolver cuando la notificación se destruye, el historial cae al ícono.

## 2026-09-24 — Barrita de botones rápidos a todo el ancho

**Archivos:** `widgets/quickSettings/QuickToggles.qml`, `panels/NotificationCenter.qml`

La barrita vuelve a ocupar el mismo ancho que el resto de los bloques (`Layout.fillWidth`) en vez de ajustarse a su contenido. Los círculos siguen siendo de 32px y se reparten de punta a punta: el `spacing` del `RowLayout` se calcula como el ancho sobrante dividido entre los huecos, sumando el `implicitWidth` de los hijos visibles (así no depende de cuántos botones haya). Padding `Theme.pVertical` parejo en los cuatro lados, para que los círculos de las puntas queden tan separados del borde como de arriba y abajo.

**Verificado:** captura con `grim` sobre una copia con el panel abierto; sin warnings nuevos.

## 2026-09-24 — Fix: el historial de notificaciones quedaba en `null` a los 5s + distribución de la referencia

### Fix: historial con referencias muertas

**Archivos:** `services/Notifications.qml`, `widgets/notifications/NotificationHistoryEntry.qml`

**Síntoma:** en la barra lateral, las notificaciones no se podían cerrar ni se veían bien. El log en vivo lo mostraba: `TypeError: Cannot read property 'summary' of null` (y `body`, `id`, `appIcon`, `urgency`) en `NotificationHistoryEntry.qml`, más `Cannot read property 'id' of null` en `removeFromHistory` al tocar la X.

**Causa:** `history` guardaba los objetos `Notification`. Quickshell destruye una notificación apenas se cierra, tenga `tracked` o no, y el toast la cierra solo (`expire()` al vencer su timeout, 5s por defecto). O sea que cada entrada del historial pasaba a `null` a los pocos segundos de llegar. El fix del 2026-09-14 (filtrar por `id`, diferir el untrack con `Qt.callLater`) atacaba un síntoma de esto mismo; la causa era de diseño.

**Fix:** `history` ahora guarda copias planas (`id`, `appIcon`, `summary`, `body`, `urgency`, `time`) tomadas en `onNotification`. `removeFromHistory(id)` recibe el id; si el toast de esa notificación sigue en pantalla, lo cierra. Se van `release()`, el `Qt.callLater` y el mapa `receivedAt` (la hora vive en la copia, `time`). Las entradas rotas que había se fueron con la recarga (el historial no persiste).

**Verificado:** `notify-send` real contra la instancia en vivo; 7s después (toast ya vencido) el log no suma ninguna línea. Antes, cada toast vencido dejaba una tanda de `TypeError`.

### Distribución copiada de la referencia

Pedido: copiar tamaños y distribución de la sidebar de end-4, no sus funciones; donde la referencia tiene un control que acá no existe, un círculo vacío que le guarde el lugar.

**Archivos:** `components/EmptySlot.qml` (nuevo), `widgets/quickSettings/QuickToggle.qml`, `widgets/quickSettings/QuickToggles.qml`, `widgets/notifications/NotificationHistory.qml`, `panels/NotificationCenter.qml`, `config/Theme.qml` (`colors.container`), `config/Settings.qml`

**Cambios:**
- `EmptySlot`: círculo relleno de `muted` al 20%, sin interacción.
- Encabezado: hora sola (se quitó la fecha) + dos `EmptySlot` + apagado, como los tres botones redondos de la referencia.
- Botones rápidos: la barrita ya no ocupa todo el ancho; se ajusta a su contenido y va centrada. Siete círculos de 32px como en la referencia: los cuatro reales + tres `EmptySlot`. `QuickToggle` ahora es directamente un `IconButton` con el aro opcional.
- Notificaciones: fila de pestañas arriba (chip "Notificaciones" + tres `EmptySlot`), tarjetas y pie como antes. Tarjetas críticas con el nuevo `Theme.colors.container`.
- Calendario: riel lateral a la izquierda con "Calendario" (píldora con ícono + etiqueta) y un `EmptySlot` donde iría una segunda vista; la grilla a la derecha.
- `Theme.colors.container` (`clay` al 30%): relleno de acento suave para chips y tarjetas destacadas.
- Medidas: `padding` 16 → 14, `bottomRatio` 0.3 → 0.34 (el calendario de la referencia ocupa ~35% del alto).

**Verificado:** captura con `grim` sobre una copia de la config con el panel abierto y tres copias falsas en `history`; sin warnings nuevos.

## 2026-09-24 — Barra lateral estilizada (referencia: sidebar de end-4 / illogical-impulse)

Adaptación del look de la referencia a la paleta propia, manteniendo los dos popups separados. No se copiaron las funciones que no son estilo (pestañas, To Do, "Silence", uptime).

**Archivos:**
- `components/IconButton.qml` (nuevo) — botón redondo solo-ícono: transparente (o `baseColor`) hasta el hover, relleno de `accent` con ícono `onAccent` cuando `checked`, atenuado si `enabled: false`. El scroll es opt-in (`scrollable`) para no comerse el scroll de una lista.
- `widgets/notifications/NotificationHistory.qml` (nuevo) — lista + estado vacío + pie
- `widgets/notifications/NotificationHistoryEntry.qml` — reescrito como tarjeta
- `widgets/quickSettings/QuickToggle.qml`, `QuickToggles.qml` — sobre `IconButton`
- `widgets/PowerButton.qml` — ahora es un `IconButton`
- `widgets/calendar/MonthCalendar.qml`, `panels/NotificationCenter.qml`
- `components/PopupContainer.qml` — `radius` configurable (antes fijo en `Theme.radius`)
- `components/CardContainer.qml` — radio por defecto `Theme.radiusCard`
- `config/Theme.qml` — `radiusCard: 12`, `radiusPanel: 16`
- `services/Notifications.qml` — `receivedAt` (hora de llegada por id)

**Cambios:**
- **Popups:** radio 16 (`Theme.radiusPanel`), tarjetas internas 12.
- **Encabezado:** hora en peso medio + fecha en español ("Jueves 24 de septiembre", con `Settings.calendar.locale`) + botón de apagado redondo.
- **Botones rápidos:** wifi y bluetooth se rellenan con el acento cuando están prendidos (como en la referencia); volumen y brillo mantienen el aro de nivel, ahora en color acento (en mute: aro `muted`, ícono `error`).
- **Notificaciones:** cada una es una tarjeta con ícono de la app en un círculo, título en peso medio, hora de llegada ("10:40", "Ayer", "22 sep"), cuerpo recortado a 2 líneas con botón de expandir (solo aparece si el texto no entra), y cerrar. Las críticas van con la tarjeta teñida de acento. Sin ícono de app → símbolo `notifications` (o `priority_high` si es crítica), en vez del `dialog-information` que no existe en el tema y dejaba un cuadro vacío. Estado vacío con ícono grande; pie con "N notificaciones" y un botón "Limpiar" con ícono.
- **Calendario:** mes dentro de una píldora (click = volver a hoy), flechas como `IconButton` redondos, ícono `today` cuando se está en otro mes, días de la semana en peso medio, hoy en círculo de acento.

**Hora de llegada:** el `NotificationServer` no guarda timestamp, así que el servicio arma `receivedAt` (id → `Date`) en cada notificación nueva, reconstruido a partir de `history` para que no se acumulen ids de notificaciones ya borradas.

**Verificado:** captura con `grim` sobre una copia de la config con el panel abierto y tres notificaciones falsas inyectadas en `history` (la instancia de prueba no puede registrar el servidor DBus, lo tiene la real): una normal con ícono, una crítica sin ícono y una larga de ayer. Se ven las tres tarjetas con sus horas ("10:40", "10:35", "Ayer"), la crítica teñida con `priority_high`, el chevron solo en la larga, el pie, el encabezado con fecha y el calendario. Sin warnings nuevos; la instancia en vivo recargó bien.

**Sin probar con mouse real:** expandir, cerrar, "Limpiar", flechas y "hoy" del calendario.

## 2026-09-24 — Barra lateral: botones rápidos como círculos con aro, hora más chica, más aire

**Archivos:**
- `widgets/quickSettings/QuickToggle.qml` — reescrito: ahora es un círculo de 32px con solo el ícono y un `RingIndicator` alrededor
- `widgets/quickSettings/QuickToggles.qml` — la fila va dentro de una barrita (`CardContainer` con `radius: height / 2`)
- `components/PopupContainer.qml`, `components/CardContainer.qml` — `padding` único en vez de los cuatro lados fijos; `CardContainer` suma `radius`
- `config/Settings.qml` — `Settings.notificationCenter.padding: 16`, `spacing: 12`
- `config/Theme.qml` — se quita `Theme.font.xlarge` (ya no lo usa nadie)
- `panels/NotificationCenter.qml`, `widgets/calendar/MonthCalendar.qml`

**Cambios:**
- **Botones:** sin texto. El aro dice cuánto está "prendido": volumen y brillo llenan el aro según su nivel (el mismo `RingIndicator` de `VolumeWidget`/`BrightnessWidget`); wifi y bluetooth, aro completo o vacío. Colores como en la barra: `fg` normal, `muted` apagado, `error` para el volumen en mute. La barrita reparte los cuatro círculos en partes iguales.
- **Hora:** `Theme.font.large` (18) en vez de 28.
- **Aire:** los dos popups pasan de 8 a 16 de padding, y los bloques del popup de arriba (hora / botones / notificaciones) de 8 a 12 de separación. El calendario separa encabezado, días y grilla con `Theme.paddings` en vez de `Theme.spacing`. La separación *entre* los dos popups queda en `Theme.margins` (8), igual a `gaps_in`.
- `PopupContainer` y `CardContainer` ahora setean `padding` (propiedad de `Control`) en vez de `leftPadding`/`rightPadding`/`topPadding`/`bottomPadding`: mismo resultado para el app launcher, pero se puede pisar con una sola línea donde se usan.

**Verificado:** capturas con `grim` sobre una copia de la config con el panel abierto — botones, barrita, hora y calendario en su lugar, sin warnings nuevos; y con el brillo puesto en 35% por un `Timer` de prueba, el aro del brillo queda lleno un tercio (restaurado a 400 después).

## 2026-09-24 — Calendario en el popup de abajo de la barra lateral

**Archivos:**
- `widgets/calendar/MonthCalendar.qml` (nuevo)
- `services/Time.qml` — `now` (la fecha como `date`, además de los strings `time`/`date`)
- `config/Settings.qml` — `Settings.calendar.locale: "es_MX"`
- `panels/NotificationCenter.qml` — el calendario llena el popup de abajo; se vuelve al mes actual cada vez que se abre el panel (`onVisibleChanged`)

**Cambios:**
- Mes con `MonthGrid` + `DayOfWeekRow` de QtQuick.Controls, con delegates propios. Encabezado: "Septiembre 2026", flechas `chevron_left`/`chevron_right` y un "Hoy" que solo aparece cuando se navegó fuera del mes actual. Scroll sobre la grilla también cambia de mes.
- Hoy va resaltado con `Theme.colors.selected` (el mismo relleno activo de los botones rápidos); los días de los meses vecinos, atenuados.
- Días de la semana como "Do Lu Ma Mi Ju Vi Sá": los nombres cortos de Qt traen punto ("lun.") y los angostos repiten letra (M/M, S/S).

**Por qué el locale va en `Settings`:** el locale del sistema es `C.UTF-8`, así que sin fijarlo todo sale en inglés. `es_MX` empieza la semana en domingo; `es`/`es_ES`, en lunes (medido con `Qt.locale(...).firstDayOfWeek`).

**Dos roles de `MonthGrid` que no se usan, a propósito:**
- `today`: se calcula una vez por cambio de mes, así que con el shell corriendo pasada la medianoche quedaría marcado el día anterior. Se compara `day`/`month`/`year` contra `Time.now`, que se actualiza cada minuto.
- `date`: la conversión QDate → Date de JS puede caer en el día anterior en zonas horarias al oeste de UTC. Por eso se usan los roles enteros.

**Verificado** (copia de la config con el panel abierto + `Timer` de prueba que avanza un mes): captura con "Septiembre 2026", el 24 resaltado en jueves y el 1 en martes (correcto para 2026), días de agosto/octubre atenuados; tras `shift(1)`, "Octubre 2026" con el "Hoy" visible. Sin warnings nuevos.

**Sin probar con mouse real:** flechas, "Hoy" y scroll (siguen sin herramientas para simular input); se probó `shift()` directo.

## 2026-09-24 — Botones rápidos en la barra lateral: wifi, bluetooth, volumen, brillo

**Archivos:**
- `widgets/quickSettings/QuickToggle.qml` (nuevo) — botón genérico: ícono + etiqueta, `active`, `available`, señales `clicked()` y `scrolled(direction)`
- `widgets/quickSettings/QuickToggles.qml` (nuevo) — la fila de cuatro, conectada a los servicios
- `services/Bluetooth.qml` (nuevo)
- `services/Network.qml` — `wifiEnabled` + `toggleWifi()`
- `services/Brightness.qml` — modo atenuado: `dimmed`, `restoreLevel`, `toggleDim()`
- `panels/NotificationCenter.qml` — la fila va entre la hora/apagado y el cuadro de notificaciones

**Qué hace cada botón:**
- **Wi-Fi:** prende/apaga la radio. Muestra el nombre de la red si está conectado por wifi. Usa `Quickshell.Networking` (NetworkManager por DBus) y no `nmcli`: el estado llega en vivo, sin esperar al poll de 3s.
- **Bluetooth:** prende/apaga el adaptador vía `Quickshell.Bluetooth`. **BlueZ no está instalado** en este sistema (ni el paquete ni el servicio), así que el botón aparece deshabilitado (opacidad 0.4, sin click). Empieza a funcionar solo con `sudo pacman -S bluez bluez-utils && sudo systemctl enable --now bluetooth`. Mientras tanto Quickshell deja un warning por carga: `Failed to create DBusObjectManagerInterface for "org.bluez"`.
- **Volumen:** click = mute, scroll = subir/bajar. Igual que `VolumeWidget`.
- **Brillo:** click = atenuar al mínimo (`Settings.brightness.minimum`) y volver al nivel anterior; scroll = subir/bajar. Si el brillo se mueve por otro lado mientras está atenuado (scroll, media keys), el modo atenuado se cae solo, para que el botón no diga "atenuado" con la pantalla a 50%.

**Estilo:** activo = `Theme.colors.selected` (el mismo relleno del slot enfocado en `WindowsWidget`), inactivo = `Theme.colors.bg` (igual que el cuadro de notificaciones), hover = `Theme.colors.hover`. Los botones no tienen ancho implícito, así que `fillWidth` reparte la fila en partes iguales.

**Verificado** (copia de la config con el panel abierto y un `Timer` de prueba): `wifiEnabled` lee `true` como `nmcli radio wifi`; Bluetooth `available: false`; brillo `400 -> 2` al atenuar, `2 -> 400` al volver, y atenuado + `increase()` da `22` con `dimmed: false`; brillo final restaurado a 400. Capturas con `grim`: los cuatro botones en su lugar, wifi y brillo activos, volumen inactivo (el sistema estaba en mute), bluetooth apagado y deshabilitado.

**Sin probar:** el toggle de wifi en sí — apagar la radio corta la conexión de la sesión que estaba haciendo la prueba. Tampoco clicks ni scroll reales (sigue sin haber `ydotool`/`wtype`/`dotool`).

## 2026-09-24 — Barra lateral: reloj + apagado + cuadro de notificaciones en el popup de arriba

**Archivos:**
- `components/CardContainer.qml` (nuevo)
- `widgets/PowerButton.qml` (nuevo)
- `panels/NotificationCenter.qml`
- `config/Theme.qml` — `Theme.font.xlarge: 28`

**Cambios:**
- Siguen siendo **dos popups separados** (`PopupContainer`, cada uno con su borde en degradado, `Theme.margins` entre ellos). Se probó unirlos en una sola ventana con dos secciones adentro y se descartó: se prefieren separados.
- Popup de arriba: fila con la hora (`Time.time`, `Theme.font.xlarge`) a la izquierda y `PowerButton` a la derecha; debajo, un cuadro (`CardContainer`) con las notificaciones (título, "Limpiar", lista o "Sin notificaciones").
- Popup de abajo: vacío, sigue midiendo `Settings.notificationCenter.bottomRatio`.
- `CardContainer`: `Control` con padding `Theme.paddings`, radio `Theme.edges` y `color` configurable (por defecto `Theme.colors.bg`, que sobre el `surface` del popup da el contraste del cuadro). A diferencia de `PopupContainer`, **no** saca su tamaño implícito de `childrenRect`: sus hijos lo llenan, y medirlos sería el mismo ciclo que tenía `BarContainer`. Lo dimensiona el layout que lo contiene.
- `PowerButton`: mismo patrón que `NotificationCenterButton` (ícono `power_settings_new`). Todavía no hace nada: el `MouseArea` no tiene `onClicked`, solo un TODO para el menú de energía.

**Verificado:** con una copia de la config que abre el panel al arrancar, el panel sigue en `x 1232..1592, y 58..992` y carga sin warnings nuevos. Y esta vez **a ojo**: `grim -g "1232,58 360x934"` funciona sin sudo (lo que decía la entrada del 14/09 ya no vale), y la captura muestra los dos popups separados, con la hora, el botón y el cuadro de notificaciones en el de arriba.

**Observado en la captura:** las superficies son semitransparentes (`surface` al 80%, `bg` al 90%) y sin blur, así que el texto de la ventana de atrás se ve a través del panel. Ya pasaba antes de este cambio.

## 2026-09-24 — Barra lateral dividida en dos tarjetas y alineada con las ventanas

Primer paso para convertir el centro de notificaciones en un centro de configuración.

**Archivos:**
- `panels/NotificationCenter.qml`
- `config/Settings.qml` — `Settings.notificationCenter.bottomRatio: 0.3`

**Cambios:**
- El panel ahora es un `ColumnLayout` con dos `PopupContainer`: arriba uno grande (`fillHeight`, con el contenido de notificaciones que ya estaba) y abajo uno chico, vacío por ahora, que ocupa `bottomRatio` del alto. Separados por `Theme.margins`, el mismo espacio que `gaps_in` deja entre ventanas.
- Márgenes: pasan de `Theme.mHorizontal`/`Theme.mVertical` (10/4) a `Theme.margins` (8), que es el `gaps_out = 8` de `~/.config/hypr/hyprland.lua` y lo que ya usa la barra. El borde de arriba queda en `Theme.margins + Settings.bar.height + Theme.margins`, donde empiezan las ventanas.

**Verificado:** con una copia de la config que abre el panel al arrancar, `hyprctl layers` da el panel en `x 1232..1592, y 58..992` en una pantalla lógica de 1600x1000 (eDP-1 a escala 1.6). Coincide exactamente con el borde exterior de las ventanas en mosaico (`at [10,60]`, `size [1580,930]` más 2px de borde = `8..1592 x 58..992`) y deja 8px contra los bordes derecho e inferior de la pantalla. Sin warnings nuevos.

**Nota:** el contenido del popup de arriba se completó el mismo día — ver entrada siguiente.

## 2026-09-24 — `IDEAS.md` pasa a llamarse `ROADMAP.md`

Renombrado y puesto al día: marcados brillo y apps abiertas como hechos, agregada una sección de pulido de widgets existentes (ícono de brillo, tooltips, agrupar ventanas por app, curva del scroll de brillo) y la falta de herramientas para simular input. Las referencias de entradas anteriores de este changelog apuntan al nombre nuevo, salvo la nota histórica del 2026-09-14 que habla del archivo en sí.

## 2026-09-24 — Fix: binding loop de `implicitWidth` en `BarContainer`

**Archivo:** `components/BarContainer.qml`

**Causa:** el `contentItem` calculaba `implicitWidth: childrenRect.width`, pero sus hijos (las tres secciones de `panels/Bar.qml`) están anclados a los bordes del contenedor (`anchors.right`, `centerIn`). O sea: el ancho implícito dependía de la posición de los hijos, la posición dependía del ancho del contenedor, y ese ancho lo fija el `Control` a partir del ancho implícito. Ciclo cerrado.

**Fix:** se sacó el `implicitWidth` del `contentItem`. La barra no necesita medir su contenido: siempre llena su `PanelWindow` vía `anchors.fill`. `PillContainer` tiene el mismo patrón pero no loopea (su contenido es un `RowLayout` sin anclas a los bordes) y sí necesita medir, así que quedó igual.

**Verificado:** el log de la instancia en vivo muestra el warning al arrancar y ya no tras el hot-reload con el cambio; una instancia de prueba (`qs -p .`) carga sin el warning.

## 2026-09-23 — Panel de apps abiertas (5 slots fijos, orden por recencia)

**Archivos:**
- `services/Windows.qml` (nuevo)
- `widgets/WindowsWidget.qml` (nuevo)
- `config/Settings.qml` — `Settings.windows.limit: 5`
- `panels/Bar.qml` — `WindowsWidget` agregado en la sección central, a la izquierda de `ClockWidget`

**Cambios:**
- `Windows.qml`: singleton sobre `Hyprland.toplevels`. Expone `active` (la ventana enfocada), `recent` (ventanas abiertas, más reciente primero, cortado en `Settings.windows.limit`) y `focus(toplevel)`. Mantiene su propia lista `order` de direcciones por recencia, sembrada desde el `focusHistoryID` de Hyprland y actualizada en cada cambio de foco; `touch()` poda de paso las direcciones de ventanas ya cerradas, así `order` queda acotado por la cantidad de ventanas abiertas en vez de crecer toda la sesión.
- `WindowsWidget.qml`: mismo patrón visual que `WorkspacesWidget` — `PillContainer` + `RowLayout` + `Repeater` de cuadrados de 24x24 con `radius: Theme.edges`, hover, `Behavior on color` y `MouseArea` con `PointingHandCursor`. El `Repeater` va sobre `Settings.windows.limit` (un número), no sobre la lista de ventanas: la cantidad de slots es fija. Ícono vía `IconImage` de 16px; los slots vacíos muestran un punto tenue.

**Por qué los slots son fijos:** el widget vive en la sección centrada del bar. Si el pill creciera y se encogiera con la cantidad de ventanas, el reloj se correría de lugar cada vez que se abre o cierra algo.

**Tres cosas que costaron encontrar:**

1. **`hyprctl dispatch` con la sintaxis clásica no funciona en este sistema, y falla en silencio.** La config de Hyprland acá es Lua (`~/.config/hypr/hyprland.lua`, y Quickshell hasta expone `Hyprland.usingLua`), así que el string que recibe `dispatch` se parsea como Lua: `dispatch("focuswindow address:0x...")` devuelve `')' expected near 'address'`. La forma que sí anda es `hl.dsp.focus({ window = "address:0x<addr>" })` — encontrada probando variantes contra la ventana *ya enfocada*, para no mover el foco mientras se buscaba la sintaxis. El mensaje de error de Hyprland además lista los argumentos válidos: `direction, monitor, window, urgent_or_last, last`.
2. **`wayland.activate()` no sirve para enfocar.** Es el método obvio (`HyprlandToplevel` no tiene ninguno propio, hay que bajar a `toplevel.wayland`), pero el compositor lo ignora: medido, el foco no se movió. Por eso `focus()` usa el dispatcher Lua y no la activación de foreign-toplevel.
3. **`Hyprland.activeToplevel` es `null` hasta el primer evento `activewindow` de la sesión.** O sea que en un arranque limpio no habría ninguna app destacada hasta que el usuario cambiara de ventana. `active` se deriva del flag `wayland.activated` de cada ventana, que sí es correcto desde el primer frame (verificado contra `hyprctl activewindow`).

**Detalle de arranque:** `Hyprland.toplevels` queda vacío hasta que Hyprland responde y nadie lo pide por su cuenta — de ahí el `Hyprland.refreshToplevels()` en `Component.onCompleted` del servicio. Sumado a que los singletons de QML se instancian lazy, esto significa que el primer acceso a `Windows.recent` devuelve una lista vacía; se llena en el frame siguiente.

**Sobre `focusHistoryID`:** es el dato de Hyprland que da la recencia (0 = enfocada ahora, 1 = la anterior). Solo refleja el momento en que se trajo el objeto IPC, así que se usa para *sembrar* el orden inicial (importante: cubre las ventanas que ya estaban abiertas antes de arrancar el shell) y no para mantenerlo. El mantenimiento sale de los cambios de foco propios.

**Verificado en vivo** (foco devuelto a su ventana original al final de cada corrida): `recent` con 3 ventanas en el orden correcto `code / brave-browser / kitty` coincidiendo con el `focusHistoryID` real; los 3 íconos resolviendo vía `DesktopEntries.heuristicLookup()` (`code -> vscode`, `brave-browser -> brave-desktop`, `kitty -> kitty`); `focus()` moviendo el foco de verdad y el MRU reordenándose a `brave-browser / code / kitty`; y con una terminal lanzada al vuelo que se cerraba sola a los 4s, `recent` pasando de 3 a 4 con la nueva ventana en primer lugar y volviendo a 3 al cerrarse, con `order` podado a 1 entrada. El shell completo carga sin warnings nuevos.

**Sin verificar con un click humano:** el `onClicked` de cada slot. Sigue sin haber `ydotool`/`wtype`/`dotool`, así que la prueba llamó `Windows.focus()` directo (que es todo lo que hace el handler). El `MouseArea` es el mismo patrón que `WorkspacesWidget`.

**Decisión de color:** el slot activo usa `Theme.colors.selected` y no `Theme.colors.fg` como hace `WorkspacesWidget`. Ahí funciona porque los números de workspace invierten el color del texto sobre el fondo claro; un ícono de app sobre un fondo casi blanco se lava.

**Pendiente / revisable:** son ventanas, no apps — dos ventanas de VS Code ocupan dos slots. Si se prefiere agrupar por `appId` es un cambio en `recent`. Tampoco hay tooltip con el título (no hay tooltips en ningún widget del shell todavía, queda en `ROADMAP.md`).

## 2026-09-23 — Servicio y widget de brillo (sysfs + udev, sin polling)

**Archivos:**
- `services/Brightness.qml` (nuevo)
- `widgets/BrightnessWidget.qml` (nuevo)
- `config/Settings.qml` — `Settings.brightness.device/step/minimum`
- `panels/Bar.qml` — `BrightnessWidget` agregado entre `NetworkWidget` y `VolumeWidget`

**Cambios:**
- `Brightness.qml`: singleton que expone `raw`/`max` (unidades del dispositivo, este panel va 0-400), `level` (0.0-1.0), `percent`, `ready`, y `setLevel()`/`increase()`/`decrease()`. Lee de `/sys/class/backlight/<device>/` con dos `FileView` y escribe por `brightnessctl`.
- `BrightnessWidget.qml`: mismo patrón que `VolumeWidget` — `PillContainer` con `hoverable`, `RingIndicator` de 16px con `progress: Brightness.level`, porcentaje al lado, y un `MouseArea` con `parent: root`/`z: 1` para el scroll. Sin `onClicked`: el brillo no tiene un toggle equivalente al mute, así que el cursor queda flecha en vez de prometer un click que no hace nada. El paso vive en el servicio (`Settings.brightness.step`) vía `increase()`/`decrease()`, no inline en el widget.

**Tres cosas que salieron de medir, no de suponer:**

1. **Hay dos backlights y `brightnessctl` elige el equivocado.** `intel_backlight` (max 400) y `nvidia_0` (max 100). `brightnessctl -m` sin `-d` devuelve `nvidia_0`, que no es el que maneja el panel. Por eso el dispositivo se nombra en `Settings` en vez de adivinarse, igual que ya hacían los binds de Hyprland.
2. **sysfs no es escribible.** No hay regla udev de backlight en este sistema (`ls /usr/lib/udev/rules.d/ /etc/udev/rules.d/` sin resultados) y `/sys/.../brightness` es `root rw-r--r--`. Leer directo sí; escribir solo por `brightnessctl`, que rutea por logind. Esto descarta el enfoque "`FileView` con `setText`".
3. **`FileView.watchChanges` no sirve acá** — usa inotify, que no dispara en atributos de sysfs. Pero el kernel **sí** emite eventos udev `change` en cada movimiento de brillo: confirmado con `udevadm monitor --udev --subsystem-match=backlight`, y confirmado también que no bufferea al pipearlo (los eventos llegaron con el mismo timestamp que el cambio). Así que el servicio escucha udev con un `Process` + `SplitParser`: cero polling, y agarra también los cambios que hacen las media keys por fuera del shell, que es justo lo que el OSD va a necesitar.

**Dos detalles que costaron un test cada uno:**
- `reload()` es asíncrono. El valor nuevo solo se puede leer dentro de `onLoaded`, no en la línea siguiente al `reload()`.
- Los singletons de QML se instancian lazy, así que `ready` es `false` y `level` es `0` durante el primer frame de lo que sea que se les bindee (medido: el valor real llega ~8ms después del primer acceso). `blockLoading: true` **no** lo arregla — probado, 8ms vs 14ms, y el `0` del primer tick queda igual — así que no quedó en el código: además bloquearía el hilo de UI en cada `reload()` del camino caliente.

**Verificado en vivo** (con el brillo restaurado a su valor original al final de cada corrida): lectura inicial `raw=285`/`max=400`/`level=0.7125`; cambio externo hecho con `brightnessctl` detectado por udev (285 → 286); `increase()`/`decrease()` dando ±20 unidades exactas; 5 `setLevel()` disparados de golpe → `queued=285` observado, gana el último, cola de vuelta en `-1`. El shell completo carga sin warnings nuevos (los dos que quedan son el binding loop previo de `BarContainer.qml[20]` y el registro DBus de notificaciones, que falla solo porque la instancia real ya lo tiene tomado).

**Sin verificar con un scroll humano:** el `onWheel` del widget. No hay `ydotool`/`wtype`/`dotool` en el sistema (misma limitación que con los clicks de las notificaciones), así que la prueba llamó `increase()`/`decrease()` directo. El `MouseArea` es el mismo patrón exacto que ya usa `VolumeWidget`, que está confirmado funcionando.

**Divergencia consciente:** los binds de Hyprland usan `-e4` (curva exponencial) y el servicio escribe valores lineales, así que scrollear en la barra y apretar la media key no mueven lo mismo para el mismo "5%". Quedó lineal para que `setLevel(0.5)` dé `raw == 200` y el anillo no mienta sobre lo que muestra; si se prefiere que coincidan, se cambia pasando porcentajes con `-e4` en `write()`.

**Piso de brillo:** `Settings.brightness.minimum: 2`, espejando el `-n2` de los binds, para que el panel no pueda llegar a negro total.

**Pendiente:** el OSD en sí (queda en `ROADMAP.md`) — el servicio ya emite todo lo que necesita. Y el widget no tiene ícono, así que al lado del de volumen son dos anillos con porcentaje difíciles de distinguir de un vistazo; se resuelve con un `Text` con `brightness_6` de Material Symbols si molesta.

## 2026-09-14 — Fix: no se podía cerrar la barra lateral ni quitar del historial

Dos bugs distintos, los dos diagnosticados con evidencia en vivo (no a ojo).

### 1. No se podía cerrar la barra lateral

**Archivo:** `panels/NotificationCenter.qml`

**Causa:** el panel estaba anclado con `margins.top: Theme.mVertical` (4px), o sea arrancaba en `y=4` — **exactamente donde también vive el bar**. Confirmado con `hyprctl layers`: bar en `y 4..46, x 10..1590` y sidebar en `y 4..996, x 1230..1590`, superponiéndose en todo el sector derecho del bar. Como la superficie del sidebar queda por encima, se comía los clicks destinados al botón de campana que está justo abajo — es decir, el panel tapaba el único botón que podía cerrarlo.

**Fix:** `margins.top: Settings.bar.height + Theme.mVertical * 2`. Verificado: ahora bar `y 4..46` y sidebar `y 50..996`, sin solapamiento.

### 2. El botón de cerrar (x) del historial no funcionaba

**Archivo:** `services/Notifications.qml`

**Causa:** `removeFromHistory()` filtraba por identidad de objeto (`n !== notification`) y después hacía `notification.tracked = false`, que **destruye el QObject en el acto** — mientras el delegate del `ListView` todavía tenía bindings apuntándole. Una entrada cuyo objeto ya fue destruido nunca vuelve a comparar igual a sí misma, así que quedaba clavada en el array para siempre. Medido en el log: la primera remoción andaba (`2 -> 1`) y las siguientes no hacían nada (`1 -> 1`, repetido).

**Fix:**
- El filtro ahora compara por `notification.id` (un `uint` estable) en vez de identidad de objeto, así una referencia muerta igual se puede purgar.
- El `tracked = false` se difiere con `Qt.callLater()` (nueva función `release()`), para que el `ListView` desarme el delegate *antes* de que el objeto se libere.

**Verificado:** tres remociones consecutivas `3 -> 2 -> 1 -> 0`, sin errores ni warnings en el log. Antes del fix, la segunda y la tercera fallaban.

**Método:** para poder invocar las funciones sin un mouse (no hay `ydotool`/`wtype`, y `grim` necesita sudo con contraseña), agregué temporalmente un `IpcHandler` (`qs ipc call notifdebug ...`) que permitió probar `removeFromHistory`/`centerOpen` desde la terminal. Ya fue removido junto con todos los `console.log` de diagnóstico.

## 2026-09-14 — Centro de notificaciones (barra lateral derecha)

**Archivos:**
- `services/Notifications.qml` — agregado `history` (array, tope `Settings.notifications.maxHistory`), `centerOpen`, `removeFromHistory()`, `clearHistory()`
- `widgets/notifications/NotificationHistoryEntry.qml` (nuevo)
- `widgets/NotificationCenterButton.qml` (nuevo)
- `panels/NotificationCenter.qml` (nuevo)
- `config/Settings.qml` — `Settings.notifications.maxHistory: 50`, `Settings.notificationCenter.width: 360`
- `panels/Bar.qml` — `NotificationCenterButton` agregado a la derecha de `BatteryWidget`
- `shell.qml` — registrado `NotificationCenter {}`

**Cambios:**
- `Notifications.qml`: además de `popups` (toasts activos) ahora mantiene `history` (últimas 50, más nueva primero) — se llena en `onNotification`, independiente de cuándo se cierra el toast. `removeFromHistory()`/`clearHistory()` llaman `dismiss()` si la notificación sigue activa como popup, o `tracked = false` si ya estaba cerrada (nunca desde dentro del handler `closed`, para no repetir el bug del loop infinito de la entrada anterior).
- `NotificationHistoryEntry.qml`: fila de lista (`Control` + `hoverEnabled` + `HorizontalSeparator`, mismo patrón que `AppEntry.qml`) con ícono, resumen, cuerpo y botón de cerrar — sin el `Timer` de auto-dismiss ni las acciones (no tienen sentido en un historial).
- `NotificationCenterButton.qml`: pill en el bar (mismo patrón que `AppLauncherButton`), ícono de campana que cambia entre lleno/vacío según si hay historial, toggle de `Notifications.centerOpen` al click.
- `NotificationCenter.qml`: `PanelWindow` anclado `top+right+bottom` (barra lateral de alto completo, no un popup bajo el botón), `exclusionMode: ExclusionMode.Ignore`, `visible` atado directo a `Notifications.centerOpen`. Header con "Limpiar", estado vacío, y `ListView` con `ScriptModel` sobre `Notifications.history` (mismo patrón que `AppLauncher`).

**Verificado en vivo:** con `qs -vv` corriendo, forcé `centerOpen: true` temporalmente con 2 notificaciones de prueba en el historial, confirmé con `hyprctl layers` que la superficie renderiza en `1230,4 360x992` (ancho y alto completo correctos, al lado de la barra `10,4 1580x42`) sin ningún warning nuevo en el log. Revertido el forzado después de confirmar.

**Simplificación consciente:** cuando `history` se recorta a 50 por el `.slice()`, las notificaciones más viejas que se caen del array no se des-trackean explícitamente (quedan vivas en memoria un poco más de lo estrictamente necesario). A este volumen de notificaciones no tiene impacto real; si en algún momento se vuelve un problema, se soluciona iterando los elementos evictados antes del slice.

**Nota aparte:** `IDEAS.md` había vuelto a su versión original en disco (se habían perdido los checks de Settings/Volumen/Notificaciones marcados en sesiones anteriores) — no toqué nada de código por eso, solo reescribí el archivo con el estado real actual.

## 2026-09-14 — Fix real: loop infinito en `Notifications.qml` (2239 llamadas)

Corrí `qs -vv` en primer plano para ver el log real en lugar de seguir adivinando — ahí apareció la causa de verdad (el fix anterior sobre `visible`/`implicitHeight` del `PanelWindow` no era el problema real, aunque tampoco estaba de más).

**Archivo:** `services/Notifications.qml`

**Bug:** después de cerrarse la primera notificación (por timeout o por la X), quedaban "flotando" y nada más volvía a mostrarse.

**Causa real:** dentro del handler de `notification.closed`, hacía `notification.tracked = false`. Eso re-entra al ciclo de cierre de esa misma notificación desde dentro de su propia señal `closed`, que la vuelve a emitir, que vuelve a correr el mismo handler, que vuelve a poner `tracked = false`... El log mostró **2239 emisiones de `closed`** para el mismo id en menos de un segundo, dejando el hilo de QML trabado — por eso ninguna notificación posterior se procesaba y el click en la X tampoco respondía (la app estaba ocupada dando vueltas en ese loop).

**Fix:** se saca `notification.tracked = false` del handler. No hace falta destrackearla ahí — dejar `tracked` en `true` solo significa que Quickshell mantiene el objeto un poco más, sin impacto real a este volumen de notificaciones.

**Verificado en vivo:** dos notificaciones seguidas, cada una se abre, cierra sola a los 5s, y `popups.length` vuelve a 0 sin ninguna repetición — cero warnings, cero loop.

**Bonus, encontrado en el mismo log:**
- `components/PopupContainer.qml`: `implicitWidth/Height: children.implicitWidth/Height` tiraba `Unable to assign [undefined] to double` en cada popup (incluido el `AppLauncher`, no solo notificaciones) — ese binding nunca funcionó, ahora usa `childrenRect.width/height` (mismo patrón ya probado en `PillContainer`/`BarContainer`).
- `widgets/notifications/NotificationToast.qml`: cuando `notify-send` no manda ícono, `Quickshell.iconPath("", "dialog-information")` armaba una URL rota (`?fallback=dialog-information`). Ahora usa `iconPath("dialog-information")` directo si `appIcon` viene vacío.

**Nota pendiente, no relacionada:** sigue apareciendo `Binding loop detected for property "implicitWidth"` en `components/BarContainer.qml[20]` — es previo a todo esto (no lo tocamos hoy), lo dejo anotado por si querés que lo revisemos aparte.

## 2026-09-14 — Fix: solo se veía la primera notificación

**Archivo:** `panels/NotificationPopups.qml`

**Bug:** después de la primera notificación (que sí se mostraba), las siguientes no aparecían.

**Causa:** el `PanelWindow` solo tenía `implicitHeight: column.implicitHeight`, sin `visible` explícito. En cuanto se cerraba la única notificación visible, esa altura caía a 0 — y una superficie layer-shell (Wayland/wlroots, que es lo que usa Hyprland) que llega a 0 de alto suele quedar "desmapeada" por el compositor y no siempre se remapea bien cuando el contenido vuelve a crecer.

**Fix:** `visible: Notifications.popups.length > 0` (atado directo a los datos, no a un tamaño derivado) + `implicitHeight: Math.max(1, column.implicitHeight)` para que nunca llegue a 0 en un frame intermedio.

## 2026-09-14 — Notificaciones vía Quickshell (Pipewire-style daemon propio)

**Archivos:**
- `services/Notifications.qml` (nuevo)
- `widgets/notifications/NotificationToast.qml` (nuevo)
- `panels/NotificationPopups.qml` (nuevo)
- `config/Settings.qml` — `Settings.notifications.width/timeout`
- `shell.qml` — registrado `NotificationPopups {}`

**Cambios:**
- `Notifications.qml`: singleton que instancia `NotificationServer` (`Quickshell.Services.Notifications`) con `keepOnReload: true` para no perder el registro DBus en cada hot-reload. Al llegar una notificación se marca `tracked = true` (si no, Quickshell la destruye apenas el sender la cierra) y se agrega a `popups` (array plano); al cerrarse (`notification.closed`) se saca de la lista y se libera (`tracked = false`) para no filtrar memoria en un proceso que corre indefinidamente.
- `NotificationToast.qml`: un `PopupContainer` por notificación — mismo borde degradado a 45° que ya tienen los demás popups. Ícono de la app, resumen (rojo si `urgency` es Critical), cuerpo con wrap, botón de cerrar y fila de acciones si la notificación las trae. Auto-dismiss vía `Timer` respetando el `expireTimeout` que mande el sender, o `Settings.notifications.timeout` (5s) si no especifica uno; `expireTimeout: 0` = no auto-cierra.
- `NotificationPopups.qml`: un `PanelWindow` nuevo (no el `Bar`) anclado arriba a la derecha, con `exclusionMode: ExclusionMode.Ignore` para que sea un overlay flotante y no reserve espacio de pantalla como el bar. Usa `ScriptModel` sobre `Notifications.popups` (mismo patrón que ya usa `AppLauncher.qml` para su lista de apps) para renderizar la pila de toasts con un `Repeater`.

**Verificación:** no había ningún daemon de notificaciones corriendo ni instalado (`dunst`/`mako`/`swaync`) antes de este cambio, así que no hay conflicto por el registro de `org.freedesktop.Notifications`. Confirmé la API (`Notification`, `NotificationServer`, `PathAngleArc` ya lo había hecho antes) contra los `.qmltypes` reales de Quickshell 0.3.1 instalados en el sistema.

**Pendiente / no cubierto:** historial de notificaciones cerradas (queda en `ROADMAP.md`), imágenes inline (`notification.image`, distinto de `appIcon`), y `sendInlineReply` (notificaciones con respuesta rápida tipo mensajería).

## 2026-09-14 — Widget de Volumen (Pipewire) + RingIndicator

**Archivos:**
- `services/Audio.qml` (nuevo)
- `components/RingIndicator.qml` (nuevo)
- `widgets/VolumeWidget.qml` (nuevo)
- `config/Settings.qml` — `Settings.audio.step: 5` (porcentaje por notch de scroll)
- `panels/Bar.qml` — `VolumeWidget` agregado entre `NetworkWidget` y `BatteryWidget`

**Cambios:**
- `Audio.qml`: singleton sobre `Quickshell.Services.Pipewire` (`Pipewire.defaultAudioSink`), expone `ready`/`muted`/`volume` (0.0-1.0) y `setVolume()`/`toggleMute()`. Usa `PwObjectTracker` para mantener el nodo suscrito (si no, Pipewire no empuja los cambios de volumen/mute).
- `RingIndicator.qml`: componente genérico reutilizable (`components/`, mismo nivel que `VerticalSeparator`/`HorizontalSeparator`) — anillo de progreso hecho con `QtQuick.Shapes`/`PathAngleArc` (mismo módulo que ya usa `PopupContainer` para el borde), con pista tenue (`trackColor` al 35% opacidad) y arco de progreso animado (`Behavior` de 150ms). `progress` se clampea a 1.0 para no dar más de una vuelta con volumen boosteado (>100%).
- `VolumeWidget.qml`: `PillContainer` con el anillo + texto de porcentaje (o "Muted"), color según estado (`Theme.colors.error` si muted, `fg` si no). Interacción: click = toggle mute, scroll = subir/bajar volumen en pasos de `Settings.audio.step`. Sigue el patrón de `AppLauncherButton` para el `MouseArea` (`parent: root`, `hoverable: true`) en vez del patrón puramente informativo de `NetworkWidget`/`BatteryWidget`, porque este sí es interactivo.

**Nota:** no pude levantar Quickshell en este entorno para verlo corriendo en vivo (no hay sesión Wayland/instancia activa acá) — sí verifiqué la API de Pipewire y `PathAngleArc` contra los `.qmltypes` instalados (Quickshell 0.3.1) y contra el `BusyIndicator.qml` de Qt Quick Controls como referencia real de uso. Probalo con un reload y avisame si algo no calza.

## 2026-09-14 — Nuevo config/Settings.qml (separado de Theme.qml)

**Archivos:**
- `config/Settings.qml` (nuevo)
- `panels/Bar.qml`, `components/BarContainer.qml` — usan `Settings.bar.height`
- `widgets/appLauncher/AppLauncher.qml` — usa `Settings.appLauncher.width/height`
- `services/Battery.qml` — `lowThreshold` ahora lee `Settings.battery.lowThreshold`
- `services/Network.qml` — el intervalo del timer lee `Settings.network.pollInterval`

**Cambio:** `Theme.qml` se queda solo con lo visual (colores, fuentes, radios, spacing). Los valores de comportamiento/estructura que estaban sueltos como números mágicos (altura de la barra duplicada en dos archivos, tamaño del popup del launcher, umbral de batería baja, intervalo de polling de red) ahora viven en un singleton `Settings`, mismo patrón que `Theme` (`pragma Singleton`, agrupado por `QtObject` de sección). Cada archivo mantiene su propia property pública (ej. `Battery.lowThreshold`) que ahora simplemente apunta a `Settings`, así no se rompe nada que ya lo estuviera usando.

**Pendiente:** aún falta mover a `Settings` qué widgets se muestran en cada sección del bar (sigue hardcodeado en `panels/Bar.qml`) — ver `ROADMAP.md`.

## 2026-09-14 — PopupContainer: borde en degradado a 45°

**Archivo:** `components/PopupContainer.qml`

**Cambio:** el `fillGradient` del borde pasó de horizontal (`x1:0,y1:0 → x2:width,y2:0`) a diagonal top-left → bottom-right, calculado con `offset = (width + height) / 4` para que el ángulo sea 45° real sin importar el aspect ratio del popup (mismo criterio que usa Hyprland para sus gradientes de borde). En un popup cuadrado esto equivale exactamente a ir de esquina a esquina; en uno rectangular (como el del app launcher, 420x480) la línea se proyecta un poco fuera de la caja en el eje más corto para mantener el ángulo real.

## 2026-09-14 — App launcher: alineación, hover y separadores

**Archivos:**
- `components/HorizontalSeparator.qml` (nuevo)
- `widgets/appLauncher/AppEntry.qml`

**Cambios:**
- Nuevo componente `HorizontalSeparator`, análogo a `VerticalSeparator` pero horizontal: línea tenue (`Theme.colors.muted`, `opacity: 0.35`) con extremos redondeados.
- `AppEntry`: el icono ahora usa `anchors.verticalCenter` igual que el texto, corrigiendo el desalineamiento vertical entre ambos dentro del `Row`.
- `AppEntry`: se activó `hoverEnabled: true` en el `Control` y se agregó un `background` con `Rectangle` (`Theme.colors.hover`, `Theme.radius`) que aparece con una animación de opacidad (120ms) al pasar el mouse — mismo patrón que `PillContainer`.
- `AppEntry`: se agregó un `HorizontalSeparator` anclado al borde inferior de cada entrada (con márgenes `Theme.mHorizontal`) para separar visualmente los ítems de la lista.

**Nota:** el separador se dibuja en todas las entradas, incluida la última (queda una línea tenue justo antes del borde inferior de la lista). No se filtró por índice para evitar tocar el delegate/model de `AppLauncher.qml` sin poder probarlo en vivo.
