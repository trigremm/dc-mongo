.PHONY: up stop down logs ps build restart shell backup restore status indexes collections stats

# ──── Lifecycle ────────────────────────────────────────────────
up:
	docker compose up -d

stop:
	docker compose stop

down:
	docker compose down

restart:
	docker compose restart

build:
	docker compose build

r: stop up  ## recreate

logs:
	docker compose logs -f mongo

logs-express:
	docker compose logs -f mongo-express

ps:
	docker compose ps -a

# ──── Interactive Shell ────────────────────────────────────────
shell:  ## mongosh into the database
	docker compose run --rm mongosh

# ──── Backup / Restore ─────────────────────────────────────────
backup:  ## dump database to ./backups/
	@mkdir -p backups
	docker compose run --rm mongo-backup

restore:  ## restore from RESTORE_DIR=dump_YYYYMMDD_HHMMSS
	@test -n "$(RESTORE_DIR)" || (echo "Usage: make restore RESTORE_DIR=dump_20240101_120000" && exit 1)
	RESTORE_DIR=$(RESTORE_DIR) docker compose run --rm mongo-restore

# ──── Useful Queries (via mongosh) ─────────────────────────────
status:  ## rs.status() / server status
	docker compose exec mongo mongosh --quiet --eval 'db.serverStatus().connections' \
		"mongodb://$$(grep MONGO_ROOT_USERNAME .env | cut -d= -f2):$$(grep MONGO_ROOT_PASSWORD .env | cut -d= -f2)@localhost:27017/admin"

collections:  ## list all collections in appdb
	docker compose exec mongo mongosh --quiet --eval 'db.getCollectionNames()' \
		"mongodb://$$(grep MONGO_ROOT_USERNAME .env | cut -d= -f2):$$(grep MONGO_ROOT_PASSWORD .env | cut -d= -f2)@localhost:27017/$$(grep MONGO_DATABASE .env | cut -d= -f2)?authSource=admin"

indexes:  ## show indexes for all collections
	docker compose exec mongo mongosh --quiet --eval 'db.getCollectionNames().forEach(c => { print("--- " + c); printjson(db[c].getIndexes()) })' \
		"mongodb://$$(grep MONGO_ROOT_USERNAME .env | cut -d= -f2):$$(grep MONGO_ROOT_PASSWORD .env | cut -d= -f2)@localhost:27017/$$(grep MONGO_DATABASE .env | cut -d= -f2)?authSource=admin"

stats:  ## db stats (size, counts)
	docker compose exec mongo mongosh --quiet --eval 'printjson(db.stats())' \
		"mongodb://$$(grep MONGO_ROOT_USERNAME .env | cut -d= -f2):$$(grep MONGO_ROOT_PASSWORD .env | cut -d= -f2)@localhost:27017/$$(grep MONGO_DATABASE .env | cut -d= -f2)?authSource=admin"

# ──── Cleanup ──────────────────────────────────────────────────
clean-data:  ## ⚠️  wipe mongo data (requires CONFIRM=1)
	@test "$(CONFIRM)" = "1" || (echo "Run with CONFIRM=1 to wipe data" && exit 1)
	docker compose down -v
	rm -rf docker_volumes/mongo/mongo_data/*

# ──── Help ─────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  dc-mongo — MongoDB dev environment"
	@echo ""
	@echo "  Lifecycle:"
	@echo "    make up         Start mongo + mongo-express"
	@echo "    make stop       Stop containers"
	@echo "    make down       Stop and remove containers"
	@echo "    make r          Recreate (stop + up)"
	@echo "    make logs       Follow mongo logs"
	@echo "    make ps         Container status"
	@echo ""
	@echo "  Tools:"
	@echo "    make shell      Open mongosh session"
	@echo "    make backup     Dump database to ./backups/"
	@echo "    make restore    Restore: make restore RESTORE_DIR=dump_..."
	@echo ""
	@echo "  Queries:"
	@echo "    make status       Server connection status"
	@echo "    make collections  List collections"
	@echo "    make indexes      Show all indexes"
	@echo "    make stats        Database size/counts"
	@echo ""
	@echo "  Danger:"
	@echo "    make clean-data CONFIRM=1  Wipe all data"
	@echo ""
