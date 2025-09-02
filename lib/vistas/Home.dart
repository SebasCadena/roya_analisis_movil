import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'consulta_api.dart';
import 'pasos_dae.dart';

class WeatherData {
  final String city;
  final double temperature;
  final int humidity;
  final String description;

  WeatherData({
    required this.city,
    required this.temperature,
    required this.humidity,
    required this.description,
  });
}

class Home extends StatefulWidget {
  const Home({super.key, required this.title});

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  WeatherData? _weatherData;
  bool _loadingWeather = true;
  String _weatherError = '';

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    
    setState(() {
      _loadingWeather = true;
      _weatherError = '';
    });

    try {
      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _weatherError = 'El servicio de ubicación está desactivado.';
            _loadingWeather = false;
          });
        }
        return;
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _weatherError = 'Permiso de ubicación denegado.';
              _loadingWeather = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _weatherError = 'Permiso de ubicación denegado permanentemente.';
            _loadingWeather = false;
          });
        }
        return;
      }

      // Obtener ubicación actual con timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Consultar API del clima
      final apiKey = '388b84ec520d37a9e7f7ac52ee4876ad';
      final url = 'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric&lang=es';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _weatherData = WeatherData(
              city: data['name'] ?? 'Ubicación desconocida',
              temperature: (data['main']['temp'] as num?)?.toDouble() ?? 0.0,
              humidity: data['main']['humidity'] ?? 0,
              description: data['weather'][0]['description'] ?? 'Sin descripción',
            );
            _loadingWeather = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _weatherError = 'No se pudo obtener información del clima. Código: ${response.statusCode}';
            _loadingWeather = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherError = 'Error al obtener el clima: ${e.toString()}';
          _loadingWeather = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.eco, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text(
              'Evaluador de Roya del Café',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header principal con gradiente verde
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _loadingWeather
                    ? const Column(
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 12),
                          Text(
                            'Obteniendo información del clima...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      )
                    : _weatherError.isNotEmpty
                        ? Column(
                            children: [
                              const Icon(Icons.cloud_off, color: Colors.white, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'Error al obtener el clima',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _weatherError,
                                style: const TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : _weatherData != null
                            ? Column(
                                children: [
                                  // Header del clima
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.wb_sunny, color: Colors.white, size: 32),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Clima Actual',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Información principal del clima
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Column(
                                      children: [
                                        // Ubicación
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.location_on, color: Colors.white, size: 20),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                _weatherData!.city,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 15),
                                        
                                        // Temperatura principal
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '${_weatherData!.temperature.toStringAsFixed(0)}°',
                                              style: const TextStyle(
                                                fontSize: 48,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'C',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    color: Colors.white.withOpacity(0.8),
                                                  ),
                                                ),
                                                Text(
                                                  _weatherData!.description,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white.withOpacity(0.9),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        
                                        // Información adicional
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildWeatherInfo(
                                              icon: Icons.water_drop,
                                              label: 'Humedad',
                                              value: '${_weatherData!.humidity}%',
                                            ),
                                            Container(
                                              height: 40,
                                              width: 1,
                                              color: Colors.white.withOpacity(0.3),
                                            ),
                                            _buildWeatherInfo(
                                              icon: Icons.thermostat,
                                              label: 'Sensación',
                                              value: '${_weatherData!.temperature.toStringAsFixed(1)}°C',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  const Icon(Icons.help_outline, color: Colors.white, size: 48),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No hay datos de clima disponibles',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
              ),
            ),

            const SizedBox(height: 30),

            // Sección de navegación con título
            Text(
              'Herramientas de Evaluación:',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 16),
            
            // Cards de navegación estilizadas
            _construirCardNavegacion(
              titulo: 'Protocolo DAE',
              descripcion: 'Consulta los pasos del Diagrama de Área Estándar para evaluación de roya',
              icono: Icons.agriculture,
              color: Colors.green[700]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PasosDAEPage()),
                );
              },
            ),

            const SizedBox(height: 16),

            _construirCardNavegacion(
              titulo: 'Iniciar Análisis',
              descripcion: 'Analiza imágenes de hojas para detectar y evaluar la presencia de roya',
              icono: Icons.camera_alt,
              color: Colors.teal[600]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ConsultaApi()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirCardNavegacion({
    required String titulo,
    required String descripcion,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        elevation: 8,
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icono, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        descripcion,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
