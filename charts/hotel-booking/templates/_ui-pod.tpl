{{/* Шаблон пода UI: спільний для Deployment і Rollout, щоб вони не розходилися */}}
{{- define "hotel-booking.ui.podTemplate" -}}
{{- $ui := include "hotel-booking.componentName" (dict "root" . "component" "ui") -}}
metadata:
  labels:
    {{- include "hotel-booking.selectorLabels" (dict "root" . "component" "ui") | nindent 4 }}
  annotations:
    checksum/config: {{ include (print $.Template.BasePath "/ui-configmap.yaml") . | sha256sum }}
spec:
  enableServiceLinks: false
  containers:
    - name: ui
      image: {{ include "hotel-booking.image" (dict "root" . "image" .Values.ui.image) }}
      imagePullPolicy: {{ .Values.image.pullPolicy }}
      ports:
        - containerPort: 80
          name: http
      resources:
        {{- toYaml .Values.ui.resources | nindent 8 }}
      volumeMounts:
        - name: nginx-conf
          mountPath: /etc/nginx/conf.d
      readinessProbe:
        httpGet:
          path: /healthz
          port: http
        periodSeconds: 5
        timeoutSeconds: 2
        failureThreshold: 3
      livenessProbe:
        httpGet:
          path: /healthz
          port: http
        initialDelaySeconds: 10
        periodSeconds: 15
        timeoutSeconds: 2
        failureThreshold: 3
  volumes:
    - name: nginx-conf
      configMap:
        name: {{ $ui }}-config
{{- end }}
