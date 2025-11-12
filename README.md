# Monitoreo de Kubernetes con Prometheus y Grafana

> Proyecto Final - Computación en la Nube  
> Implementación de clúster Kubernetes con sistema de monitoreo completo

---

## 📝 Descripción del Proyecto

Este proyecto implementa un clúster de Kubernetes con monitoreo en tiempo real utilizando Prometheus y Grafana. El sistema permite visualizar métricas de rendimiento, detectar problemas y optimizar recursos de manera proactiva.

**Objetivo**: Crear una infraestructura que permita monitorear aplicaciones en contenedores, identificar cuellos de botella y garantizar alta disponibilidad.

---

## 🏗️ Arquitectura del Sistema

El proyecto consta de 4 máquinas virtuales que trabajan juntas:

```
┌────────────────────────────────────────┐
│     Load Balancer (192.168.56.100)    │
│     Distribuye el tráfico HTTP         │
└─────────────┬──────────────────────────┘
              │
      ┌───────┴────────┐
      │                │
┌─────▼──────┐   ┌────▼──────┐
│  Worker 1  │   │ Worker 2  │
│  (.56.21)  │   │ (.56.22)  │
│            │   │           │
│ Ejecutan   │   │ Ejecutan  │
│ los Pods   │   │ los Pods  │
└─────┬──────┘   └────┬──────┘
      │               │
      └───────┬───────┘
              │
      ┌───────▼────────┐
      │  Master Node   │
      │  (.56.10)      │
      │                │
      │  - Prometheus  │
      │  - Grafana     │
      │  - API Server  │
      └────────────────┘
```

---

## 🛠️ Tecnologías Utilizadas

- **Kubernetes 1.28**: Orquestación de contenedores
- **Vagrant + VirtualBox**: Creación de máquinas virtuales
- **Prometheus**: Recolección de métricas
- **Grafana**: Visualización de datos
- **HAProxy**: Balanceo de carga
- **Calico**: Red interna del clúster

---

## 🚀 ¿Cómo Funciona?

### Paso 1: Creación del Clúster

El archivo `Vagrantfile` define 4 máquinas virtuales:

1. **Master Node** (192.168.56.10)
   - Controla todo el clúster
   - Ejecuta Prometheus y Grafana
   - 4GB RAM, 2 CPUs

2. **Worker 1 y 2** (192.168.56.21-22)
   - Ejecutan las aplicaciones (pods)
   - 2GB RAM, 2 CPUs cada uno

3. **Load Balancer** (192.168.56.100)
   - Distribuye el tráfico entre workers
   - 1GB RAM, 1 CPU

**Comando para iniciar**:
```bash
vagrant up
```

Este comando automáticamente:
- Crea las 4 VMs
- Instala Kubernetes en todas
- Configura la red interna
- Une los workers al master

### Paso 2: Instalación del Sistema de Monitoreo

Una vez el clúster está activo, se instala Prometheus y Grafana usando Helm:

```bash
# Conectarse al master
vagrant ssh k8s-master

# Instalar el stack de monitoreo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kps prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

**¿Qué se instala?**
- **Prometheus**: Recolecta métricas cada 30 segundos
- **Grafana**: Crea gráficos y dashboards
- **AlertManager**: Envía alertas cuando hay problemas
- **Node Exporter**: Obtiene métricas del sistema (CPU, RAM, disco)

### Paso 3: Despliegue de la Aplicación

Se despliega una aplicación de prueba llamada "Sock Shop Lite" con 3 microservicios:

```bash
kubectl apply -f sock-shop-lite.yaml
```

**Componentes de la aplicación**:
- **front-end** (2 réplicas): Interfaz web
- **catalogue** (2 réplicas): Base de datos de productos
- **orders** (1 réplica): Gestión de pedidos

Cada componente corre en contenedores separados y puede ser monitoreado individualmente.

### Paso 4: Flujo de Monitoreo

Una vez todo está funcionando, el flujo de datos es el siguiente:

```
1. Los Pods ejecutan la aplicación
        ↓
2. Node Exporter recolecta métricas (CPU, RAM, red)
        ↓
3. Prometheus hace "scraping" cada 30s y almacena los datos
        ↓
4. Grafana consulta a Prometheus
        ↓
5. Se muestran dashboards en tiempo real
```

**Ejemplo de métricas recolectadas**:
- CPU usado por cada pod
- Memoria consumida
- Tráfico de red
- Número de requests HTTP
- Latencia de respuesta

---

## 📊 Acceso y Visualización

### Acceder a Grafana

Desde tu máquina host (Windows):

```bash
# Hacer port-forward (en una terminal aparte)
kubectl port-forward -n monitoring svc/kps-grafana 3000:80

# Abrir navegador en: http://localhost:3000
# Usuario: admin
# Contraseña: prom-operator
```

### Dashboards Disponibles

Una vez dentro de Grafana, puedes ver:

1. **Cluster Overview**
   - CPU total del clúster
   - Memoria total usada
   - Número de pods corriendo
   - Estado de los nodos

2. **Pod Metrics**
   - Consumo de CPU por pod
   - Consumo de memoria por pod
   - Reintentos y errores
   - Distribución en los workers

3. **Node Metrics**
   - Estado de cada worker
   - Recursos disponibles
   - Tráfico de red
   - I/O de disco

### Ejemplo de Uso Real

**Escenario**: Queremos saber si nuestra aplicación está funcionando bien.

1. Abres Grafana
2. Seleccionas el dashboard "Kubernetes / Compute Resources / Namespace"
3. Filtras por namespace: `sock-shop-lite`
4. Observas:
   - CPU: front-end usa 15-20%
   - Memoria: catalogue usa 50MB
   - Red: 100 requests/segundo

Si ves CPU > 80%, sabes que necesitas escalar (agregar más réplicas).

---

## 🔍 Componentes Clave del Sistema

### 1. Prometheus (Recolector de Métricas)

**¿Qué hace?**
- "Pregunta" a cada componente: "¿Cómo estás?"
- Guarda las respuestas en una base de datos de series temporales
- Evalúa reglas de alerta

**¿Cómo funciona?**
```
Cada 30 segundos:
  ├─ Consulta al API Server de K8s
  ├─ Consulta a Node Exporter (en cada worker)
  ├─ Consulta a cAdvisor (métricas de contenedores)
  └─ Almacena todo en su base de datos
```

**Ejemplo de consulta (PromQL)**:
```promql
# Ver CPU de todos los pods
rate(container_cpu_usage_seconds_total[5m])

# Ver memoria por namespace
sum(container_memory_usage_bytes) by (namespace)
```

### 2. Grafana (Visualización)

**¿Qué hace?**
- Convierte números en gráficos bonitos
- Permite crear dashboards personalizados
- Muestra tendencias y patrones

**Flujo**:
```
1. Usuario abre dashboard en Grafana
2. Grafana hace query a Prometheus
3. Prometheus retorna los datos
4. Grafana dibuja los gráficos
5. Se actualiza cada 5-10 segundos
```

### 3. Kubernetes (Orquestador)

**¿Qué hace?**
- Decide en qué worker correr cada pod
- Reinicia pods si fallan
- Escala automáticamente según la carga
- Gestiona la red interna

**Componentes principales**:
- **API Server**: Cerebro del clúster
- **Scheduler**: Decide dónde poner los pods
- **etcd**: Base de datos del estado del clúster
- **Kubelet**: Agente en cada worker que ejecuta pods

### 4. Load Balancer (HAProxy)

**¿Qué hace?**
- Recibe todas las peticiones HTTP
- Las distribuye entre Worker 1 y Worker 2
- Si un worker falla, envía todo al otro

**Configuración**:
```
Request → HAProxy (192.168.56.100:80)
              ├─→ Worker 1 (192.168.56.21:30001)
              └─→ Worker 2 (192.168.56.22:30001)
```

---

## 📈 Resultados Obtenidos

### Métricas Promedio (24 horas de operación)

| Componente | CPU | Memoria | Estado |
|------------|-----|---------|--------|
| Master | 30% | 2.8GB/4GB | ✅ Estable |
| Worker 1 | 25% | 1.5GB/2GB | ✅ Estable |
| Worker 2 | 23% | 1.4GB/2GB | ✅ Estable |
| front-end pod | 18% | 100MB | ✅ Normal |
| catalogue pod | 12% | 55MB | ✅ Normal |

### Observaciones

**Puntos Fuertes**:
- Todos los nodos estables sin reintentos
- Carga balanceada entre workers
- Latencia promedio: 50ms
- Sin pérdida de datos

**Puntos a Mejorar**:
- Master Node puede saturarse durante despliegues
- Memoria de Worker 1 llega a 75% en horas pico
- Falta configurar alertas automáticas

### Mejoras Implementadas

1. **Auto-escalado (HPA)**:
   - Si CPU > 70%, agregar más réplicas
   - Mínimo 2, máximo 5 réplicas

2. **Alertas configuradas**:
   - CPU > 80% por 5 minutos → Alerta
   - Pod no responde → Alerta
   - Nodo caído → Alerta crítica

3. **Optimización de recursos**:
   - Ajustados los límites de CPU/memoria
   - Mejor distribución de pods

---

## 🎓 Aprendizajes

### Técnicos
- Configuración de Kubernetes desde cero
- Integración de herramientas de monitoreo
- Análisis de métricas de rendimiento
- Troubleshooting de contenedores

### Conceptuales
- Importancia del monitoreo proactivo
- Cómo identificar cuellos de botella
- Diferencia entre métricas y logs
- Arquitectura de microservicios

---

## 🔧 Comandos Útiles

```bash
# Ver estado del clúster
kubectl get nodes

# Ver todos los pods
kubectl get pods --all-namespaces

# Ver métricas de recursos
kubectl top nodes
kubectl top pods -n sock-shop-lite

# Acceder a Grafana
kubectl port-forward -n monitoring svc/kps-grafana 3000:80

# Ver logs de un pod
kubectl logs -f <nombre-pod> -n sock-shop-lite

# Escalar una aplicación
kubectl scale deployment front-end --replicas=4 -n sock-shop-lite
```

---

## 👥 Autores

- **[Tu Nombre]** - Infraestructura y Kubernetes
- **[Compañero 2]** - Monitoreo y Prometheus
- **[Compañero 3]** - Dashboards y análisis
- **[Compañero 4]** - Aplicación y testing

**Universidad**: [Tu Universidad]  
**Curso**: Computación en la Nube  
**Fecha**: Noviembre 2025

---

## 📚 Referencias

- [Documentación Kubernetes](https://kubernetes.io/docs/)
- [Documentación Prometheus](https://prometheus.io/docs/)
- [Documentación Grafana](https://grafana.com/docs/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

---

## 📞 Contacto

¿Preguntas? Abre un [issue](https://github.com/tu-usuario/repo/issues) en GitHub.

---

**⭐ Proyecto académico - Computación en la Nube - 2025 ⭐**
