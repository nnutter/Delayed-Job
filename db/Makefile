.PHONY = db

USERNAME ?= nnutter

db:
	@psql --username=$(USERNAME) --file=db.sql
	@psql --username=$(USERNAME) --file=schema.sql delayed
