#!/usr/bin/env bash
#
# Copyright (C) 2026 clangsdorff
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

PRINT_USAGE()
{
    echo "Usage: diskusage [options]" >&2
    echo " -p, --path <path> : Scan a specific path instead of work dir" >&2
    echo " -n, --number <n>  : Number of results (default: 30)" >&2
}

LIMIT=30
SCAN_PATH="$WORK_DIR"

while [ "$#" != 0 ]; do
    case "$1" in
        "-p" | "--path")
            SCAN_PATH="$2"
            shift 2
            ;;
        "-n" | "--number")
            LIMIT="$2"
            shift 2
            ;;
        "-h" | "--help")
            PRINT_USAGE
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            PRINT_USAGE
            exit 1
            ;;
    esac
done

if [ ! -d "$SCAN_PATH" ]; then
    echo "Path not found: $SCAN_PATH"
    exit 1
fi

echo "Largest files in $SCAN_PATH:"
echo "----------------------------------------"
find "$SCAN_PATH" -type f -not -path "*/\.*" -exec du -b {} + 2>/dev/null | sort -rn | head -n "$LIMIT" | awk '{size=$1; $1=""; name=substr($0,2); if (size>=1073741824) printf "%.2f GiB%s\n", size/1073741824, name; else if (size>=1048576) printf "%.2f MiB%s\n", size/1048576, name; else if (size>=1024) printf "%.2f KiB%s\n", size/1024, name; else printf "%d B%s\n", size, name}'

echo ""
echo "Largest directories in $SCAN_PATH:"
echo "----------------------------------------"
du -sh "$SCAN_PATH"/*/ 2>/dev/null | sort -rh | head -n "$LIMIT"

echo ""
echo "Total size:"
du -sh "$SCAN_PATH" 2>/dev/null
