{{- define "generic.istio.RequestAuthentication" }}
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: {{ .Generic.name }}-requestauthentication
  namespace: {{ .namespace }}
spec:
  selector:
    matchLabels:
      app: {{ .Generic.name }}
  jwtRules:
  - issuer: {{ required "Parameter authentication.jwt.issuer cannot be empty or null" .Generic.authentication.jwt.issuer | quote }}
    jwksUri: {{ required "Parameter authentication.jwt.jwksUri cannot be empty or null" .Generic.authentication.jwt.jwksUri | quote }}
    forwardOriginalToken: true
---
{{- end }}
