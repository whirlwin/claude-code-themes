#!/usr/bin/env bash
# Fails when the site and the catalog disagree: a marketplace entry with no
# card, a card with no entry, or a page or stylesheet that points at a file
# that is not there. Also fails on en and em dashes in the files we write.
# `npm run check` runs it after `claude plugin validate .`. Needs jq.
# Written for bash 3.2, the bash that ships with macOS.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
catalog="$root/.claude-plugin/marketplace.json"
public="$root/public"
page="$public/index.html"
site=https://themes.whirlwin.io
failed=0

problem() {
  echo "check: $*" >&2
  failed=1
}

# Every catalog entry has a card, an <article class="card theme" id="<name>">,
# that carries its install command, and every card has an entry. The copy
# button copies the text of the card's code element, so that text must be
# exactly the command, which adds the marketplace first if it is missing.
names=$(jq -r '.plugins[].name' "$catalog")
for name in $names; do
  grep -Eq "<article class=\"card theme[^\"]*\" id=\"$name\"" "$page" ||
    problem "index.html has no card for \"$name\": <article class=\"card theme ...\" id=\"$name\">"
  cmd="/plugin install $name --marketplace $site/marketplace.json"
  # The command carries markup for line breaking, so compare it as text.
  got=$(sed -n "/<article class=\"card theme[^\"]*\" id=\"$name\"/,/<\/article>/p" "$page" |
    grep -o '<code class="cmd__text">.*</code>' | sed -E 's/<[^>]+>//g')
  [ "$got" = "$cmd" ] || problem "card #$name copies \"$got\", not \"$cmd\""
done
cards=$(grep -Eo '<article class="card theme[^"]*" id="[^"]+"' "$page" | sed -E 's/.*id="([^"]+)"/\1/')
for card in $cards; do
  grep -qx "$card" <<<"$names" ||
    problem "card #$card in index.html has no entry in .claude-plugin/marketplace.json"
done

# resolve FROM REF: fail unless REF, a link or source in the file FROM, names
# a file in public/ (and, with a #fragment, an id in that page). Links that
# leave the site are not checked.
resolve() {
  local from=$1 ref=$2 path fragment file
  case $ref in
    "$site"/*) ref=${ref#"$site"} ;;
    http://* | https://* | mailto:*) return 0 ;;
  esac
  path=${ref%%[?#]*}
  fragment=
  case $ref in *'#'*) fragment=${ref#*#} ;; esac
  case $path in
    '') file=$from ;;
    /marketplace.json) file=$catalog ;; # built into public/ by build.command
    */) file=$public${path%/}/index.html ;;
    /*) file=$public$path ;;
    *) file=$(dirname "$from")/$path ;;
  esac
  if [ ! -f "$file" ]; then
    problem "${from#"$root"/} points at $ref, which is not a file in public/"
  elif [ -n "$fragment" ] && ! grep -q "id=\"$fragment\"" "$file"; then
    problem "${from#"$root"/} links to $ref, but ${file#"$root"/} has no id=\"$fragment\""
  fi
}

for html in "$public"/*.html; do
  for ref in $(grep -Eo '(src|href)="[^"]*"' "$html" | sed -E 's/^[a-z]+="(.*)"$/\1/'); do
    resolve "$html" "$ref"
  done
  # og:image and the like are absolute URLs on this site.
  for ref in $(grep -Eo "content=\"$site/[^\"]*\"" "$html" | sed -E 's/^content="(.*)"$/\1/'); do
    resolve "$html" "$ref"
  done
done
for css in "$public"/*.css; do
  for ref in $(grep -Eo 'url\([^)]*\)' "$css" | sed -E 's/^url\("?([^")]*)"?\)$/\1/'); do
    resolve "$css" "$ref"
  done
done

# The house style has no en or em dashes, in copy or in comments.
dashes=$(printf '\342\200\223|\342\200\224')
for file in "$root"/README.md "$root"/wrangler.jsonc "$root"/package.json "$catalog" \
  "$root"/scripts/*.sh "$root"/og/*.html "$public"/*.html "$public"/*.css "$public"/*.js \
  "$public"/_headers "$public"/favicon.svg; do
  [ -f "$file" ] || continue
  if LC_ALL=C grep -En "$dashes" "$file" >/dev/null; then
    problem "${file#"$root"/} has an en or em dash: $(LC_ALL=C grep -En "$dashes" "$file" | cut -d: -f1 | tr '\n' ' ')"
  fi
done

if [ "$failed" -ne 0 ]; then
  exit 1
fi
echo "check: $(wc -w <<<"$names" | tr -d ' ') catalog entries match their cards, and every local link resolves"
