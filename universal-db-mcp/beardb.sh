#!/usr/bin/env bash
# Usage: source beardb.sh
# Creates a bear-db session and defines the beardb() function in your current shell.

_BEARDB_SESSION=$(curl -s -X POST http://localhost:8088/api/connect \
  -H "Content-Type: application/json" \
  -d '{"type":"mysql","host":"mysql","port":3306,"user":"bear_development","password":"bear","database":"bear3_development"}' \
  | jq -r '.data.sessionId')

if [ -z "$_BEARDB_SESSION" ] || [ "$_BEARDB_SESSION" = "null" ]; then
  echo "beardb: failed to connect to bear-db MCP server" >&2
  return 1 2>/dev/null || exit 1
fi

echo "beardb: session started ($_BEARDB_SESSION)"

beardb() {
  curl -s -X POST http://localhost:8088/api/query \
    -H "Content-Type: application/json" \
    -d "{\"sessionId\":\"$_BEARDB_SESSION\",\"query\":\"$1\"}" | jq '.data'
}

export -f beardb
