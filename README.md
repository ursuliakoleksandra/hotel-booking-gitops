# hotel-booking-gitops

Репозиторій конфігурації для лабораторної роботи №5 (GitOps через Argo CD). Застосунок: hotel-booking-system
(user-service, hotel-management, booking-service, UI, PostgreSQL, Kafka). Єдине джерело правди про стан кластера: цей репозиторій.

```
hotel-booking-gitops/
├── bootstrap/root.yaml            кореневий Application, застосовується вручну один раз
├── argocd-apps/hotel-booking.yaml Application застосунку (ним керує root)
├── argocd-apps/argo-rollouts.yaml Application контролера Argo Rollouts (ЛР-6)
├── charts/hotel-booking/          Helm-чарт з лабораторної №4
│   ├── values-minikube.yaml       значення для кластера minikube (тег образу, existingSecret, вимкнені хуки)
│   └── values-ghcr.yaml           необов'язково: образи з GHCR замість локальних
└── scripts/
    ├── set-github-user.sh         підставляє ваш логін GitHub у файли
    └── push-to-ghcr.sh            публікує образи 1.0.0 і 1.1.0 у GHCR
```

## Що змінилось у чарті порівняно з лабораторною №4

- `existingSecret`: якщо задано, чарт не створює Secret, а Deployment-и (сервіси й PostgreSQL) беруть змінні з наявного Secret.
  Для minikube це `hotel-booking-secret`, який створюється вручну командою `kubectl create secret`, тож паролів у Git немає.
- `hooks.enabled` і `tests.enabled`: Argo CD перетворює Helm-хук `pre-upgrade` на PreSync-хук, що запускається ще до створення
  об'єктів. Наша перевірка PostgreSQL на першій синхронізації завершилась би помилкою, тому в `values-minikube.yaml` хуки вимкнені.
- `ui.progressDeadlineSeconds`: у `values-minikube.yaml` дорівнює 90, щоб невдале оновлення UI швидко давало статус `Degraded`.

## Як це працює

Назва Application (`hotel-booking`) стає назвою Helm-релізу, тому об'єкти називаються `hotel-booking-*`
(наприклад, `hotel-booking-ui`). Argo CD лише рендерить шаблони (`helm list` порожній) і застосовує результат у namespace `hotel-gitops`.
Усі зміни робляться комітами в `main`, ручний `kubectl apply` виконується один раз для `bootstrap/root.yaml`.

## Лабораторна №6: Argo Rollouts

- `argocd-apps/argo-rollouts.yaml`: контролер Argo Rollouts (чарт `argo-rollouts` 2.43.8), sync-wave `-1`, `ServerSideApply=true`
  (CRD Argo Rollouts завеликі для звичайного apply).
- Rollout створюється для **UI** (`hotel-booking-ui`): stateless, невеликий, версію видно в `/version.json`. Spring-сервіси лишаються
  звичайними Deployment.
- Чарт (версія 0.2.0): `templates/ui-rollout.yaml`, `templates/ui-service-preview.yaml` (для blue-green), спільний шаблон пода
  `templates/_ui-pod.tpl` (Deployment і Rollout не розходяться), `ui-deployment.yaml` вимикається умовою `ui.rollout.enabled`.
- `values-minikube.yaml`: `ui.replicas: 5`, `ui.rollout.enabled: true`, canary-кроки 20%, пауза, 60%, 30 с, 80%, 30 с.
  Блок blue-green лежить там же закоментованим.
- `argocd-apps/hotel-booking.yaml`: `retry` на випадок, якщо застосунок синхронізується раніше за CRD.
