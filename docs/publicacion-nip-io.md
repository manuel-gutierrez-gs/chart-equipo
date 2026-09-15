# Publicación de servicios mediante nip.io

Cómo se publican los micros de `oc-vacunas` en DES con Istio y hosts `nip.io`.

`nip.io` resuelve cualquier nombre que lleve una IP embebida a esa misma IP.
`vacunas-movimientos.oc-vacunas.10.200.201.76.nip.io` resuelve a
`10.200.201.76`, que es el ingressgateway de Istio. Así no hace falta dar de
alta nada en el DNS del SAS.

## Qué declara cada micro

En `projects/<micro>.yaml`:

```yaml
ingress:
  enabled: true
  host: "vacunas-movimientos.oc-vacunas.10.200.201.76.nip.io"
  gateway: oc-vacunas-gateway
trafficManagement:
  ruleSet:
    - name: "route-to-openapi"
      prefix: "/vacunas-movimientos/openapi"
      urlRewrite: "/openapi"
    - name: "route-to-service"
      prefix: "/vacunas-movimientos/api/v1"
      urlRewrite: "/api/v1"
```

El `prefix` es lo que se pide desde fuera; el `urlRewrite`, el path que sirve
la aplicación de verdad.

Con `ingress.enabled: false` (consumidores Kafka puros) no se genera
VirtualService y el micro no queda expuesto.

## Gateway

`templates/gateway.yaml` recorre todos los `projects[]` con
`ingress.enabled: true` y añade sus hosts al Gateway `oc-vacunas-gateway`.
No hay hosts escritos a mano: al dar de alta un micro expuesto, su host entra
solo.

Si un host no está en el Gateway, Istio responde 404 aunque el
VirtualService exista.

## Camino de una petición

```text
cliente
  -> <micro>.oc-vacunas.10.200.201.76.nip.io
  -> istio-ingressgateway
  -> Gateway oc-vacunas-gateway
  -> VirtualService <micro>-virtualservice
  -> Service <micro>-service
  -> Pod <micro>:9080
```

## Comprobaciones

```bash
curl -sS http://vacunas-movimientos.oc-vacunas.10.200.201.76.nip.io/vacunas-movimientos/health/ready
curl -sS http://vacunas-movimientos.oc-vacunas.10.200.201.76.nip.io/vacunas-movimientos/openapi
```

```bash
kubectl -n oc-vacunas get gateway oc-vacunas-gateway -o yaml
kubectl -n oc-vacunas get virtualservice <micro>-virtualservice -o yaml
kubectl -n oc-vacunas get service <micro>-service -o yaml
```

## Llamadas entre micros

Dentro del clúster no se usa el host `nip.io`: se llama al Service interno,
que es más rápido y no pasa por el ingress.

```text
http://<micro>-service.oc-vacunas.svc.cluster.local:9080/api/v1/...
```

Ojo con la ruta: por dentro **no** lleva el prefijo con el nombre del micro,
porque ese prefijo lo quita el `urlRewrite` del VirtualService.

## Salida a hosts externos

Con el mesh en `REGISTRY_ONLY`, cualquier host externo sin ServiceEntry recibe
502. Los destinos externos se declaran en `values-des.yaml`:

```yaml
global:
  egress:
    - host: terminologias-des.pre.sas.junta-andalucia.es
      port: 80
      protocol: HTTP
```

## Checklist

- El micro tiene `ingress.enabled: true`, `ingress.host` y `ingress.gateway`.
- El micro tiene `trafficManagement.ruleSet` (sin él, VirtualService sin rutas).
- El host aparece en el Gateway renderizado.
- La IP embebida en el host es la del ingressgateway.
