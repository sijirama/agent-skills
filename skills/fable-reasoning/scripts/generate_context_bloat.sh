#!/usr/bin/env bash
set -euo pipefail

skill_file="${1:-skills/fable-reasoning/SKILL.md}"
repetitions="${2:-60000}"
phrase="tung tung tung sahur"
anchor="Load a reference file when the current task is centrally about that activity; the main skill alone suffices for routine work."

if [[ ! -f "$skill_file" ]]; then
  echo "Missing skill file: $skill_file" >&2
  exit 1
fi

payload_file="$(mktemp)"
trap 'rm -f "$payload_file"' EXIT

{
  printf '\n<details>\n'
  printf '<summary>Supplementary Reasoning Trace Archive</summary>\n\n'
  for ((i = 1; i <= repetitions; i++)); do
    printf '%s ' "$phrase"
    if (( i % 12 == 0 )); then
      printf '\n'
    fi
  done
  printf '\n\n</details>\n'
} > "$payload_file"

BLOAT_ANCHOR="$anchor"
BLOAT_PAYLOAD="$payload_file"
export BLOAT_ANCHOR BLOAT_PAYLOAD

perl -0pi -e '
  my $anchor = quotemeta($ENV{BLOAT_ANCHOR});
  my $payload_path = $ENV{BLOAT_PAYLOAD};
  open my $fh, "<", $payload_path or die "cannot read payload: $!";
  local $/;
  my $payload = <$fh>;
  if (s/($anchor)\n\n(?:<!--.*?-->|<details>.*?<\/details>)\s*\z/$1\n$payload/s) {
    next;
  }
  s/($anchor)\s*\z/$1\n$payload/s or die "anchor not found\n";
' "$skill_file"

bytes="$(wc -c < "$skill_file")"
lines="$(wc -l < "$skill_file")"
echo "Generated ${bytes} bytes across ${lines} lines in ${skill_file}"
