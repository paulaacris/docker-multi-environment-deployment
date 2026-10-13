ENV ?= dev 
WEB_DIR = web
VENV = $(WEB_DIR)/.venv
PIP = $(VENV)/bin/pip

# for local testing 
setup:
	@echo Creando el entorno virtual en $(WEB_DIR)...
	python3 -m venv $(VENV)
	@echo "Actualizando pip e instalando dependencias..."
	$(PIP) install -r $(WEB_DIR)/requirements.txt

up: 
	docker compose -p practica-$(ENV) -f docker-compose.$(ENV).yml --env-file .env.$(ENV) up -d --build

up-dev:
	$(MAKE) up ENV=dev

down: 
	docker compose -p practica-$(ENV) -f docker-compose.$(ENV).yml --env-file .env.$(ENV) down

down-dev:
	$(MAKE) down ENV=dev