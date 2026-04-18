# NeonArena 🦾

![NeonArena](https://via.placeholder.com/800x200?text=NeonArena+-+Cyberpunk+Combat)

Un shooter de arena en primera persona con estética cyberpunk, desarrollado para la plataforma Roblox. Enfocado en mecánicas de combate fluido, IA reactiva y sistemas de armas con gestión térmica.

## 🚀 Logros del Proyecto

Actualmente, el núcleo del sistema de combate y la lógica de oleadas están plenamente operativos:

- **Movimiento Avanzado**: Sistema WASD responsivo con rotación sincronizada y salto calibrado.
- **Arma "Aguijón"**:
    - Disparo preciso mediante Raycast.
    - Sistema de sobrecalentamiento y enfriamiento reactivo.
    - Comunicación cliente-servidor optimizada para detección de daño.
- **IA de Drones**: Enemigos autónomos con persecución activa y efectos de muerte (fading).
- **Control de Oleadas**: Motor de generación configurable con conteo de entidades y transiciones dinámicas.
- **Interfaz (UI)**: Punto de mira central, barras de estado térmico y contadores de oleada.

## 📂 Estructura del Repositorio

- `scripts/`: Lógica central del juego (Lua).
    - `Aguijon_Client.lua`: Lógica de disparo y efectos locales.
    - `Aguijon_Server.lua`: Validación de daño y estado del servidor.
    - `DroneAI.lua`: Comportamiento de los enemigos.
    - `PlayerController.lua`: Entrada del jugador y cámara.
    - `UIController.lua`: Gestión de interfaces y retroalimentación visual.
    - `WaveSpawner.lua`: Motor de oleadas.

## 🛠 Próximos Pasos

1. [ ] Implementación de salud del jugador y daño de drones.
2. [ ] Condiciones de fin de partida (Victoria/Derrota).
3. [ ] Integración de modelos visuales detallados para el arma "Aguijón".
4. [ ] Sistema de sonido inmersivo.
5. [ ] Expansión y detallado de la Arena de combate.

---

> [!NOTE]
> Este repositorio contiene exclusivamente la lógica en scripts. El archivo de construcción `.rbxl` no está incluido actualmente.
