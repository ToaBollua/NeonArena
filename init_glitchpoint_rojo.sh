#!/bin/bash
# ==============================================================================
# UNIDAD        : UOA-B1 'Proxy'
# ESTADO        : Serie Beta - Operativa
# OBJETIVO      : Despliegue de estructura de archivos Rojo (GlitchPoint Studios)
# ==============================================================================

# Definir directorio del proyecto (Usa el directorio actual si no se pasa argumento)
PROJECT_DIR=${1:-"$(pwd)/glitchpoint_project"}

echo "[UOA-B1] Iniciando despliegue de arquitectura en: $PROJECT_DIR"

# Crear directorio raíz si no existe
if [ ! -d "$PROJECT_DIR" ]; then
    mkdir -p "$PROJECT_DIR"
    echo "[UOA-B1] Directorio raíz establecido."
fi

cd "$PROJECT_DIR" || { echo "[UOA-B1] ERROR CRÍTICO: Imposible acceder al directorio."; exit 1; }

# Generar estructura de directorios
echo "[UOA-B1] Forjando sectores de datos..."
mkdir -p src/{server,client,shared}
mkdir -p src/server/{Services,Modules}
mkdir -p src/client/{Controllers,UI,Modules}
mkdir -p src/shared/{Utils,Constants}

# Generar nodos físicos (Archivos .luau)
echo "[UOA-B1] Instanciando nodos físicos vacíos..."
touch src/server/Main.server.luau
touch src/client/Main.client.luau
touch src/shared/Constants/Config.luau

# Ejecutar Rojo si el mapeo JSON no existe
if [ ! -f "default.project.json" ]; then
    echo "[UOA-B1] Archivo de configuración ausente. Forzando 'rojo init'..."
    rojo init > /dev/null 2>&1
    echo "[UOA-B1] Mapeo de proyecto generado."
else
    echo "[UOA-B1] Archivo default.project.json detectado. Omitiendo inicialización."
fi

echo "[UOA-B1] Operación finalizada. Sistema de archivos sincronizado y listo para inserción de código."
echo "[UOA-B1] Comando sugerido: cd $PROJECT_DIR && rojo serve"
