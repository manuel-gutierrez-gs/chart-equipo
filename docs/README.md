# Documentación de despliegue e infraestructura

Notas operativas del chart `oc-vacunas-helm` para el entorno **DES**
(namespace `oc-vacunas`, release Helm `oc-vacunas`).

La fuente de verdad de la configuración es `../values-des.yaml`. Si algo de
aquí no cuadra con ese fichero, manda el fichero.

## Índice

1. [Despliegue en Azure AKS mediante Helm](./despliegue-aks-helm.md)
2. [Publicación de servicios mediante nip.io](./publicacion-nip-io.md)
3. [Conexión de un microservicio a Oracle](./conexion-oracle.md)
4. [Configuración de Kafka securizado](./kafka-securizado.md)
5. [Tolerancias obligatorias en Azure AKS](./tolerancias-aks.md)
6. [Uso de kubeconfig para acceder al clúster](./uso-kubeconfig.md)

## Datos del entorno

- Namespace: `oc-vacunas`
- Release Helm: `oc-vacunas`
- Values: `values-des.yaml`
- Registro de imágenes: `solutia.azurecr.io/oc-vacunas`
- Contexto kubeconfig: `oc-vacunas-admin@AKS-CLUSTER-DES01`
- Front: `vacunas-app-mf`
