# Sistema de Predicción IoT - Guía de Implementación

## Resumen

Se ha implementado un sistema completo de predicción para sensores IoT que predice temperatura, humedad, calidad de aire y presión para las próximas 24 horas usando modelos estadísticos simples (promedios móviles, regresión temporal, patrones horarios).

## Archivos Creados

### Servidor (PHP/Python)

Todos los archivos están en la carpeta `server/` y deben copiarse a tu servidor en `/api_handler_swift/`:

1. **`predict_iot.py`** - Script Python con los modelos de predicción
2. **`train_and_predict.php`** - Script PHP que extrae datos de MySQL y ejecuta Python
3. **`get_predictions.php`** - Endpoint público para obtener predicciones
4. **`requirements.txt`** - Dependencias Python (solo numpy)
5. **`README.md`** - Instrucciones de instalación del servidor

### iOS App (Swift)

1. **`Structuras/PredictionModels.swift`** - Modelos de datos para predicciones
2. **`Models/APIClient.swift`** - Extendido con método `fetchPredictions()`
3. **`Views/PredictionView.swift`** - Vista completa con gráficos y lista de predicciones
4. **`Views/LocationInfoView.swift`** - Modificado para agregar botón de predicciones

## Configuración del Servidor

### Paso 1: Copiar archivos

```bash
# Copia todos los archivos de server/ a tu servidor
cp -r server/* /ruta/tu/servidor/api_handler_swift/
```

### Paso 2: Instalar dependencias Python

```bash
cd /ruta/tu/servidor/api_handler_swift/
pip3 install -r requirements.txt
```

### Paso 3: Configurar permisos

```bash
chmod +x predict_iot.py
mkdir -p cache_predictions
chmod 755 cache_predictions
```

### Paso 4: Configurar credenciales MySQL

Edita `train_and_predict.php` y `get_predictions.php`:

```php
$db_host = 'localhost';  // Tu host MySQL
$db_user = 'root';       // Tu usuario MySQL
$db_pass = '';           // Tu contraseña MySQL
$db_name = 'estacion_prueba';  // Tu base de datos
```

### Paso 5: Verificar funcionamiento

```bash
# Probar Python directamente
echo '{"estacion":"biblioteca","readings":[{"fecha":"2025-11-28","hora":"14:00:00","temperatura":24.5,"humedad":45.0,"presion":775.0,"calidadAire":62.0}]}' | python3 predict_iot.py

# Probar desde PHP
curl "http://192.168.1.216/api_handler_swift/get_predictions.php?estacion=biblioteca"
```

## Uso en la App iOS

### Cómo funciona

1. El usuario abre una estación en la app
2. Ve un botón "Ver Predicciones (24h)" en la parte inferior
3. Al tocar el botón, se abre una vista con:
   - Gráfico interactivo de línea para la variable seleccionada
   - Selector de variable (Temperatura, Humedad, Calidad de Aire, Presión)
   - Lista de predicciones hora por hora con indicadores de confianza

### Características

- **Cache automático**: Las predicciones se cachean por 1 hora en el servidor
- **Actualización**: Pull-to-refresh para actualizar manualmente
- **Gráficos**: Visualización clara de tendencias para las próximas 24 horas
- **Confianza**: Cada predicción muestra un nivel de confianza basado en la cantidad de datos disponibles

## Modelos de Predicción

### Temperatura y Humedad
- **Método**: Promedio móvil ponderado + tendencia lineal
- **Características**: Usa las últimas 6 horas para calcular promedio y tendencia
- **Predicción**: `promedio + (tendencia × horas_adelante)`

### Calidad de Aire
- **Método**: Promedio móvil + patrón horario
- **Características**: Identifica patrones por hora del día
- **Predicción**: `promedio × factor_horario`

### Presión
- **Método**: Suavizado exponencial
- **Características**: Cambios graduales (presión varía lentamente)
- **Predicción**: `último_valor + (tendencia_suave × horas_adelante × 0.1)`

### Nivel de Confianza
- Basado en cantidad de datos históricos disponibles
- Decrece con el horizonte temporal (menos confianza a más horas)
- Rango: 0.3 - 1.0

## Solución de Problemas

### Error: "No se pudieron obtener las predicciones"
- Verifica que PHP pueda ejecutar Python3
- Revisa los logs de PHP
- Verifica que las credenciales MySQL sean correctas

### Error: "Error ejecutando Python"
- Asegúrate de que numpy esté instalado: `pip3 install numpy`
- Verifica que `python3` esté en el PATH del servidor
- Revisa permisos del archivo `predict_iot.py`

### Predicciones no aparecen en la app
- Verifica que el endpoint sea accesible desde tu red
- Revisa la consola de Xcode para errores de decodificación JSON
- Confirma que la IP del servidor sea correcta (192.168.1.216)

### Predicciones muy conservadoras
- Es normal con pocos datos (< 1 semana)
- Los modelos están diseñados para ser conservadores y evitar predicciones erráticas
- A medida que tengas más datos, las predicciones mejorarán

## Próximos Pasos (Opcional)

1. **Mejorar modelos**: Una vez tengas más datos (2-4 semanas), puedes mejorar los modelos
2. **Agregar más variables**: Puedes extender los modelos para considerar variables externas
3. **Alertas**: Implementar notificaciones cuando las predicciones indiquen valores extremos
4. **Comparación histórica**: Mostrar predicciones vs valores reales para validar el modelo

## Notas Técnicas

- Los modelos están diseñados para funcionar con **mínimos datos** (incluso con solo 2 lecturas)
- El sistema es **robusto** y tiene fallbacks para casos de datos insuficientes
- Las predicciones se **cachean** para reducir carga en el servidor
- El código es **interpretable** y fácil de ajustar según tus necesidades

