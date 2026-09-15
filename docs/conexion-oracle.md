# Conexión de un microservicio a Oracle

Los micros de `oc-vacunas` acceden a Oracle mediante un datasource de Open
Liberty cuyos valores llegan como variables de entorno.

## Dónde se declaran las credenciales

En `values-des.yaml`, en la entrada del micro, bajo
`environment.secrets` (**en plural**: el chart ignora `secret` en singular):

```yaml
- configFile: projects/lotes-inventario-ingesta-api.yaml
  spec:
    type: microservicio
    environment:
      secrets:
        DB_URL: jdbc:oracle:thin:@10.200.128.4:1522/bd19c02
        DB_USER: APP_VAC_INVENTARIO_LOTES
        DB_PASSWORD: APP_VAC_INVENTARIO_LOTES
        DB_DEFAULT_SCHEMA: OWN_VAC_INVENTARIO_LOTES
```

Helm genera con eso el Secret `<micro>-secret` (`templates/generic/_Secret.tpl`)
y el Deployment lo inyecta entero con `envFrom.secretRef`.

Los nombres de las variables **no son fijos**: cada micro usa los que espera su
`server.xml`. En el chart conviven `DB_URL`, `DATABASE_URL`, `DB_URL_IL`,
`DB_LEGACY_URL`… Antes de rellenar, mira el `server.xml` del micro.

Un micro con dos datasources declara los dos juegos de variables (por ejemplo
`DB_URL` y `DB_URL_IL`).

## Instancias en DES

- `10.200.128.4:1522/bd19c02` — la mayoría de los esquemas.
- `10.200.128.5:1521/bd11r202` — Oracle 11g del legacy, solo para los micros de
  sincronización.

## Datasource en el micro

El `server.xml` referencia las variables, nunca los valores:

```xml
<dataSource id="oracle" jndiName="jdbc/dataSource" transactional="true">
    <jdbcDriver libraryRef="jdbcLib"/>
    <properties.oracle URL="${DB_URL}" user="${DB_USER}" password="${DB_PASSWORD}"/>
    <onConnect>ALTER SESSION SET CURRENT_SCHEMA=${DB_DEFAULT_SCHEMA}</onConnect>
</dataSource>
<library id="jdbcLib">
    <fileset dir="/config/usr/shared/resources" includes="ojdbc*.jar"/>
</library>
```

Dos cosas que rompen el arranque en silencio:

- El `jndiName` del `server.xml` tiene que ser exactamente el mismo que el
  `<jta-data-source>` del `persistence.xml`. Si no coinciden, el micro arranca
  y falla en la primera consulta.
- La imagen tiene que llevar el driver. En `plantillas-backend/Dockerfile` la
  línea que copia `usr/shared/resources/` viene comentada: hay que activarla
  cuando el `server.xml` define un datasource Oracle.

## Comprobaciones

```bash
kubectl -n oc-vacunas describe secret <micro>-secret
```

Variables efectivas en el pod, sin enseñar la contraseña:

```bash
kubectl -n oc-vacunas exec deploy/<micro> -- printenv \
  | grep -E 'DB_|DATABASE_' | sed -E 's/(PASS[A-Z_]*)=.*/\1=***/'
```

```bash
kubectl -n oc-vacunas logs deploy/<micro> --tail=200
```

## Checklist

- Las variables van en `environment.secrets`, no en el ConfigMap.
- Sus nombres coinciden con los que usa el `server.xml` del micro.
- `jndiName` del `server.xml` == `<jta-data-source>` del `persistence.xml`.
- La imagen incluye el driver `ojdbc`.
- El esquema de `DB_DEFAULT_SCHEMA` es el operativo, no el usuario de conexión.
