#!/usr/bin/env bash
# Installs the physicalpknu skill into ~/.claude/skills/physicalpknu.
#
#   curl -fsSL https://raw.githubusercontent.com/dptjddl285-ship-it/test/main/install.sh | bash
#
# Fallback for machines without Node. The normal route is the skills.sh CLI:
#
#   npx skills add dptjddl285-ship-it/test
#
# Works from a checkout too - it copies the local files instead of downloading
# when they are already next to this script.

set -euo pipefail

REPO="${PHYSICALPKNU_REPO:-dptjddl285-ship-it/test}"
BRANCH="${PHYSICALPKNU_BRANCH:-main}"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}/skills/physicalpknu"
DEST="${HOME}/.claude/skills/physicalpknu"
FILES="SKILL.md skill.sh"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
local_src="${here}/skills/physicalpknu"

mkdir -p "$DEST"

if [ -d "$local_src" ]; then
  echo "installing from local checkout: ${local_src}"
  for f in $FILES; do cp "${local_src}/${f}" "${DEST}/${f}"; done
else
  echo "downloading from ${REPO}@${BRANCH}"
  for f in $FILES; do
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "${RAW}/${f}" -o "${DEST}/${f}"
    elif command -v wget >/dev/null 2>&1; then
      wget -qO "${DEST}/${f}" "${RAW}/${f}"
    else
      echo "error: need curl or wget" >&2
      exit 1
    fi
  done
fi

chmod +x "${DEST}/skill.sh"

cat <<EOF

Installed skill: ${DEST}

Next:
  cd ${DEST}
  ./skill.sh name YOUR_NAME     # must match DEVICE_NAME in your board
  ./skill.sh check              # is the broker reachable?
  ./skill.sh devices            # which boards are online
  ./skill.sh led on

Needs the mosquitto clients (mosquitto_pub / mosquitto_sub):
  Windows  https://mosquitto.org/download/   (default path is auto-detected)
  macOS    brew install mosquitto
  Linux    sudo apt install mosquitto-clients
EOF
