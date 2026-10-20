#!/usr/bin/env bash
# Launch ComfyUI for the AudioCraft -> Demucs stem pipeline.
#
# Notes:
#   * Runs on CPU. The GTX 1070 (sm_61 / compute 6.1) cannot be used by this
#     ComfyUI build: its pinned comfy-kitchen==0.2.39 needs sm_75+ with cu130+.
#   * Interpreter is the venv that has ComfyUI's dependencies installed
#     (torch, torchsde, av, demucs, transformers, ...).
set -euo pipefail

PYTHON="${PYTHON:-/home/mrnicholas/dictator-env/bin/python}"
COMFY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8188}"
LOG="${LOG:-/tmp/opencode/comfyui.log}"

if [ ! -x "$PYTHON" ]; then
  echo "Python interpreter not found or not executable: $PYTHON" >&2
  echo "Override it with PYTHON=/path/to/python $0" >&2
  exit 1
fi

if pgrep -f "main.py .*--port $PORT" >/dev/null 2>&1; then
  echo "ComfyUI already listening on port $PORT. Stop it first (pkill -f 'main.py')." >&2
  exit 1
fi

cd "$COMFY_DIR"
echo "Starting ComfyUI (CPU) at http://$HOST:$PORT"
echo "Logging to $LOG"
echo "Stems are written to $COMFY_DIR/output/stems"

exec "$PYTHON" main.py --cpu --listen "$HOST" --port "$PORT" > "$LOG" 2>&1
