ENV ?= dev
WEB_DIR = web
VENV = $(WEB_DIR)/.venv
PIP = $(VENV)/bin/pip
PORT = $(shell grep '^WEB_PORT=' .env.$(ENV) | cut -d= -f2)

# for local testing 
virtual-env:
	@echo Creando el entorno virtual en $(WEB_DIR)...
	python3 -m venv $(VENV)
	@echo "Actualizando pip e instalando dependencias..."
	$(PIP) install -r $(WEB_DIR)/requirements.txt

up: 
	docker compose -p practica-$(ENV) -f docker-compose.$(ENV).yml --env-file .env.$(ENV) up -d --build
	@echo "Listo: http://localhost:$(PORT)"

up-dev:
	$(MAKE) up ENV=dev

up-prod:
	$(MAKE) up ENV=prod

down: 
	docker compose -p practica-$(ENV) -f docker-compose.$(ENV).yml --env-file .env.$(ENV) down

down-dev:
	$(MAKE) down ENV=dev

down-prod:
	$(MAKE) down ENV=prod

# show db content (table favoritos)
show-db: 
	docker compose -p practica-$(ENV) -f docker-compose.$(ENV).yml exec db sh -c 'mysql -u $$MYSQL_USER -p"$$MYSQL_PASSWORD" $$MYSQL_DATABASE -e "SELECT * FROM favoritos;"'

show-db-dev:
	$(MAKE) show-db ENV=dev

show-db-prod:
	$(MAKE) show-db ENV=prod

# show vol content (table favoritos)
show-vol:
	docker compose -p practica-$(ENV) -f docker-compose.$(ENV).yml exec db ls -la /var/lib/mysql

show-vol-dev:
	$(MAKE) show-vol ENV=dev

show-vol-prod:
	$(MAKE) show-vol ENV=prod

# add content to the db
add-db:
	docker compose -p practica-$(ENV) -f docker-compose.$(ENV).yml exec db sh -c 'mysql -u $$MYSQL_USER -p"$$MYSQL_PASSWORD" $$MYSQL_DATABASE -e "INSERT INTO favoritos (nombre) VALUES (\"Snorlax\"), (\"Charmander\"), (\"Squirtle\");"'

add-db-dev:
	$(MAKE) add-db ENV=dev

add-db-prod:
	$(MAKE) add-db ENV=prod

# shut down only db 
stop-db:
	docker compose -p practica-$(ENV) -f docker-compose.$(ENV).yml --env-file .env.$(ENV) stop db

stop-db-dev:
	$(MAKE) stop-db ENV=dev

stop-db-prod:
	$(MAKE) stop-db ENV=prod

# start only db
start-db:
	docker compose -p practica-$(ENV) -f docker-compose.$(ENV).yml --env-file .env.$(ENV) start db

start-db-dev:
	$(MAKE) start-db ENV=dev

start-db-prod:
	$(MAKE) start-db ENV=prod