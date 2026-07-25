#!/usr/bin/env bash
#
# publish.sh — publie la cave Dionysos (Élise) sur le site day2day.
#
# Ce que fait le script :
#   1. Vérifie qu'aucun prix / lieu d'achat ne part en ligne (le site est PUBLIC).
#   2. Met en attente tout changement sous static/cave/ (fiches, photos, suppressions).
#   3. S'il n'y a rien de neuf, s'arrête sans rien faire.
#   4. Sinon, committe et pousse sur GitHub → Cloudflare reconstruit le site.
#
# Usage :
#   ./publish.sh                 → message de commit automatique (daté)
#   ./publish.sh "mon message"   → message de commit personnalisé
#
set -euo pipefail

# Toujours travailler depuis le dossier du dépôt, où qu'on lance le script.
cd "$(dirname "$0")"

CAVE="static/cave"
JSON="$CAVE/vins.json"

# 1. Garde-fou confidentialité — jamais de prix/lieu d'achat sur un site public.
if [ -f "$JSON" ] && grep -qiE '"prix"|"lieu_achat"' "$JSON"; then
  echo "⛔ Publication annulée : un champ prix/lieu_achat a été détecté dans $JSON."
  echo "   Retire cette donnée avant de publier — le site est public."
  exit 1
fi

# 2. Mettre en attente tout changement de la cave (ajouts, modifs ET suppressions).
git add -A "$CAVE"

# 3. Rien à publier ?
if git diff --cached --quiet -- "$CAVE"; then
  echo "✅ Rien à publier : la cave en ligne est déjà à jour."
  exit 0
fi

# Petit récapitulatif de ce qui va partir.
echo "Changements à publier :"
git diff --cached --name-status -- "$CAVE" | sed 's/^/   /'
echo

# 4. Commit (message personnalisé en 1er argument, sinon message daté).
MSG="${1:-cave: mise à jour de la cave Dionysos ($(date '+%Y-%m-%d %H:%M'))}"
git commit -m "$MSG"

# 5. Push → déclenche le déploiement Cloudflare.
echo "--- Envoi vers GitHub (déclenche le déploiement Cloudflare) ---"
git push origin master

echo
echo "✅ Publié. Cloudflare reconstruit le site (~1 à 2 min)."
echo "   → https://day2day.pages.dev/cave/"
