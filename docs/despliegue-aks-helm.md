# Despliegue en Azure AKS mediante Helm

Cómo se aplica el chart `oc-vacunas-helm` sobre el clúster de DES.

## Release

- Chart: el directorio `chart-equipo` (`.` si estás dentro)
- Release: `oc-vacunas`
- Namespace: `oc-vacunas`
- Values: `values-des.yaml`

`values-des.yaml` es el único fichero de values. Los datos globales están
arriba del todo:

```yaml
global:
  nameSpace: oc-vacunas
  registry:
    dns: solutia.azurecr.io
    path: oc-vacunas
  ingress:
    gateway: oc-vacunas-gateway
  imagePullSecret: solutia-acr-pull
  developDeployment: true    # true en DES; en PRE/PRO iría a false
  egress: []
```

## Cómo se forma la imagen

`templates/worker.yaml` construye la ruta así:

```gotemplate
{{ $imageBase := printf "%s:%s" $spec.image.name ($spec.imageTag | default "latest") }}
{{ $imagePath := printf "%s/%s/%s" $global.registry.dns $global.registry.path $imageBase }}
```

Con `image.name: vacunas-movimientos` e `imageTag: 1.0.1` en la entrada del
micro, sale:

```text
solutia.azurecr.io/oc-vacunas/vacunas-movimientos:1.0.1
```

Sin `imageTag` el chart usa `latest`. Reutilizar el mismo tag solo funciona si
el micro tiene `image.pullPolicy: Always`; si no, el nodo se queda con la
imagen cacheada.

## Qué genera el chart

Por cada entrada de `projects[]`, `templates/worker.yaml` lee el fichero de
`configFile`, lo mezcla con los valores por defecto de `microservicio.spec` y
con `global`, y renderiza:

- `Service` y `Deployment` siempre
- `ConfigMap` si hay `environment.configMap`
- `Secret` si hay `environment.secrets`
- `VirtualService` si `ingress.enabled: true`
- `HorizontalPodAutoscaler` si `autoscaling.enabled: true`

Además, `templates/gateway.yaml` genera un único Gateway con todos los hosts
de los micros expuestos, y `templates/serviceEntries.yaml` un ServiceEntry por
cada entrada de `global.egress`.

## Render previo (no toca el clúster)

```bash
helm template oc-vacunas . -n oc-vacunas -f values-des.yaml
```

Solo el Deployment de un micro:

```bash
helm template oc-vacunas . -n oc-vacunas -f values-des.yaml \
  | sed -n '/kind: Deployment/,/---/p'
```

## Despliegue

```bash
helm upgrade --install oc-vacunas . \
  -n oc-vacunas \
  -f values-des.yaml \
  --timeout 15m
```

Si el release quedó bloqueado por un despliegue anterior a medias
(`pending-upgrade`), hay que resolver ese estado antes de reintentar:

```bash
helm status oc-vacunas -n oc-vacunas
helm rollback oc-vacunas -n oc-vacunas
```

Redesplegar la misma versión no crea pods nuevos por sí solo: si el tag no
cambia, el Deployment queda igual y Kubernetes no ve motivo para reiniciar.

```bash
kubectl -n oc-vacunas rollout restart deploy/<micro>
kubectl -n oc-vacunas rollout status deploy/<micro> --timeout=300s
```

## Comprobaciones

```bash
helm list -n oc-vacunas
kubectl -n oc-vacunas get deploy,pod
```

Imagen que está corriendo de verdad:

```bash
kubectl -n oc-vacunas get deploy <micro> \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

Health interno:

```bash
kubectl -n oc-vacunas exec deploy/<micro> -- \
  curl -sS --max-time 30 http://localhost:9080/health/ready
```

Un rollout puede terminar bien sin arrancar nada: si el micro está a
`replicaCount: 0` no hay pods. Compruébalo:

```bash
kubectl -n oc-vacunas get pod -l app=<micro>
```

## Checklist

- La imagen existe en `solutia.azurecr.io/oc-vacunas`.
- El `imageTag` del micro en `values-des.yaml` es el que acabas de subir.
- Los Secrets externos que el micro referencia (`environment.secretRefs`) ya
  existen en el namespace.
- `helm template` renderiza sin errores.
- `helm upgrade` termina correctamente.
- `rollout status` termina y el pod queda `Running`.
- `/health/ready` responde `UP`.
