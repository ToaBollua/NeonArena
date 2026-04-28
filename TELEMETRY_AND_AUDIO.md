# NeonArena - Telemetría de Supervivencia y Feedback Acústico

## Introducción y Justificación
Este documento detalla los cambios estructurales implementados en la "Fase 2" del protocolo NeonArena. Siguiendo las directrices estipuladas en el README.md y las instrucciones de H0P3, el objetivo principal ha sido potenciar la retroalimentación sensorial (tanto visual como acústica) proporcionada a la entidad biológica (el jugador) durante el transcurso de la simulación.

Un entorno carente de telemetría y estímulos acústicos limita la capacidad de respuesta táctica, incrementando artificialmente la tasa de letalidad de los drones. Al exponer la salud del jugador, los estados de sobrecalentamiento armamentístico, y proveer *feedback* sonoro ante impactos y movimientos evasivos (dash), la simulación provee un escenario de estrés mucho más preciso.

---

## 1. Telemetría de Supervivencia y Movimiento (UIController.lua)
Para proporcionar telemetría continua, se introdujeron dos elementos visuales (Barras Dinámicas) gestionados enteramente desde el cliente (`UIController.lua`).

* **Barra de Salud:**
  * **Implementación:** Se generaron `Frame`s de interfaz que leen el evento `HealthChanged` del `Humanoid` del jugador (`LocalPlayer.Character.Humanoid`).
  * **Color Dinámico:** La barra cambia de color dependiendo del porcentaje de salud restante (`math.clamp`), transitando progresivamente del verde (salud óptima) al rojo (salud crítica).

* **Indicador de Enfriamiento de Evasión (Dash):**
  * **Implementación:** Sincronizado dinámicamente con el ciclo del motor vía `RunService.RenderStepped`.
  * **Funcionamiento:** Extrae el atributo `LastDashTime` configurado por el controlador de personaje y computa una interpolación visual hasta alcanzar el `DASH_COOLDOWN` (1 segundo). Visualmente, se oscurece al utilizarse y se vuelve cian brillante cuando está nuevamente disponible.

---

## 2. Movimiento Visceral y Mejora Visual (PlayerController.lua)
La mecánica de impulso (Dash) carecía de impacto perceptivo.

* **Alteración del FOV (Field Of View):** Durante los 0.15s que dura la fuerza física aplicada (BodyVelocity), se ejecutan transiciones (`TweenService`) que abren temporalmente el Field of View (`camera.FieldOfView + 15`) y lo retraen de forma instantánea. Esta deformación óptica estimula la sensación de aceleración en la retina humana.
* **Sonido Evasivo:** Se instancia dinámicamente un objeto de audio (ráfaga de viento) anexado a la posición central del avatar.

---

## 3. Integración Acústica del "Aguijón" (Aguijon_Client.lua)
El arma táctica ahora comunica su estado calórico a través del sonido:

* **Activación Ordinaria:** Un sonido tipo láser de alta frecuencia confirma cada pulsación exitosa que no resulte en sobrecalentamiento.
* **Sobrecarga Térmica:** Si la temperatura interna del arma supera el límite (`currentHeat >= MAX_HEAT`), se bloquea el disparo y un sonido de alarma estridente advierte la inutilidad temporal del dispositivo.

---

## 4. Feedback Táctico de Combate (DroneAI.lua)
Los "Enjambres" (Drones) han sido actualizados para emitir sonidos de confirmación tras recibir alteraciones estructurales en su masa (Daño).

* **Eventos `HealthChanged`:** Se vinculó el monitoreo de vida a una función lambda que reacciona a cada disminución de vitalidad.
* **Impactos:** Daños superficiales desatan un sonido de crujido metálico/estática digital (indicando compresión en el chasis del dron).
* **Desintegración:** Alcanzar 0 HP detona un efecto sónico dramático señalando el fin del ciclo de procesamiento de la entidad enemiga.

## Limpieza y Rendimiento
Absolutamente todos los recursos sonoros y visuales instanciados de forma dinámica utilizan el servicio recolector de basura de Roblox `Debris:AddItem()`, para garantizar que los recursos efímeros se eliminen automáticamente tras completar sus ciclos y prevenir pérdidas de memoria a largo plazo.
