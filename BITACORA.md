  Bitácora de Desarrollo - NeonArena

  Logro Actual:

   * Estructura del Proyecto: Carpeta /workspace/NeonArena creada, scripts
     organizados.
   * Controlador de Jugador:
       * Movimiento WASD personalizado y responsivo.
       * Rotación del personaje sincronizada con la cámara.
       * Salto corregido (sin vuelo infinito).
       * Vista en primera persona forzada.
   * Sistema de Armas ("Aguijón"):
       * Modelo base con Handle y Muzzle configurados.
       * Disparo con raycast (impacto preciso).
       * Efecto visual de pulso de energía verde.
       * Sistema de daño al dron (comunicación cliente-servidor segura).
       * Mecánica de sobrecalentamiento implementada (genera calor, se bloquea al
         máximo, se enfría).
   * Sistema de Enemigos (Drones):
       * IA básica de persecución.
       * Salud (Humanoid) y detección de muerte.
       * Efecto de desvanecimiento al morir.
   * Sistema de Oleadas (WaveSpawner):
       * Generación de drones en oleadas configurables.
       * Conteo de drones vivos por oleada.
       * Transición entre oleadas.
       * Rutina de "calentamiento" para evitar tirones en la primera muerte.
   * Interfaz de Usuario (UI):
       * Punto de mira centralizado (se oculta al apuntar).
       * Contador de oleada y drones restantes en pantalla.
       * Barra de sobrecalentamiento del arma.

  Próximos Pasos (Orden de Prioridad Actual):

   1. Salud del Jugador y Ataque del Dron: Implementar la lógica para que los drones
       puedan dañar al jugador y reducir su salud.
   2. Condiciones de Victoria/Derrota: Definir qué sucede cuando el jugador pierde
      toda la salud o cuando completa todas las oleadas.
   3. Modelo Visual del Arma: Reemplazar el modelo de bloques del "Aguijón" por un
      diseño visual más elaborado y acorde a la estética cyberpunk.
   4. Efectos de Sonido: Añadir audio para disparos, impactos, muerte de drones,
      sobrecalentamiento, etc.
   5. Expansión de la Arena: Diseñar un mapa más complejo con obstáculos y elementos
       interactivos.
