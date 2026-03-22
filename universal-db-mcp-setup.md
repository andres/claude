# universal-db-mcp — Bear DB Setup

Docker files: `/home/andres/code/claude/universal-db-mcp/`

Runs the [universal-db-mcp](https://github.com/Anarkh-Lee/universal-db-mcp) HTTP server on port **8088**, connected to the bear MariaDB via the `bear_default` Docker network.

## Start / stop

```bash
cd /home/andres/code/claude/universal-db-mcp
docker compose up -d      # start
docker compose down       # stop
```

Bear's docker compose must be running first (provides the `bear_default` network and `mysql` service).

## claude_desktop_config.json

Add to `~/.config/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "bear-db": {
      "type": "sse",
      "url": "http://localhost:8088/sse"
    }
  }
}
```

Or using Streamable HTTP (recommended):

```json
{
  "mcpServers": {
    "bear-db": {
      "type": "http",
      "url": "http://localhost:8088/mcp",
      "headers": {
        "X-DB-Type": "mysql",
        "X-DB-Host": "mysql",
        "X-DB-Port": "3306",
        "X-DB-User": "bear_development",
        "X-DB-Password": "bear",
        "X-DB-Database": "bear3_development",
        "X-DB-Permission-Mode": "safe"
      }
    }
  }
}
```

## REST API (direct use)

```bash
# Connect and get a session
SESSION=$(curl -s -X POST http://localhost:8088/api/connect \
  -H "Content-Type: application/json" \
  -d '{"type":"mysql","host":"mysql","port":3306,"user":"bear_development","password":"bear","database":"bear3_development"}' \
  | jq -r '.data.sessionId')

# Query
curl -s -X POST http://localhost:8088/api/query \
  -H "Content-Type: application/json" \
  -d "{\"sessionId\":\"$SESSION\",\"query\":\"SELECT ...\"}"

# List tables
curl -s "http://localhost:8088/api/tables?sessionId=$SESSION"

# Health check
curl http://localhost:8088/api/health
```

## Connection details

| Field    | Value               |
|----------|---------------------|
| Host     | `mysql` (internal)  |
| Port     | 3306                |
| User     | `bear_development`  |
| Password | `bear`              |
| Database | `bear3_development` |
| Mode     | read-only (`safe`)  |
