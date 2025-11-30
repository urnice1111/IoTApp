#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de predicción para sensores IoT
Usa modelos estadísticos simples: promedios móviles, regresión temporal y patrones horarios
"""

import json
import sys
from datetime import datetime
try:
    import numpy as np
except ImportError:
    error_msg = json.dumps({
        'error': 'numpy no está instalado. Ejecuta: pip3 install numpy',
        'estacion': 'unknown',
        'fecha_prediccion': datetime.now().strftime('%Y-%m-%d'),
        'predicciones': []
    }, indent=2)
    print(error_msg, file=sys.stderr)
    sys.exit(1)

def weighted_moving_average(data, weights=None):
    """Calcula promedio móvil ponderado"""
    if len(data) == 0:
        return None
    if weights is None:
        weights = np.exp(np.linspace(-1, 0, len(data)))  # Pesos exponenciales
    weights = np.array(weights) / np.sum(weights)
    return np.average(data, weights=weights)

def linear_trend(data):
    """Calcula tendencia lineal simple"""
    if len(data) < 2:
        return 0.0
    x = np.arange(len(data))
    slope = np.polyfit(x, data, 1)[0]
    return slope

def hourly_pattern_factor(hour, historical_data_by_hour):
    """Calcula factor de patrón horario basado en datos históricos"""
    if hour not in historical_data_by_hour or len(historical_data_by_hour[hour]) == 0:
        return 1.0
    avg_hour = np.mean(historical_data_by_hour[hour])
    avg_all = np.mean([np.mean(vals) for vals in historical_data_by_hour.values() if len(vals) > 0])
    if avg_all == 0:
        return 1.0
    return avg_hour / avg_all

def predict_temperature(data_points, hours_ahead):
    """Predice temperatura usando promedio móvil ponderado + tendencia lineal"""
    if len(data_points) < 2:
        return data_points[-1] if len(data_points) > 0 else 22.0
    
    recent_data = data_points[-min(6, len(data_points)):]
    wma = weighted_moving_average(recent_data)
    trend = linear_trend(recent_data)
    prediction = wma + (trend * hours_ahead)
    prediction = max(10.0, min(35.0, prediction))
    return round(prediction, 2)

def predict_humidity(data_points, hours_ahead):
    """Predice humedad usando promedio móvil + tendencia"""
    if len(data_points) < 2:
        return data_points[-1] if len(data_points) > 0 else 50.0
    
    recent_data = data_points[-min(6, len(data_points)):]
    wma = weighted_moving_average(recent_data)
    trend = linear_trend(recent_data)
    prediction = wma + (trend * hours_ahead * 0.5)
    prediction = max(20.0, min(80.0, prediction))
    return round(prediction, 2)

def predict_air_quality(data_points, hours_ahead, historical_by_hour):
    """Predice calidad de aire usando promedio móvil + patrón horario"""
    if len(data_points) < 2:
        return data_points[-1] if len(data_points) > 0 else 60.0
    
    recent_data = data_points[-min(6, len(data_points)):]
    wma = weighted_moving_average(recent_data)
    target_hour = (datetime.now().hour + hours_ahead) % 24
    hour_factor = hourly_pattern_factor(target_hour, historical_by_hour)
    prediction = wma * hour_factor
    prediction = max(30.0, min(100.0, prediction))
    return round(prediction, 2)

def predict_pressure(data_points, hours_ahead):
    """Predice presión usando suavizado exponencial"""
    if len(data_points) < 1:
        return 775.0
    
    last_value = data_points[-1]
    
    if len(data_points) >= 2:
        recent_avg = np.mean(data_points[-min(3, len(data_points)):])
        trend = (recent_avg - np.mean(data_points[-min(6, len(data_points)):-3])) if len(data_points) >= 6 else 0
    else:
        trend = 0
    
    prediction = last_value + (trend * hours_ahead * 0.1)
    prediction = max(750.0, min(800.0, prediction))
    return round(prediction, 2)

def calculate_confidence(data_points, hours_ahead):
    """Calcula nivel de confianza basado en cantidad de datos y distancia temporal"""
    data_points_factor = min(len(data_points) / 12.0, 1.0)
    time_factor = max(0.3, 1.0 - (hours_ahead / 24.0))
    return round(data_points_factor * time_factor, 2)

def process_data(json_data):
    """Procesa datos JSON y genera predicciones para las próximas 24 horas"""
    try:
        data = json.loads(json_data) if isinstance(json_data, str) else json_data
        
        estacion = data.get('estacion', 'unknown')
        readings = data.get('readings', [])
        
        if len(readings) < 1:
            # Sin datos: retornar predicción con valores por defecto
            predictions = []
            for hour in range(24):
                predictions.append({
                    'hora': f"{hour:02d}:00",
                    'temperatura': 22.0,
                    'humedad': 50.0,
                    'calidadAire': 60.0,
                    'presion': 775.0,
                    'confianza': 0.3
                })
            return {
                'estacion': estacion,
                'fecha_prediccion': datetime.now().strftime('%Y-%m-%d'),
                'predicciones': predictions
            }
        
        # Extraer series temporales
        temperatures = [float(r.get('temperatura', 22.0)) for r in readings]
        humidities = [float(r.get('humedad', 50.0)) for r in readings]
        air_qualities = [float(r.get('calidadAire', 60.0)) for r in readings]
        pressures = [float(r.get('presion', 775.0)) for r in readings]
        hours = []
        for r in readings:
            hora_str = r.get('hora', '00:00')
            try:
                hours.append(int(hora_str.split(':')[0]))
            except:
                hours.append(0)
        
        # Agrupar calidad de aire por hora para patrón horario
        air_by_hour = {}
        for i, hour in enumerate(hours):
            if hour not in air_by_hour:
                air_by_hour[hour] = []
            air_by_hour[hour].append(air_qualities[i])
        
        # Generar predicciones para las próximas 24 horas
        predictions = []
        for hour in range(24):
            hours_ahead = hour
            confidence = calculate_confidence(temperatures, hours_ahead)
            
            predictions.append({
                'hora': f"{hour:02d}:00",
                'temperatura': predict_temperature(temperatures, hours_ahead),
                'humedad': predict_humidity(humidities, hours_ahead),
                'calidadAire': predict_air_quality(air_qualities, hours_ahead, air_by_hour),
                'presion': predict_pressure(pressures, hours_ahead),
                'confianza': confidence
            })
        
        return {
            'estacion': estacion,
            'fecha_prediccion': datetime.now().strftime('%Y-%m-%d'),
            'predicciones': predictions
        }
        
    except Exception as e:
        import traceback
        return {
            'error': f'Error procesando datos: {str(e)}. Traceback: {traceback.format_exc()}',
            'estacion': 'unknown',
            'fecha_prediccion': datetime.now().strftime('%Y-%m-%d'),
            'predicciones': []
        }

if __name__ == '__main__':
    # Leer datos desde stdin (JSON)
    input_data = sys.stdin.read()
    
    if not input_data:
        error_result = {
            'error': 'No se recibieron datos de entrada',
            'estacion': 'unknown',
            'fecha_prediccion': datetime.now().strftime('%Y-%m-%d'),
            'predicciones': []
        }
        print(json.dumps(error_result, indent=2))
        sys.exit(1)
    
    try:
        result = process_data(input_data)
        print(json.dumps(result, indent=2))
    except Exception as e:
        import traceback
        error_result = {
            'error': f'Error fatal: {str(e)}. Traceback: {traceback.format_exc()}',
            'estacion': 'unknown',
            'fecha_prediccion': datetime.now().strftime('%Y-%m-%d'),
            'predicciones': []
        }
        print(json.dumps(error_result, indent=2))
        sys.exit(1)
