# Uso de kubeconfig para acceder al clúster

El fichero `kubeconfig` de la raíz del paquete da acceso al clúster AKS de DES.
Es material sensible: no se sube a git, no se pega en incidencias y no se
comparte fuera de canal privado.

El contexto que interesa es `oc-vacunas-admin@AKS-CLUSTER-DES01`, que ya viene
como activo. El fichero trae también otros contextos (docker-desktop, OKD) que
no se usan aquí.

## Instalación (lo habitual)

`kubectl` y `helm` buscan por defecto un fichero llamado `config`, sin
extensión, dentro de la carpeta `.kube` del perfil del usuario. Copia ahí el
fichero **renombrándolo a `config`**:

```text
C:\Users\<tu-usuario>\.kube\config
```

En PowerShell:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.kube" | Out-Null
Copy-Item ".\kubeconfig" "$env:USERPROFILE\.kube\config"
```

> ⚠️ Si ya tenías un `.kube\config`, esto lo sustituye y pierdes los contextos
> que tuvieras (Docker Desktop, OKD, otros clústeres). Haz copia antes:
>
> ```powershell
> Copy-Item "$env:USERPROFILE\.kube\config" "$env:USERPROFILE\.kube\config.backup"
> ```

Hecho esto, `kubectl` y `helm` funcionan sin indicar nada más:

```bash
kubectl config current-context
kubectl -n oc-vacunas get pod
```

## Alternativa sin tocar tu `.kube\config`

Apuntar a él solo para esa sesión, dejando intacto lo que ya tengas.

PowerShell:

```powershell
$env:KUBECONFIG = "C:\ruta\despliegue-manual\kubeconfig"
```

Bash:

```bash
export KUBECONFIG=/ruta/despliegue-manual/kubeconfig
```

O pasándolo en cada comando:

```bash
kubectl --kubeconfig /ruta/kubeconfig -n oc-vacunas get pod
helm --kubeconfig /ruta/kubeconfig list -n oc-vacunas
```

## Cambiar de contexto

Si conviven varios en el mismo fichero:

```bash
kubectl config get-contexts
kubectl config use-context oc-vacunas-admin@AKS-CLUSTER-DES01
```

## Validar el acceso

```bash
kubectl config current-context
kubectl cluster-info
kubectl -n oc-vacunas get deploy,pod
```

El API del AKS es privado: solo responde a través de la VPN de Azure. Si
`cluster-info` se queda colgado o da timeout, revisa la VPN antes de mirar
nada del kubeconfig.

## Comprobar permisos

```bash
kubectl auth can-i create deployments -n oc-vacunas
kubectl auth can-i get secrets -n oc-vacunas
kubectl auth can-i create virtualservices.networking.istio.io -n oc-vacunas
```

Los ServiceEntry de `global.egress` necesitan permiso propio; si falta, el
`helm upgrade` falla con `Forbidden` sobre
`serviceentries.networking.istio.io`. Ese permiso lo concede plataforma.

## Ver el estado sin línea de comandos

Sobre el mismo kubeconfig funcionan:

- `k9s` — interfaz de terminal (<https://k9scli.io/>)
- OpenLens — cliente gráfico

Sirven para mirar y diagnosticar; el despliegue se sigue haciendo con `helm`.

## Diagnóstico rápido

Helm no encuentra el release:

```bash
helm list -A | grep oc-vacunas
```

El namespace no aparece:

```bash
kubectl get namespace oc-vacunas
```

## Reglas de seguridad

- No guardar el kubeconfig dentro de un repositorio.
- No pegar certificados, tokens ni claves en commits, incidencias o logs.
- No compartir salidas completas de `kubectl config view`.
