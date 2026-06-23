# Simulación de la arquitectura de comunicaciones de la microrred del CEDER-CIEMAT

Modelo de eventos discretos (MATLAB/Simulink + SimEvents) y scripts de análisis de tráfico para evaluar la arquitectura de comunicaciones que soporta la monitorización de la microrred del **CEDER-CIEMAT** (Soria).

Este repositorio acompaña al Trabajo Fin de Grado *"Diseño y evaluación de una arquitectura de comunicaciones para la monitorización de la microrred del CEDER-CIEMAT"* (ETSIT-UPM, 2026) y contiene todo el código necesario para reproducir las simulaciones y las figuras de la memoria.

## ¿Qué hace este código?

El trabajo modela el sistema de adquisición de datos (un sondeo Modbus desde Node-RED) como una cadena de **entidades, colas y servidores**, y evalúa por simulación si la arquitectura actual soporta estrategias de monitorización más exigentes (mayor frecuencia, captura de calidad de onda, sincrofasores). El hallazgo central es que el factor limitante no es el ancho de banda (la red se usa por debajo del 0,2 %), sino la **concurrencia del sondeador**, que hoy opera cerca de su límite.

El código permite:

1. **Analizar una captura de tráfico real** (Modbus TCP) para extraer la tasa de transacciones, el tiempo de respuesta y la concurrencia en vuelo.
2. **Simular** el comportamiento temporal del sistema bajo distintos escenarios de carga y concurrencia.
3. **Generar las figuras** de resultados de la memoria.

## Estructura del repositorio

```
.
├── parametros/
│   └── parametros.m     Parámetros del modelo (calibrados con la captura)
├── simulacion/
│   ├── barrido_S0.m        Barrido de escenarios S0–S2 (tasa × concurrencia)
│   ├── barrido_S3.m               Barrido del escenario S3 (calidad de onda)
│   ├── barrido_S4.m               Barrido del escenario S4 (sincrofasores)
│   ├── monitor_ceder_S0.slx       Modelo base S0–S2
│   ├── monitor_ceder_S3.slx       Modelo S3: calidad de onda
│   └── monitor_ceder_S4.slx       Modelo S4: sincrofasores
├── analisis_captura/
│   └── figuras_captura.m          Figuras 4.1 y 4.2
├── figuras/
│   └── figuras_resultados.m       Figuras 6.1 y 6.2
├── LICENSE
└── README.md
```

## Requisitos

- **MATLAB** R2021b o posterior
- **Simulink**
- **SimEvents** (extensión de simulación de eventos discretos)
- Para el análisis de la captura: **Wireshark / tshark**

## Cómo usarlo

### 1. Simulación de los escenarios

```matlab
% Desde la carpeta simulacion/, con el modelo monitor_ceder_S0.slx presente:

run('../parametros/parametros.m')   % carga los parámetros
barrido                              % ejecuta el barrido completo
```

El barrido recorre la malla de factores de escala de la tasa (`fFactor`) y concurrencias (`c`), simula cada combinación y guarda los resultados en `resultados.xlsx`, imprimiendo además la frontera de saturación por concurrencia.

Para una única ejecución de verificación, basta con cargar los parámetros y pulsar *Run* en el modelo: con `c = 4` y `fFactor = 1` la utilización de Node-RED debe estabilizarse en torno a **0,97**, reproduciendo el régimen real medido.

Los escenarios avanzados tienen su propio script y modelo:

```matlab

barrido_S3      % calidad de onda: satura el núcleo → resultados_S3.xlsx
barrido_S4      % sincrofasores: efecto sobre la concurrencia → resultados_S4.xlsx
```

`barrido_S3` requiere `monitor_ceder_S3.slx` (segundo generador para los analizadores, atributo de tamaño por entidad y cola finita para medir pérdidas);
`barrido_S4` requiere `monitor_ceder_S4.slx` (generador de sincrofasores a 50 tramas/s). Ambos escriben sus resultados en sendos `.xlsx`.

### 2. Análisis de una captura de tráfico

Primero, exporta las transacciones Modbus de la captura a un fichero de texto con tshark:

```bash
tshark -r captura.pcap -Y "modbus" -T fields -e frame.time_epoch -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport -e mbtcp.trans_id -E occurrence=f > modbus.tsv
```

Después, ejecuta el análisis en MATLAB:

```matlab
% Desde la carpeta analisis_captura/, con modbus.tsv presente:

figuras_captura
```

Genera las Figuras 4.1 (CDF del tiempo de respuesta) y 4.2 (concurrencia en vuelo) e imprime los estadísticos (mediana, media, p95, concurrencia media), que deben coincidir con los de la memoria.

### 3. Figuras de resultados

```matlab
% Desde la carpeta figuras/, con resultados.xlsx generado:

figuras_resultados
```

## Sobre los datos

Los **datos de tráfico reales no se incluyen** en este repositorio por motivos de
privacidad y seguridad: la captura original contiene direcciones IP de la
infraestructura de la microrred. El modelo reproduce el *comportamiento* del sistema
a partir de los parámetros agregados extraídos de esa captura (tasa, tiempo de
respuesta, concurrencia), no los equipos reales ni sus direcciones. Para reproducir
el análisis de captura con datos propios, sigue el procedimiento de la sección
anterior con tu propio fichero `.pcap`.

## Cómo citar

Si utilizas este código, puedes citar el Trabajo Fin de Grado:

> D. Varela Ramírez, "Diseño y evaluación de una arquitectura de comunicaciones para
> la monitorización de la microrred del CEDER-CIEMAT", Trabajo Fin de Grado, ETSIT,
> Universidad Politécnica de Madrid, 2026.

## Licencia

Código publicado bajo licencia [MIT](LICENSE).
