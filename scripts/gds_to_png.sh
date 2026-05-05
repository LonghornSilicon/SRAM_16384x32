#!/usr/bin/env bash
# Render a GDS file to PNG using KLayout (batch mode).
#
# Usage:
#   scripts/gds_to_png.sh                            # uses defaults below
#   scripts/gds_to_png.sh <input.gds>                # auto-derives <input>.png
#   scripts/gds_to_png.sh <input.gds> <output.png>   # explicit output
#   scripts/gds_to_png.sh <input.gds> <output.png> <long_side>
#
# Extra positional / -rd args after long_side are forwarded to the python
# script (see scripts/gds_to_png.py for the full list, e.g. bg=#000000,
# margin=0.06, oversample=2, cell=<name>).
#
# Environment overrides:
#   KLAYOUT      - path to klayout binary (default: klayout from PATH)
#   PDK_ROOT     - PDK root (default: ~/.volare)
#   PDK          - PDK name (default: sky130A)
#   LYP          - explicit layer-properties .lyp (default: PDK's sky130A.lyp)

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

GDS="${1:-$ROOT/gds/CF_SRAM_16384x32.gds}"
PNG="${2:-${GDS%.gds}.png}"
LONG_SIDE="${3:-6144}"
shift $(( $# < 3 ? $# : 3 )) || true

KLAYOUT_BIN="${KLAYOUT:-$(command -v klayout || true)}"
if [[ -z "$KLAYOUT_BIN" || ! -x "$KLAYOUT_BIN" ]]; then
    echo "ERROR: klayout not found on PATH; set KLAYOUT=/path/to/klayout" >&2
    exit 1
fi

if [[ ! -f "$GDS" ]]; then
    echo "ERROR: GDS file not found: $GDS" >&2
    exit 1
fi

PDK_ROOT="${PDK_ROOT:-$HOME/.volare}"
PDK="${PDK:-sky130A}"
LYP="${LYP:-$PDK_ROOT/$PDK/libs.tech/klayout/tech/$PDK.lyp}"

EXTRA_RD=()
if [[ -f "$LYP" ]]; then
    EXTRA_RD+=("-rd" "lyp=$LYP")
else
    echo "WARN: layer properties file not found: $LYP (rendering with klayout defaults)" >&2
fi

# Forward any remaining 'key=value' args verbatim as -rd flags.
for arg in "$@"; do
    EXTRA_RD+=("-rd" "$arg")
done

echo "[gds_to_png] klayout : $KLAYOUT_BIN"
exec "$KLAYOUT_BIN" -b -nc -z \
    -r "$HERE/gds_to_png.py" \
    -rd "gds=$GDS" \
    -rd "png=$PNG" \
    -rd "long_side=$LONG_SIDE" \
    "${EXTRA_RD[@]}"
