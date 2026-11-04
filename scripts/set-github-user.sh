# Підставляє ваш логін GitHub у файли репозиторію: bash scripts/set-github-user.sh <логін>
set -euo pipefail
user="${1:?Використання: bash scripts/set-github-user.sh <логін GitHub>}"
cd "$(dirname "$0")/.."
sed -i "s/YOUR_GITHUB_USER/${user}/g" bootstrap/root.yaml argocd-apps/hotel-booking.yaml charts/hotel-booking/values-ghcr.yaml
echo "Готово. Перевірка:"
grep -rn "github.com\|ghcr.io" bootstrap argocd-apps charts/hotel-booking/values-ghcr.yaml
