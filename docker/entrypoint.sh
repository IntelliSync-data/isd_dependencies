#!/bin/bash
set -euo pipefail

if [ -v PASSWORD_FILE ]; then
    PASSWORD="$(< "$PASSWORD_FILE")"
fi

: "${HOST:=${DB_PORT_5432_TCP_ADDR:=${PGHOST:=db}}}"
: "${PORT:=${DB_PORT_5432_TCP_PORT:=${PGPORT:=5432}}}"
: "${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:=${PGUSER:=odoo}}}}"
: "${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:=${PGPASSWORD:=odoo}}}}"
: "${ODOO_DB:=isd}"

missing=0
for manifest in \
    /mnt/extra-addons/isd_marketing/isd_marketing_template/__manifest__.py \
    /mnt/extra-addons/openeducat/openeducat_core/__manifest__.py
do
    if [ ! -f "$manifest" ]; then
        echo "ERROR: missing ${manifest}" >&2
        missing=1
    fi
done
if [ "$missing" -ne 0 ]; then
    echo "ERROR: nested addons are empty. On the host run:" >&2
    echo "  git submodule update --init --recursive" >&2
    exit 1
fi

DB_ARGS=(--db_host "$HOST" --db_port "$PORT" --db_user "$USER" --db_password "$PASSWORD")

wait-for-psql.py "${DB_ARGS[@]}" --timeout=30

db_exists="$(PGPASSWORD="$PASSWORD" psql -h "$HOST" -p "$PORT" -U "$USER" -d postgres -tAc \
    "SELECT 1 FROM pg_database WHERE datname='${ODOO_DB}'" || true)"

if [ "$db_exists" != "1" ]; then
    echo "Initializing database ${ODOO_DB} (base only, no ISD modules)..."
    odoo -d "$ODOO_DB" -i base --without-demo=all --stop-after-init --no-http "${DB_ARGS[@]}"
    echo "Refreshing module list..."
    echo "env['ir.module.module'].update_list(); env.cr.commit()" \
        | odoo shell -d "$ODOO_DB" --no-http "${DB_ARGS[@]}"
fi

if [ "${1:-}" = "--" ] || [ "${1:-}" = "odoo" ]; then
    shift
fi

exec odoo -d "$ODOO_DB" --db-filter="^${ODOO_DB}$" --dev=xml,reload,qweb \
    "$@" "${DB_ARGS[@]}"
