WEB_DIR = web
VENV = $(WEB_DIR)/.venv
PIP = $(VENV)/bin/pip

setup:
	@echo Creando el entorno virtual en $(WEB_DIR)...
	python3 -m venv $(VENV)
	@echo "Actualizando pip e instalando dependencias..."
	$(PIP) install -r $(WEB_DIR)/requirements.txt