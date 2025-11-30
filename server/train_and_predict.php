<?php
/**
 * Script PHP para entrenar modelos y generar predicciones
 * Extrae datos de MySQL, ejecuta Python y cachea resultados
 */

header('Content-Type: application/json; charset=utf-8');

// Configuración de base de datos (AJUSTAR SEGÚN TU CONFIGURACIÓN)
$db_host = 'localhost';
$db_user = 'root';  // AJUSTAR
$db_pass = '';      // AJUSTAR
$db_name = 'estacion_prueba';

// Obtener parámetros
$estacion = isset($_GET['estacion']) ? $_GET['estacion'] : null;
$cache_dir = __DIR__ . '/cache_predictions';
$cache_duration = 3600; // 1 hora en segundos

// Crear directorio de cache si no existe
if (!file_exists($cache_dir)) {
    mkdir($cache_dir, 0755, true);
}

if (!$estacion) {
    echo json_encode([
        'error' => 'Estación no especificada',
        'estacion' => 'unknown',
        'fecha_prediccion' => date('Y-m-d'),
        'predicciones' => []
    ]);
    exit;
}

// Verificar cache
$cache_file = $cache_dir . '/' . md5($estacion) . '.json';
if (file_exists($cache_file) && (time() - filemtime($cache_file)) < $cache_duration) {
    // Retornar cache si es reciente
    echo file_get_contents($cache_file);
    exit;
}

try {
    // Conectar a MySQL
    $conn = new mysqli($db_host, $db_user, $db_pass, $db_name);
    
    if ($conn->connect_error) {
        throw new Exception("Error de conexión a MySQL: " . $conn->connect_error);
    }
    
    // Obtener ID de estación
    $stmt = $conn->prepare("SELECT idEstacion FROM estacion WHERE nombreEstacion = ?");
    $stmt->bind_param("s", $estacion);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception("Estación no encontrada: " . $estacion);
    }
    
    $row = $result->fetch_assoc();
    $idEstacion = $row['idEstacion'];
    
    // Obtener datos históricos de las últimas 48 horas
    $date_limit = date('Y-m-d H:i:s', strtotime('-48 hours'));
    
    // Obtener última lectura completa para tener valores por defecto
    $fallback_query = "
        SELECT 
            (SELECT lecturaTemperatura FROM temperatura WHERE idEstacion = ? ORDER BY fechaLectura DESC, horaLectura DESC LIMIT 1) as temperatura,
            (SELECT lecturaHumedad FROM humedad WHERE idEstacion = ? ORDER BY fechaLectura DESC, horaLectura DESC LIMIT 1) as humedad,
            (SELECT lecturaPresion FROM presion WHERE idEstacion = ? ORDER BY fechaLectura DESC, horaLectura DESC LIMIT 1) as presion,
            (SELECT lecturaAire FROM calidad_de_aire WHERE idEstacion = ? ORDER BY fechaLectura DESC, horaLectura DESC LIMIT 1) as calidadAire,
            (SELECT CONCAT(fechaLectura, ' ', horaLectura) FROM temperatura WHERE idEstacion = ? ORDER BY fechaLectura DESC, horaLectura DESC LIMIT 1) as fecha_hora
    ";
    
    $stmt = $conn->prepare($fallback_query);
    $stmt->bind_param("iiiii", $idEstacion, $idEstacion, $idEstacion, $idEstacion, $idEstacion);
    $stmt->execute();
    $fallback_result = $stmt->get_result();
    $fallback_data = $fallback_result->fetch_assoc();
    
    $default_temp = floatval($fallback_data['temperatura'] ?? 22.0);
    $default_hum = floatval($fallback_data['humedad'] ?? 50.0);
    $default_pres = floatval($fallback_data['presion'] ?? 775.0);
    $default_air = floatval($fallback_data['calidadAire'] ?? 60.0);
    $default_datetime = $fallback_data['fecha_hora'] ?? date('Y-m-d H:i:s');
    
    list($default_date, $default_time) = explode(' ', $default_datetime);
    
    // Consulta para obtener todas las lecturas recientes agrupadas
    $query = "
        SELECT 
            t.fechaLectura,
            t.horaLectura,
            t.lecturaTemperatura as temperatura,
            COALESCE(h.lecturaHumedad, ?) as humedad,
            COALESCE(p.lecturaPresion, ?) as presion,
            COALESCE(a.lecturaAire, ?) as calidadAire
        FROM temperatura t
        LEFT JOIN humedad h ON t.idEstacion = h.idEstacion 
            AND t.fechaLectura = h.fechaLectura 
            AND t.horaLectura = h.horaLectura
        LEFT JOIN presion p ON t.idEstacion = p.idEstacion 
            AND t.fechaLectura = p.fechaLectura 
            AND ABS(TIME_TO_SEC(TIMEDIFF(t.horaLectura, p.horaLectura))) < 300
        LEFT JOIN calidad_de_aire a ON t.idEstacion = a.idEstacion 
            AND t.fechaLectura = a.fechaLectura 
            AND ABS(TIME_TO_SEC(TIMEDIFF(t.horaLectura, a.horaLectura))) < 300
        WHERE t.idEstacion = ? 
        AND CONCAT(t.fechaLectura, ' ', t.horaLectura) >= ?
        ORDER BY t.fechaLectura ASC, t.horaLectura ASC
        LIMIT 100
    ";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("dddis", $default_hum, $default_pres, $default_air, $idEstacion, $date_limit);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $readings = [];
    while ($row = $result->fetch_assoc()) {
        $readings[] = [
            'fecha' => $row['fechaLectura'],
            'hora' => $row['horaLectura'],
            'temperatura' => floatval($row['temperatura'] ?? $default_temp),
            'humedad' => floatval($row['humedad'] ?? $default_hum),
            'presion' => floatval($row['presion'] ?? $default_pres),
            'calidadAire' => floatval($row['calidadAire'] ?? $default_air)
        ];
    }
    
    // Si no hay lecturas, usar valores por defecto
    if (empty($readings)) {
        $readings = [[
            'fecha' => $default_date,
            'hora' => $default_time,
            'temperatura' => $default_temp,
            'humedad' => $default_hum,
            'presion' => $default_pres,
            'calidadAire' => $default_air
        ]];
    }
    
    // Preparar datos para Python
    $python_input = [
        'estacion' => $estacion,
        'readings' => $readings
    ];
    
    $json_input = json_encode($python_input);
    
    // Ejecutar script Python
    $python_script = __DIR__ . '/predict_iot.py';
    
    if (!file_exists($python_script)) {
        throw new Exception("Script Python no encontrado: " . $python_script);
    }
    
    $python_cmd = "python3 " . escapeshellarg($python_script) . " 2>&1";
    
    // Usar proc_open para mejor manejo de entrada/salida
    $descriptorspec = [
        0 => ["pipe", "r"],  // stdin
        1 => ["pipe", "w"],  // stdout
        2 => ["pipe", "w"]   // stderr
    ];
    
    $process = proc_open($python_cmd, $descriptorspec, $pipes);
    
    if (!is_resource($process)) {
        throw new Exception("No se pudo ejecutar el script Python. Verifica que Python3 esté instalado y en el PATH.");
    }
    
    // Escribir datos a stdin
    fwrite($pipes[0], $json_input);
    fclose($pipes[0]);
    
    // Leer salida
    $output = stream_get_contents($pipes[1]);
    $errors = stream_get_contents($pipes[2]);
    fclose($pipes[1]);
    fclose($pipes[2]);
    
    $return_code = proc_close($process);
    
    if ($return_code !== 0 || empty($output)) {
        $error_msg = "Error ejecutando Python (código: $return_code)";
        if ($errors) {
            $error_msg .= ". Detalles: " . trim($errors);
        }
        if ($output && json_decode($output, true) === null) {
            $error_msg .= ". Salida: " . substr(trim($output), 0, 200);
        }
        // Agregar información de debugging
        $error_msg .= ". Script: " . $python_script . ". Existe: " . (file_exists($python_script) ? 'sí' : 'no');
        throw new Exception($error_msg);
    }
    
    // Validar que la salida sea JSON válido
    $result = json_decode($output, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception("Respuesta inválida de Python: " . substr($output, 0, 200));
    }
    
    // Guardar en cache
    file_put_contents($cache_file, $output);
    echo $output;
    
    $conn->close();
    
} catch (Exception $e) {
    echo json_encode([
        'error' => $e->getMessage(),
        'estacion' => $estacion ?? 'unknown',
        'fecha_prediccion' => date('Y-m-d'),
        'predicciones' => []
    ]);
}
