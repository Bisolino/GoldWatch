# GoldWatch - Rastreador de Oro para WoW

**GoldWatch** es un addon para World of Warcraft que rastrea tus ganancias de oro en tiempo real durante sesiones de farmeo. Calcula tu oro por hora (GPH) y ofrece proyecciones precisas con un sistema inteligente de detección de "hyperspawn".

## 📥 Instalación
1. Descarga versión actual
2. Extrae carpeta `GoldWatch` en `Interface\AddOns`
3. Inicia/recarga WoW

## 🚀 Cómo Empezar
1. **Abre el addon**: Teclea `/gw` o haz clic en el ícono del minimapa
2. **Entra a mazmorra**: Ve a tu zona de farmeo
3. **Inicia rastreo**: Haz clic en `Iniciar`
4. **Farmea normalmente**: Mata mobs, recolecta botín, completa misiones
5. **Vende a PNJs**: Vende todos los ítems farmeados
6. **Detén rastreo**: Haz clic en `Detener` al terminar

## ⚙️ Características Clave
| Función | Descripción |
|---------|-----------|
| 📊 Rastreo Tiempo Real | Monitorea cada cobre ganado |
| ⏱️ Proyección 60 Min | Estima ganancias horarias al ritmo actual |
| 🗺️ Datos por Mazmorra | Aprende tu GPH promedio por ubicación |
| 🚨 Anti-Hyperspawn | Detecta ganancias anormales y ajusta automáticamente |
| 📜 Historial Sesiones | Almacena todas las sesiones con estadísticas |

## 🚨 Sistema Anti-Hyperspawn
**¿Qué es hyperspawn?**  
Cuando los mobs respawn anormalmente rápido, creando patrones de oro irreales. GoldWatch compara GPH actual con promedios históricos.

**Modos de operación:**
- 🔔 `Alerta`: Notifica con sonido/texto (predeterminado)
- 📉 `Ajuste`: Reduce ganancias en 30% para realismo
- ⏸️ `Pausa`: Pausa rastreo por 10 minutos

Configura con: `/gw config`

## 💻 Comandos Útiles
| Comando | Función |
|---------|--------|
| `/gw` | Abre/cierra ventana principal |
| `/gw config` | Abre configuración |
| `/gw summary` | Muestra resumen en chat |
| `/gw reset` | Reinicia sesión actual |
| `/zd` | Muestra datos de mazmorra actual |
| `/gw history` | Abre historial de sesiones |

## ❓ Preguntas Frecuentes

### 1. ¿Qué es GoldWatch?
R: Addon que rastrea ganancias de oro en tiempo real durante sesiones de farmeo.

### 2. ¿Cómo inicio rastreo?
R: Entra a mazmorra y haz clic en `Iniciar`.

### 3. ¿Cuenta ventas en casa de subastas?
R: No, solo botín, ventas a PNJ y recompensas de misiones.

### 4. ¿Qué es Anti-Hyperspawn?
R: Sistema que detecta respawn anormal de mobs y ajusta valores.

### 5. ¿Cómo veo historial?
R: Usa `/gw history` o haz clic en `Historial`.

### 6. ¿Se guardan datos?
R: Sí, localmente en `WTF\Account\<tu_cuenta>\SavedVariables`.

### 7. ¿Soporta múltiples personajes?
R: ¡Sí! Datos de aprendizaje compartidos, sesiones individuales.

### 8. Lista de todos los comandos
| Comando | Función |
|---------|--------|
| /gw` | Abre/cierra ventana principal |
| /goldwatch | Alternativa para abrir/cerrar ventana principal |
| /gw config | Abre configuración del addon |
| /gw summary | Muestra resumen de sesión actual en chat |
| /gw summary all | Muestra historial completo de sesiones en chat |
| /gw reset | Reinicia sesión actual (datos en curso) |
| /gw reset data | Borra datos de aprendizaje (promedios de mazmorras) |
| /gw reset all | Borra TODOS los datos del addon (requiere confirmación) |
| /gw history | Abre historial de sesiones |
| /zd | Muestra datos de mazmorra actual (GPH promedio, muestras) |
| /zd all | Muestra datos de todas las mazmorras registradas |

---

### Soporte y actualizaciones
**Autor**: Levindo
**Versión**: 1.0.0
**Compatible con**: WoW Retail (v10.0+)