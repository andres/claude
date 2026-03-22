# Ollama Local LLM Server

## Quick Start

```bash
# Start the container
docker start ollama

# Stop the container
docker stop ollama

# Check status
docker ps --filter "name=ollama"
```

## Container Details

| Property | Value |
|----------|-------|
| Container name | `ollama` |
| Image | `ollama/ollama:latest` |
| Port | `11434` → `localhost:11434` |
| Volume | `ollama:/root/.ollama` (named volume) |

## Available Models

| Model | Size | Notes |
|-------|------|-------|
| `deepseek-r1:14b` | 9.0 GB | DeepSeek R1 reasoning model |
| `qwen2.5:14b` | 9.0 GB | Alibaba Qwen 2.5 |
| `llama3.1:8b` | 4.9 GB | Meta Llama 3.1 |
| `llama3.2:3b` | 2.0 GB | Meta Llama 3.2 (lightweight) |

## Common Commands

```bash
# List models
docker exec ollama ollama list

# Run a model interactively
docker exec -it ollama ollama run llama3.1:8b

# Pull a new model
docker exec ollama ollama pull <model-name>

# Remove a model
docker exec ollama ollama rm <model-name>

# API: generate a completion
curl http://localhost:11434/api/generate -d '{"model":"llama3.1:8b","prompt":"Hello"}'

# API: chat
curl http://localhost:11434/api/chat -d '{"model":"llama3.1:8b","messages":[{"role":"user","content":"Hello"}]}'

# API: list models
curl http://localhost:11434/api/tags
```

## Re-creating the Container (if needed)

```bash
docker run -d --name ollama -p 11434:11434 -v ollama:/root/.ollama ollama/ollama:latest
```
