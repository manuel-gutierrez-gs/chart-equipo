# Tolerancias obligatorias en Azure AKS

Este documento describe las tolerancias y el `nodeSelector` que deben usar los Deployments generados por `oc-vacunas-helm`.

La referencia usada es `oc-bdu-dev`. Se han revisado estos Deployments:

- `bdu-consulta-datos-paciente`
- `bdu-actualiza-datos-paciente`
- `bdu-front`

## Configuracion usada por oc-bdu

Los Deployments de `oc-bdu-dev` revisados usan esta tolerancia:

```yaml
tolerations:
  - effect: NoSchedule
    key: kubernetes.azure.com/scalesetpriority
    operator: Equal
    value: spot
```

Tambien usan este `nodeSelector`:

```yaml
nodeSelector:
  kubernetes.azure.com/scalesetpriority: spot
```

Esta es la configuracion que debe aplicar `oc-vacunas-helm`.

## Configuracion aplicada en oc-vacunas-helm

El template `templates/generic/_Deployment.tpl` aplica a todos los Deployments:

```yaml
tolerations:
  - key: "kubernetes.azure.com/scalesetpriority"
    operator: "Equal"
    value: "spot"
    effect: "NoSchedule"
nodeSelector:
  kubernetes.azure.com/scalesetpriority: spot
```

## Taint objetivo

Los nodos Spot del cluster tienen esta taint:

```yaml
- key: kubernetes.azure.com/scalesetpriority
  value: spot
  effect: NoSchedule
```

Para que un pod pueda planificarse en esos nodos, el Deployment debe declarar la tolerancia equivalente.

## Node selector objetivo

Los pods deben seleccionar nodos con:

```yaml
kubernetes.azure.com/scalesetpriority: spot
```

Con esto el scheduler evita colocar los pods en node pools que no sean Spot.

## Comandos de verificacion

Ver tolerancias y `nodeSelector` en `oc-bdu-dev`:

```bash
kubectl -n oc-bdu-dev get deploy bdu-consulta-datos-paciente -o yaml \
  | sed -n '/tolerations:/,/containers:/p'

kubectl -n oc-bdu-dev get deploy bdu-consulta-datos-paciente -o yaml \
  | sed -n '/nodeSelector:/,/restartPolicy:/p'
```

Ver tolerancias y `nodeSelector` renderizados en `oc-vacunas`:

```bash
kubectl -n oc-vacunas get deploy <micro> -o yaml \
  | sed -n '/tolerations:/,/containers:/p'

kubectl -n oc-vacunas get deploy <micro> -o yaml \
  | sed -n '/nodeSelector:/,/restartPolicy:/p'
```

Ver el nodo donde queda planificado el pod:

```bash
kubectl -n oc-vacunas get pod -l app=<micro> -o wide
```

Si un pod se queda `Pending`, mira primero si hay sitio en el pool Spot: el
`nodeSelector` impide que caiga en cualquier otro nodo.

Ver taints de todos los nodos:

```bash
kubectl get nodes -o custom-columns='NAME:.metadata.name,TAINTS:.spec.taints'
```

## Checklist operativo

- El Deployment contiene tolerancia `kubernetes.azure.com/scalesetpriority=spot:NoSchedule`.
- El Deployment contiene `nodeSelector kubernetes.azure.com/scalesetpriority: spot`.
- El pod queda planificado en un nodo compatible con Spot.
- `kubectl rollout status deploy/<micro> -n oc-vacunas` termina correctamente.
