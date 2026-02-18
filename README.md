# dc-mongo

MongoDB 7.0 + Mongo Express (web UI on port 8081).

> **Note:** Using MongoDB 7.0 for stability. Latest available: 7.0.30-jammy.

## Quick start

```bash
cp .env.sample .env
vim .env
make up
```

## Commands

### Lifecycle

```
make d          # deploy (git pull + recreate)
make r          # recreate (build + stop + up)
make up         # start
make stop       # stop
make down       # stop and remove
make ps         # status
make l          # follow logs
```

### MongoDB

All commands run inside Docker — no host dependencies required.

```
make mongo-shell          # open mongosh session
make mongo-databases      # list databases
make mongo-collections    # list collections
make mongo-stats          # database stats
make mongo-backup         # mongodump to .docker_volumes/backups/
make mongo-restore RESTORE_DIR=dump_appdb_20240101_120000
make mongo-clean-data CONFIRM=1   # wipe all data
make test                 # run smoke tests (ping, insert/find)
```

## Mongo Express

Open http://localhost:8081 — web UI for database management.

## Backups

Backups are created via a separate Docker container (`mongo-backup`) using `mongodump`.
Files are stored in `.docker_volumes/backups/`.
