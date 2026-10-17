ENV ?= dev
WEB_DIR = web
VENV = $(WEB_DIR)/.venv
PIP = $(VENV)/bin/pip
PORT = $(shell grep '^WEB_PORT=' .env.$(ENV) | cut -d= -f2)

# docker compose base command
DC = docker compose -p practica-$(ENV) -f docker-compose.$(ENV).yml --env-file .env.$(ENV)

setup: 
	@echo "Checking Docker requirements..."
	@command -v docker >/dev/null 2>&1 || { echo >&2 "Error: Docker no está instalado."; exit 1; }
	@docker info >/dev/null 2>&1 || { echo >&2 "Error: Docker no está en ejecución."; exit 1; }

	@echo "Verifying environment files(.env)..."
	@if [ ! -f .env.dev ]; then echo "WEB_PORT=5000\nDB_HOST=db\nMYSQL_USER=user\nMYSQL_PASSWORD=pass\nMYSQL_DATABASE=pokedex\nMYSQL_ROOT_PASSWORD=root" > .env.dev; echo ".env.dev creado con valores por defecto."; fi
	@if [ ! -f .env.prod ]; then echo "WEB_PORT=8080\nDB_HOST=db\nMYSQL_USER=user\nMYSQL_PASSWORD=pass\nMYSQL_DATABASE=pokedex\nMYSQL_ROOT_PASSWORD=root\nREDIS_HOST=cache\nREDIS_PASSWORD=redispass" > .env.prod; echo ".env.prod creado con valores por defecto."; fi

	@echo "Setting permissions on .env files..."
	@chmod 600 .env.dev .env.prod

	@echo "Setup complete. Start with 'make up-dev' or 'make up-prod'."

build:
	$(DC) build

up: 
	@chmod 600 .env.$(ENV)
	$(DC) up -d --build
	@echo "Listo: http://localhost:$(PORT)"

# healthy 
ps: 
	docker ps --format "table {{.Names}}\t{{.Status}}"

status:
	curl http://localhost:$(PORT)/status

favoritos:
	curl http://localhost:8080/favoritos

check-ports:
	docker ps --format "table {{.Names}}\t{{.Ports}}"
	-nc -zv localhost 5000
	-nc -zv localhost 8080
	-nc -zv localhost 3306
	-nc -zv localhost 6379

down: 
	$(DC) down

# show db content (table favoritos)
show-db: 
	$(DC) exec db sh -c 'mysql -u $$MYSQL_USER -p"$$MYSQL_PASSWORD" $$MYSQL_DATABASE -e "SELECT * FROM favoritos;"'

# show vols in docker
show-vol:
	docker volume ls

clean: 
	$(DC) down -v

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