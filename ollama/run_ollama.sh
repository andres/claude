#!/usr/bin/env bash
set -euo pipefail

CONTAINER="ollama"

# Ensure container is running
status=$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null || echo "missing")

if [[ "$status" == "missing" ]]; then
    echo "Error: Ollama container '$CONTAINER' does not exist."
    echo "Create it with: docker run -d --name ollama -p 11434:11434 -v ollama:/root/.ollama ollama/ollama:latest"
    exit 1
elif [[ "$status" != "true" ]]; then
    echo "Starting Ollama container..."
    docker start "$CONTAINER" > /dev/null
    sleep 2
    echo "Container started."
fi

# Get available models
models=$(docker exec "$CONTAINER" ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')

if [[ -z "$models" ]]; then
    echo "No models found. Pull one with: docker exec ollama ollama pull <model>"
    exit 1
fi

# Display menu
echo ""
echo "Available models:"
echo "─────────────────"
i=1
while IFS= read -r model; do
    echo "  $i) $model"
    ((i++))
done <<< "$models"
echo ""

# Get selection
read -rp "Select model [1-$((i-1))]: " choice

if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice >= i )); then
    echo "Invalid selection."
    exit 1
fi

selected=$(sed -n "${choice}p" <<< "$models")
echo ""
echo "Launching $selected ..."
echo ""
docker exec -it "$CONTAINER" ollama run "$selected"
