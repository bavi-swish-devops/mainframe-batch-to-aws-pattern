#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COBOL_SRC="${PROJECT_ROOT}/legacy/cobol/ACCTPOST.cbl"
COBOL_BIN="${PROJECT_ROOT}/legacy/cobol/ACCTPOST"

echo "==> Running legacy batch locally"
echo "Project root: ${PROJECT_ROOT}"

if ! command -v cobc >/dev/null 2>&1; then
  echo "ERROR: GnuCOBOL (cobc) is not installed."
  echo "Install it first, for example on Ubuntu/Debian:"
  echo "  sudo apt-get update && sudo apt-get install gnucobol"
  exit 1
fi

echo "==> Compiling COBOL program"
cobc -x -o "${COBOL_BIN}" "${COBOL_SRC}"

echo "==> Executing COBOL batch"
(
  cd "${PROJECT_ROOT}"
  "${COBOL_BIN}"
)

echo "==> Legacy batch completed"