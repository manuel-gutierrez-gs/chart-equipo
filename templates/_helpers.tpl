{{/*
Devuelve el nombre completo del recurso. Si se define `fullnameOverride`, se usa ese valor.
*/}}
{{- define "mychart.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{ .Values.fullnameOverride }}
{{- else -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end -}}
{{- end -}}
