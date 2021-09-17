SHELL := /bin/bash
ALEPH_DATABASE_URI ?= postgresql://aleph:aleph@postgres/aleph
ALEPH_POSTGRES_CONTAINER ?= aleph_postgres_1
ALEPH_POSTGRES_USER ?= aleph
ALEPH_POSTGRES_DB ?= aleph

RCLONE_ARCHIVE ?= archive:
RCLONE_REMOTE ?= remote:

START_DATE ?= `date -d "-1 day" "+%Y-%m-%d"`
END_DATE ?= `date "+%Y-%m-%d"`
NOW=`date +"%Y-%m-%dT%H:%M:%S"`

all: getdiff copy

getdiff:
	@mkdir -p state/current
	@echo "exporting postgres ..."
	@docker exec $(ALEPH_POSTGRES_CONTAINER) psql $(ALEPH_POSTGRES_DB) -U $(ALEPH_POSTGRES_USER) -c "copy (select content_hash from document where updated_at >= '$(START_DATE)' and updated_at <= '$(END_DATE)' order by content_hash) to stdout" > state/current/documents
	@echo "storing state data in ./state/current/ ..."
	@while read chash ; do \
			echo $${chash:0:2}/$${chash:2:2}/$${chash:4:2}/$$chash ; \
	done < state/current/documents > state/current/paths

copy:
	@echo "copying `wc -l < state/current/paths` files to $(RCLONE_REMOTE) ..."
	@rclone --progress --config rclone.conf --files-from state/current/paths copy $(RCLONE_ARCHIVE) $(RCLONE_REMOTE)
	mv state/current state/$(NOW)

clean:
	rm -rf state
