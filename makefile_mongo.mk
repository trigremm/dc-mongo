# makefile_mongo.mk
# MongoDB commands (all run inside Docker, no host dependencies)

MONGOSH_URI = mongodb://$${MONGO_ROOT_USERNAME:-admin}:$${MONGO_ROOT_PASSWORD:-adminpass}@mongo:27017/$${MONGO_DATABASE:-appdb}?authSource=admin

.PHONY: mongo-shell mongo-databases mongo-collections mongo-stats mongo-backup mongo-restore mongo-clean-data test

mongo-shell:
	$(DC_BIN) exec mongo mongosh "$(MONGOSH_URI)"

mongo-databases:
	$(DC_BIN) exec mongo mongosh --quiet --eval 'db.adminCommand("listDatabases").databases.forEach(d => print(d.name))' "$(MONGOSH_URI)"

mongo-collections:
	$(DC_BIN) exec mongo mongosh --quiet --eval 'db.getCollectionNames().forEach(print)' "$(MONGOSH_URI)"

mongo-stats:
	$(DC_BIN) exec mongo mongosh --quiet --eval 'printjson(db.stats())' "$(MONGOSH_URI)"

mongo-backup:
	$(DC_BIN) run --rm mongo-backup

mongo-restore:
	@test -n "$(RESTORE_DIR)" || (echo "Usage: make mongo-restore RESTORE_DIR=dump_appdb_20240101_120000" && exit 1)
	$(DC_BIN) exec mongo mongorestore \
		--username=$${MONGO_ROOT_USERNAME:-admin} \
		--password=$${MONGO_ROOT_PASSWORD:-adminpass} \
		--authenticationDatabase=admin \
		--db=$${MONGO_DATABASE:-appdb} \
		/backups/$(RESTORE_DIR)/$${MONGO_DATABASE:-appdb}

mongo-clean-data:
	@test "$(CONFIRM)" = "1" || (echo "Run with CONFIRM=1 to wipe data" && exit 1)
	$(DC_BIN) down -v
	rm -rf .docker_volumes/mongo/*

test:
	@echo "Starting mongo..."
	$(DC_BIN) up -d
	@echo "Waiting for healthcheck..."
	@for i in 1 2 3 4 5 6; do \
		$(DC_BIN) exec mongo mongosh --quiet --eval 'db.runCommand("ping").ok' "$(MONGOSH_URI)" 2>/dev/null && break || sleep 5; \
	done
	@echo "Test ping..."
	$(DC_BIN) exec mongo mongosh --quiet --eval 'db.runCommand("ping").ok' "$(MONGOSH_URI)" | grep -q 1 && echo "PASS: ping" || (echo "FAIL: ping" && exit 1)
	@echo "Test insert/find..."
	$(DC_BIN) exec mongo mongosh --quiet --eval 'db.test_col.insertOne({k:"v"}); r=db.test_col.findOne({k:"v"}); print(r.k); db.test_col.drop()' "$(MONGOSH_URI)" | grep -q v && echo "PASS: insert/find" || (echo "FAIL: insert/find" && exit 1)
	@echo ""
	@echo "All tests passed!"
