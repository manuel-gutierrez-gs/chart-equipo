# chart-equipo — el chart Helm del equipo (EDITABLE)

Fuente de trabajo del equipo para los despliegues manuales en DES. Se edita
como cualquier chart:

- `values-des.yaml`      -> configuración del entorno DES (imageTag, variables,
                            secretos, réplicas, recursos). Es lo que se toca
                            casi siempre.
- `projects\<micro>.yaml`-> spec fijo de cada micro (nombre, puertos, host de
                            ingress, rutas del VirtualService)
- `templates\`           -> plantillas: NO tocar
- `docs\`                -> notas operativas (Helm, nip.io, Oracle, Kafka,
                            tolerancias, kubeconfig)

Tras editar, comprueba que renderiza antes de desplegar:

```bash
helm template oc-vacunas . -n oc-vacunas -f values-des.yaml
```
