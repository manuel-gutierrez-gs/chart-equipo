{{- define "generic.Service" }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Generic.name }}-service
  namespace: {{ .namespace }}
  labels:
    app: {{ .Generic.name }}
    service: {{ .Generic.name }}-service
    sas_monitoring: {{ .Generic.service.sas_monitoring | quote  }}
spec:
  {{- if .Generic.developDeployment }}
  type: NodePort
  {{- end }}
  selector:
    app: {{ .Generic.name }}
  ports:
  - name: "http"
    port: {{ required "Parameter port cannot be empty or null" .Generic.service.port }}
    {{- if .Generic.developDeployment }}
    targetPort: {{ .Generic.service.port }}
    nodePort: {{ .Generic.service.nodePort }}
    {{- end }}
---
{{- end }}