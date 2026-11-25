{{/* Шаблон пода Spring-сервісу: спільний для Deployment і Rollout. Аргументи: dict "root" $ "name" <ім'я> "svc" <значення сервісу> */}}
{{- define "hotel-booking.app.podTemplate" -}}
{{- $root := .root }}
{{- $name := .name }}
{{- $svc := .svc }}
{{- $comp := include "hotel-booking.componentName" (dict "root" $root "component" $name) }}
{{- $pg := include "hotel-booking.componentName" (dict "root" $root "component" "postgres") }}
metadata:
  labels:
    {{- include "hotel-booking.selectorLabels" (dict "root" $root "component" $name) | nindent 4 }}
  annotations:
    checksum/config: {{ include (print $root.Template.BasePath "/app-configmap.yaml") $root | sha256sum }}
    checksum/secret: {{ include (print $root.Template.BasePath "/app-secret.yaml") $root | sha256sum }}
spec:
  enableServiceLinks: false
  initContainers:
    - name: wait-for-postgres
      image: {{ include "hotel-booking.imageRef" $root.Values.postgres.image }}
      imagePullPolicy: {{ $root.Values.image.pullPolicy }}
      command:
        - sh
        - -c
        - until pg_isready -h {{ $pg }} -p {{ $root.Values.postgres.port }} -U {{ $root.Values.postgres.user }}; do echo "waiting for postgres"; sleep 2; done
      resources:
        requests:
          cpu: 10m
          memory: 16Mi
        limits:
          cpu: 100m
          memory: 64Mi
  containers:
    - name: {{ $name }}
      image: {{ include "hotel-booking.image" (dict "root" $root "image" $svc.image) }}
      imagePullPolicy: {{ $root.Values.image.pullPolicy }}
      ports:
        - containerPort: {{ $svc.port }}
          name: http
      envFrom:
        - configMapRef:
            name: {{ $comp }}-config
        - secretRef:
            name: {{ default (printf "%s-secret" $comp) $root.Values.existingSecret }}
      env:
        - name: SERVER_PORT
          value: {{ $svc.port | quote }}
        - name: JAVA_TOOL_OPTIONS
          value: {{ $root.Values.javaOpts | quote }}
        {{- with $svc.env }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      resources:
        {{- toYaml $svc.resources | nindent 8 }}
      startupProbe:
        httpGet:
          path: /actuator/health/liveness
          port: http
        periodSeconds: 5
        timeoutSeconds: 3
        failureThreshold: 48
      livenessProbe:
        httpGet:
          path: /actuator/health/liveness
          port: http
        periodSeconds: 15
        timeoutSeconds: 3
        failureThreshold: 3
      readinessProbe:
        httpGet:
          path: /actuator/health/readiness
          port: http
        periodSeconds: 10
        timeoutSeconds: 3
        failureThreshold: 3
{{- end }}
