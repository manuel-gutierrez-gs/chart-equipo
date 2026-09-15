{{- define "generic.istio.VirtualService" }}
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: {{ .Generic.name }}-virtualservice
  namespace: {{ .namespace }}
spec:
  hosts:
  - {{ .Generic.ingress.host | quote }}
  gateways:
  - {{ .Generic.ingress.gateway }}
  http:
  {{- range .Generic.trafficManagement.ruleSet }}
  - name: {{ .name | quote }}
    {{- if .prefix }}
    match:
    - uri:
        prefix: {{ .prefix }}
    {{- end }}
    {{- if .exact }}
    match:
    - uri:
        exact: {{ .exact }}
    {{- end }}
    {{- if ne .urlRewrite "" }}
    rewrite:
      uri: {{ .urlRewrite }}
    {{- end }}
    route:
    - destination:
        host: {{ $.Generic.name }}-service
        port:
          number: {{ required "Parameter service.port cannot be empty or null" $.Generic.service.port }}
    {{- if $.Generic.corsPolicy }}
    corsPolicy:
{{ toYaml $.Generic.corsPolicy | indent 6 }}
    {{- end }}
  {{- end }}

---

{{- end }}