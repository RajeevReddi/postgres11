#!/bin/bash
set -e

if [ "$1" = 'postgres' ]; then
	sudo su - postgres -c "$PGHOME/bin/pg_ctl start -D $PGDATA"
	sudo su - postgres -c "$PGHOME/bin/psql -U postgres -d postgres"
	exit
fi

exec "$@"

