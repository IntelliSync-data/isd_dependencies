.PHONY: help init build up start stop down logs ps shell install reset

COMPOSE := docker compose
WEB     := web
DB      := $(or $(ODOO_DB),isd)
MODULE  ?=

help:
	@echo "Targets:"
	@echo "  make init              git submodules + .env from example"
	@echo "  make up                build and start (detached, wait healthy)"
	@echo "  make start             start without rebuild"
	@echo "  make stop              stop, keep volumes"
	@echo "  make down              stop containers"
	@echo "  make logs               follow web logs"
	@echo "  make ps                 compose status"
	@echo "  make shell              odoo shell on \$$ODOO_DB ($(DB))"
	@echo "  make install MODULE=x   odoo -i MODULE --stop-after-init"
	@echo "  make reset              down -v then up (destroys DB + filestore)"
	@echo "  make build              image only"

init:
	git submodule update --init --recursive
	@test -f .env || cp .env.example .env
	@test -f addons/isd_marketing/isd_marketing_template/__manifest__.py
	@test -f addons/openeducat/openeducat_core/__manifest__.py

build:
	$(COMPOSE) build

up: init
	$(COMPOSE) up --build -d --wait

start:
	$(COMPOSE) up -d --wait

stop:
	$(COMPOSE) stop

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f $(WEB)

ps:
	$(COMPOSE) ps

shell:
	$(COMPOSE) exec $(WEB) odoo shell -d $(DB) --no-http \
		--db_host db --db_user odoo --db_password odoo

install:
	@test -n "$(MODULE)" || { echo "usage: make install MODULE=isd_menu"; exit 1; }
	$(COMPOSE) exec $(WEB) odoo -d $(DB) -i $(MODULE) \
		--stop-after-init --no-http \
		--db_host db --db_user odoo --db_password odoo

reset:
	$(COMPOSE) down -v
	$(COMPOSE) up --build -d --wait
