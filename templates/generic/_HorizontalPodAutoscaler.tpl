{{- define "generic.HorizontalPodAutoscaler" }}
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Generic.name }}-hpa
  namespace: {{ .namespace }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .Generic.name }}-deployment
  minReplicas: {{ .Generic.autoscaling.minReplicas | default 1 }}
  maxReplicas: {{ .Generic.autoscaling.maxReplicas | default 1 }}  
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: AverageValue
        averageValue: {{ required "Parameter .Generic.autoscaling.targetCPUUtilizationValue cannot be empty or null" .Generic.autoscaling.targetCPUUtilizationValue }}
  - type: Resource
    resource:
      name: memory
      target: 
        type: AverageValue
        averageValue: {{ required "Parameter .Generic.autoscaling.targetMemoryUtilizationValue cannot be empty or null" .Generic.autoscaling.targetMemoryUtilizationValue }}
---
{{- end }}