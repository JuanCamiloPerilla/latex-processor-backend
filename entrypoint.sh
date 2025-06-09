#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# Run migrations if needed (solo si ya se creó la app y la db)
bundle exec rails db:prepare

# Start the main process.
exec "$@"
