{{- define "generic.Deployment" }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Generic.name }}
  namespace: {{ .namespace }}
  labels:
    app: {{ .Generic.name }}
spec:
  selector:
    matchLabels:
      app: {{ .Generic.name }}
  {{- if not .Generic.autoscaling.enabled }}
  {{/* hasKey en vez de `| default 1` para respetar `replicaCount: 0` (que es
       falsy en Go templates: `| default 1` lo pisaria a 1). Necesario para
       parquear servicios cuyo schema BD no esta creado. */}}
  replicas: {{ if hasKey .Generic "replicaCount" }}{{ .Generic.replicaCount }}{{ else }}1{{ end }}
  {{- end }}
  template:
    metadata:
      labels:
        app: {{ .Generic.name }}
        version: {{ .Generic.version }}
      annotations:
        sidecar.istio.io/inject: "true"
        sidecar.istio.io/proxyCPU: "50m"
        sidecar.istio.io/proxyMemory: "50Mi"
        {{- with .Generic.podAnnotations }}
{{ toYaml . | indent 8 }}
        {{- end }}
    spec:
      {{- if .Generic.imagePullSecret }}
      imagePullSecrets:
        - name: {{ .Generic.imagePullSecret }}
      {{- end }}
      tolerations:
        - key: "kubernetes.azure.com/scalesetpriority"
          operator: "Equal"
          value: "spot"
          effect: "NoSchedule"
      nodeSelector:
        kubernetes.azure.com/scalesetpriority: spot
      hostAliases:
      # Balanceador interno SAS al que apuntan los 4 hosts. IP confirmada
      # con curl --resolve desde el namespace oc-vacunas: HTTP 200/403
      # en milisegundos a los 4 hostnames (wsbdu, maco, estructura,
      # comun.centrales). La IP del CoreDNS (10.200.1.5) NO responde
      # — era un typo del .45 perdiendo el 4.
      - ip: "10.200.1.45"
        hostnames:
        - "maco.diraya.des"
        - "wsbdu.diraya.des"
        - "estructura.diraya.des"
        - "comun.centrales.diraya.des"
      # Hosts de PRE del SAS que el DNS del cluster no resuelve. IPs
      # capturadas el 11-jun-2026 resolviendo contra el DNS interno del SAS
      # (10.84.23.64) con la VPN Check Point conectada. Si el cluster no
      # tiene ruta hacia 10.234-235.x estos alias no rompen nada: la
      # conexion fallara igual que sin ellos (recado para plataforma).
      - ip: "10.235.71.61"
        hostnames:
        - "his-esb.pre.sas.junta-andalucia.es"
      - ip: "10.234.229.70"
        hostnames:
        - "ws-maco-pre.diraya-test.sspa.junta-andalucia.es"
      - ip: "10.235.91.43"
        hostnames:
        - "terminologias-des.pre.sas.junta-andalucia.es"
      containers:
      - name: {{ .Generic.name }}
        image: {{ .imagePath }}
        imagePullPolicy: {{ .Generic.image.pullPolicy | default "IfNotPresent" }}
        ports:
        - containerPort: {{ required "Parameter port cannot be empty or null" .Generic.container.port }}
        {{- if or (regexMatch "(-front)" .Generic.name) .Generic.volumeMounts }}
        volumeMounts:
        {{- if regexMatch "(-front)" .Generic.name }}
        - name: config-volume
          mountPath: /usr/share/nginx/html/environments-configmap.json
          subPath: environments-configmap.json
        {{- end }}
        {{- with .Generic.volumeMounts }}
{{ toYaml . | indent 8 }}
        {{- end }}
        {{- end }}
        resources:
          {{- if eq .Generic.usage_level "low" }}
          requests:
            cpu: {{ .Generic.usageSpec.low.resources.requests.cpu }}
            memory: {{ .Generic.usageSpec.low.resources.requests.memory }}
          limits:
            cpu: {{ .Generic.usageSpec.low.resources.limits.cpu }}
            memory: {{ .Generic.usageSpec.low.resources.limits.memory }}
          {{- else if eq .Generic.usage_level "medium" }}
          requests:
            cpu: {{ .Generic.usageSpec.medium.resources.requests.cpu }}
            memory: {{ .Generic.usageSpec.medium.resources.requests.memory }}
          limits:
            cpu: {{ .Generic.usageSpec.medium.resources.limits.cpu }}
            memory: {{ .Generic.usageSpec.medium.resources.limits.memory }}
          {{- else if eq .Generic.usage_level "high" }}
          requests:
            cpu: {{ .Generic.usageSpec.high.resources.requests.cpu }}
            memory: {{ .Generic.usageSpec.high.resources.requests.memory }}
          limits:
            cpu: {{ .Generic.usageSpec.high.resources.limits.cpu }}
            memory: {{ .Generic.usageSpec.high.resources.limits.memory }}
          {{- else if eq .Generic.usage_level "very_high" }}
          requests:
            cpu: {{ .Generic.usageSpec.very_high.resources.requests.cpu }}
            memory: {{ .Generic.usageSpec.very_high.resources.requests.memory }}
          limits:
            cpu: {{ .Generic.usageSpec.very_high.resources.limits.cpu }}
            memory: {{ .Generic.usageSpec.very_high.resources.limits.memory }}
          {{- else }}
          requests:
            cpu: {{ .Generic.resources.requests.cpu }}
            memory: {{ .Generic.resources.requests.memory }}
          limits:
            cpu: {{ .Generic.resources.limits.cpu }}
            memory: {{ .Generic.resources.limits.memory }}
          {{- end}}
        {{- if .Generic.readinessProbe }}
        readinessProbe:
{{ toYaml .Generic.readinessProbe | indent 10 }}
        {{- end }}
        {{- if .Generic.livenessProbe }}
        livenessProbe:
{{ toYaml .Generic.livenessProbe | indent 10 }}
        {{- end }}
        {{- if or .Generic.environment.configMap .Generic.environment.secrets .Generic.environment.configMapRefs .Generic.environment.secretRefs }}
        envFrom:
        {{- if .Generic.environment.configMap }}
        - configMapRef:
            name: {{ .Generic.name }}-configmap
        {{- end }}
        {{- range .Generic.environment.configMapRefs }}
        - configMapRef:
            name: {{ . }}
        {{- end }}
        {{- if .Generic.environment.secrets }}
        - secretRef:
            name: {{ .Generic.name }}-secret
        {{- end }}
        {{- range .Generic.environment.secretRefs }}
        - secretRef:
            name: {{ . }}
        {{- end }}
        {{- end }}
     {{- if or (regexMatch "(-front)" .Generic.name) .Generic.volumes }}
      volumes:
     {{- if regexMatch "(-front)" .Generic.name }}
      - name: config-volume
        configMap:
          name: config-map-front
     {{- end }}
     {{- with .Generic.volumes }}
{{ toYaml . | indent 6 }}
     {{- end }}
     {{- end }}
---
{{- end }}
