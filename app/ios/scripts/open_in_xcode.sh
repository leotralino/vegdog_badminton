#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/VegDog.xcodeproj"

if [ ! -d "$PROJECT_PATH" ]; then
  echo "Project not found. Run scripts/generate_xcodeproj.sh first."
  exit 1
fi

open "$PROJECT_PATH"
