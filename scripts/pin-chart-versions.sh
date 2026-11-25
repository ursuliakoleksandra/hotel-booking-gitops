# Підставляє в argocd-apps/*.yaml актуальні версії чартів моніторингу (за helm search repo).
# Запуск з кореня репозиторію: bash scripts/pin-chart-versions.sh
set -euo pipefail
cd "$(dirname "$0")/.."

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null
helm repo add grafana-community https://grafana-community.github.io/helm-charts >/dev/null
helm repo add grafana https://grafana.github.io/helm-charts >/dev/null
helm repo update >/dev/null

latest() {
  helm search repo "$1" -o json | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4
}

pin() {
  local file="$1" chart="$2" ver
  ver="$(latest "$chart")"
  [ -n "$ver" ] || { echo "Не вдалося визначити версію $chart"; exit 1; }
  sed -i "s/^\(    targetRevision: \)[^ ]*/\1${ver}/" "$file"
  echo "$chart -> $ver ($file)"
}

pin argocd-apps/kps.yaml prometheus-community/kube-prometheus-stack
pin argocd-apps/loki.yaml grafana-community/loki
pin argocd-apps/alloy.yaml grafana/alloy
grep -n "targetRevision" argocd-apps/kps.yaml argocd-apps/loki.yaml argocd-apps/alloy.yaml
