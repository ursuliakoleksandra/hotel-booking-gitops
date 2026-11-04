# Публікує локально зібрані образи (1.0.0 і 1.1.0) у GHCR: bash scripts/push-to-ghcr.sh <логін GitHub>
# Перед цим: docker login ghcr.io -u <логін> (пароль: токен з правом write:packages).
# Після публікації зробіть пакети публічними (GitHub, Packages, Package settings, Change visibility).
set -euo pipefail
user="$(echo "${1:?Використання: bash scripts/push-to-ghcr.sh <логін GitHub>}" | tr '[:upper:]' '[:lower:]')"
for svc in user-service hotel-management booking-service ui; do
  for ver in 1.0.0 1.1.0; do
    src="hotel-booking-system/${svc}:${ver}"
    dst="ghcr.io/${user}/hotel-booking-${svc}:${ver}"
    echo "==> ${src} -> ${dst}"
    docker tag "${src}" "${dst}"
    docker push "${dst}"
  done
done
