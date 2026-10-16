ENV ?= dev
WEB_DIR = web
VENV = $(WEB_DIR)/.venv
PIP = $(VENV)/bin/pip
PORT = $(shell grep '^WEB_PORT=' .env.$(ENV) | cut -d= -f2)

# docker compose base command
DC = docker compose -p practica-$(ENV) -f docker-compose.$(ENV).yml --env-file .env.$(ENV)

# for local testing 
virtual-env:
	@echo Creando el entorno virtual en $(WEB_DIR)...
	python3 -m venv $(VENV)
	@echo "Actualizando pip e instalando dependencias..."
	$(PIP) install -r $(WEB_DIR)/requirements.txt

up: 
	$(DC) up -d --build
	@echo "Listo: http://localhost:$(PORT)"

down: 
	$(DC) down

# show db content (table favoritos)
show-db: 
	$(DC) exec db sh -c 'mysql -u $$MYSQL_USER -p"$$MYSQL_PASSWORD" $$MYSQL_DATABASE -e "SELECT * FROM favoritos;"'

# show vol content (table favoritos)
show-vol:
	$(DC) exec db ls -la /var/lib/mysql

# add content to the db
add-db:
	$(DC) exec db sh -c 'mysql -u $$MYSQL_USER -p"$$MYSQL_PASSWORD" $$MYSQL_DATABASE -e "INSERT INTO favoritos (nombre) VALUES (\"Snorlax\"), (\"Charmander\"), (\"Squirtle\");"'

# shut down only db 
stop-db:
	$(DC) stop db

# start only db
start-db:
	$(DC) start db

# show caché content
show-cache:
	docker compose -p practica-$(ENV) -f docker-compose.$(ENV).yml --env-file .env.$(ENV) exec cache sh -c 'redis-cli -a "$$REDIS_PASSWORD" --no-auth-warning GET favoritos'

# Apagar solo la caché
stop-cache:
	$(DC) stop cache

# Volver a encender la caché
start-cache:
	$(DC) start cache

# pattern 
%-dev:
	$(MAKE) $* ENV=dev

%-prod:
	$(MAKE) $* ENV=prod