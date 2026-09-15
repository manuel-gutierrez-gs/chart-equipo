# Configuración de Kafka securizado

Los micros del circuito de eventos (`lotes-inventario-ingesta-api`,
`vacunas-movimientos`, `notificar-actualizacion-estado-inmunizacion-api`)
hablan con un Kafka con SASL_SSL. La configuración tiene tres piezas: las
variables del conector, el Secret con las credenciales y el certificado de la
CA montado como fichero.

## 1. Variables del conector

En `values-des.yaml`, en `environment.configMap` del micro:

```yaml
MP_MESSAGING_CONNECTOR_LIBERTY_KAFKA_SECURITY_PROTOCOL: SASL_SSL
MP_MESSAGING_CONNECTOR_LIBERTY_KAFKA_SASL_MECHANISM: SCRAM-SHA-512
MP_MESSAGING_CONNECTOR_LIBERTY_KAFKA_SSL_TRUSTSTORE_TYPE: PEM
MP_MESSAGING_CONNECTOR_LIBERTY_KAFKA_SSL_TRUSTSTORE_LOCATION: /opt/certs/aks-kafka-cluster-ca-cert.crt
```

El topic va aparte, con la clave que espere cada micro
(`ACCIONES_TOPIC: acciones-vacunales-topic`,
`MOVIMIENTOS_TOPIC: movimientos-topic`…).

## 2. Credenciales

El bootstrap y el JAAS **no** están en el chart: viven en un Secret creado
aparte en el namespace, que el micro referencia por nombre.

```yaml
environment:
  secretRefs:
    - movimientos-kafka-secret
```

Ese Secret contiene:

```text
MP_MESSAGING_CONNECTOR_LIBERTY_KAFKA_BOOTSTRAP_SERVERS
MP_MESSAGING_CONNECTOR_LIBERTY_KAFKA_SASL_JAAS_CONFIG
```

Comprobar que existe y qué claves tiene, sin ver los valores:

```bash
kubectl -n oc-vacunas describe secret movimientos-kafka-secret
```

Si el Secret no existe, el pod arranca y se queda `NotReady`: el readiness
check de Kafka no consigue conectar.

## 3. Certificado de la CA

El certificado se monta como fichero desde otro Secret, en la ruta que apunta
`..._SSL_TRUSTSTORE_LOCATION`:

```yaml
volumeMounts:
  - name: kafka-ca-volume
    mountPath: /opt/certs/aks-kafka-cluster-ca-cert.crt
    readOnly: true
    subPath: aks-kafka-cluster-ca-cert.crt
volumes:
  - name: kafka-ca-volume
    secret:
      secretName: movimientos-kafka-ca-secret
      items:
        - key: aks-kafka-cluster-ca-cert.crt
          path: aks-kafka-cluster-ca-cert.crt
```

```bash
kubectl -n oc-vacunas describe secret movimientos-kafka-ca-secret
kubectl -n oc-vacunas exec deploy/<micro> -- ls -l /opt/certs/
```

## 4. Anotación de Istio

El sidecar de Istio no debe interceptar el tráfico a Kafka:

```yaml
podAnnotations:
  traffic.sidecar.istio.io/excludeOutboundPorts: '9093'
```

Sin esta anotación la conexión TLS con Kafka falla, porque el sidecar se mete
en medio de un handshake que ya es TLS.

## Comprobación final

```bash
kubectl -n oc-vacunas exec deploy/<micro> -- \
  curl -sS --max-time 30 http://localhost:9080/health/ready
```

Los micros del circuito tienen un check propio de Kafka en el readiness: si
sale `UP`, el conector ha llegado al clúster con las credenciales y el
certificado correctos.

## Checklist

- El Secret de credenciales y el de la CA existen en el namespace.
- El micro los referencia (`secretRefs` y `volumes`).
- La ruta de `..._SSL_TRUSTSTORE_LOCATION` coincide con el `mountPath`.
- El pod lleva `excludeOutboundPorts: '9093'`.
- `/health/ready` devuelve el check de Kafka en `UP`.
