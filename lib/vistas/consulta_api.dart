import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';

// ========================================
// CONFIGURACIÓN DE LA API
// ========================================
// Para cambiar la URL de la API, solo modifica esta línea:
const String API_BASE_URL = 'https://3a9298e0c474.ngrok-free.app';

// Ejemplos de otras URLs:
// const String API_BASE_URL = 'https://tu-nueva-url.ngrok-free.app';
// const String API_BASE_URL = 'https://mi-servidor.com';
// const String API_BASE_URL = 'http://localhost:8000'; // Para desarrollo local
// ========================================

class ConsultaApi extends StatefulWidget {
  const ConsultaApi({super.key});

  @override
  State<ConsultaApi> createState() => _ConsultaApiState();
}

class _ConsultaApiState extends State<ConsultaApi> {
  void _seleccionarFuenteImagenRoya(int filaIndex, int hojaIndex) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de la galería'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _analizarImagenRoya(filaIndex, hojaIndex, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto con la cámara'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _analizarImagenRoya(filaIndex, hojaIndex, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _seleccionarFuenteImagen() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de la galería'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  segmentarImagen(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto con la cámara'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  segmentarImagen(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  String resultado = 'Esperando respuesta...';
  String resultadoSegmentacion = 'Selecciona una imagen para segmentar...';
  String resultadoRoya = 'Configura la tabla para comenzar el análisis...';
  bool _cargandoApi = false;
  bool _cargandoSegmentacion = false;
  Uint8List? _imagenSegmentada; // Para almacenar la imagen recibida
  Uint8List? _imagenOriginal; // Para almacenar la imagen original
  List<Map<String, dynamic>>?
  _datosTablaRoya; // Para almacenar datos de la tabla

  // Variables para configuración dinámica de tabla
  int _numeroFilas = 3; // Número de filas por defecto
  bool _tablaCreada = false; // Si la tabla ya fue creada
  List<TextEditingController> _controllersHojasPresentes = [];
  List<TextEditingController> _controllersHojasConRoya = [];
  int _maxHojasConRoya =
      0; // Máximo número de hojas con roya para generar columnas

  // Variables para análisis de imágenes
  Map<String, bool> _analizandoImagen =
      {}; // Para tracking de análisis en progreso
  Map<String, double> _resultadosAnalisis = {}; // Para almacenar resultados

  Future<void> consultarApi() async {
    setState(() {
      _cargandoApi = true;
      resultado = 'Consultando API...';
    });

    try {
      final url = Uri.parse(API_BASE_URL); // Usar la variable constante
      final respuesta = await http.get(url);
      if (respuesta.statusCode == 200) {
        final data = json.decode(respuesta.body);
        setState(() {
          resultado =
              'API activa: ${data['status']}, Modelo: ${data['modelo']}';
        });
      } else {
        setState(() {
          resultado = 'Error: ${respuesta.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        resultado = 'Error al conectar con la API: $e';
      });
    } finally {
      setState(() {
        _cargandoApi = false;
      });
    }
  }

  Future<void> segmentarImagen(ImageSource source) async {
    setState(() {
      _cargandoSegmentacion = true;
      resultadoSegmentacion = 'Abriendo selector de imágenes...';
      _imagenSegmentada = null;
      _imagenOriginal = null;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile == null) {
        setState(() {
          resultadoSegmentacion = 'No se seleccionó ninguna imagen';
        });
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name;
      final extension = fileName.split('.').last.toLowerCase();

      setState(() {
        resultadoSegmentacion = 'Validando archivo $fileName...';
        _imagenOriginal = bytes;
      });

      if (bytes.isEmpty) {
        setState(() {
          resultadoSegmentacion = '❌ Error: El archivo está vacío';
        });
        return;
      }

      if (bytes.length > 10 * 1024 * 1024) {
        setState(() {
          resultadoSegmentacion = '❌ Error: El archivo es demasiado grande (máx 10MB)';
        });
        return;
      }

      final url = Uri.parse('$API_BASE_URL/segment-leaf');
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Accept': 'application/json, image/png, */*',
        'User-Agent': 'Flutter-App/1.0',
        'ngrok-skip-browser-warning': 'true',
      });

      String contentType = 'image/jpeg';
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (extension == 'gif') {
        contentType = 'image/gif';
      } else if (extension == 'bmp') {
        contentType = 'image/bmp';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      );
      request.fields['filename'] = fileName;

      setState(() {
        resultadoSegmentacion = 'Subiendo imagen $fileName (${(bytes.length / 1024).toStringAsFixed(2)} KB)...';
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        _imagenSegmentada = response.bodyBytes;
        setState(() {
          resultadoSegmentacion = '✅ ¡Imagen segmentada exitosamente!\n📏 Tamaño: ${(response.bodyBytes.length / 1024).toStringAsFixed(2)} KB\n🎯 Tipo: ${response.headers['content-type'] ?? 'desconocido'}';
        });
      } else {
        String errorDetails = response.body.isNotEmpty ? response.body : 'Sin detalles del error';
        setState(() {
          resultadoSegmentacion = '❌ Error ${response.statusCode}\n📝 Detalles: $errorDetails';
        });
      }
    } catch (e) {
      setState(() {
        resultadoSegmentacion = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _cargandoSegmentacion = false;
      });
    }
  }

  Future<void> _analizarImagenRoya(int filaIndex, int hojaIndex, ImageSource source) async {
    final String claveAnalisis = '${filaIndex}_$hojaIndex';

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final fileName = pickedFile.name;
        final extension = fileName.split('.').last.toLowerCase();

        setState(() {
          _analizandoImagen[claveAnalisis] = true;
        });

        final url = Uri.parse('$API_BASE_URL/analyze-image');
        final request = http.MultipartRequest('POST', url);
        request.headers.addAll({
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App/1.0',
          'ngrok-skip-browser-warning': 'true',
        });

        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
            contentType: MediaType('image', extension.isNotEmpty ? extension : 'jpeg'),
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['status'] == 'success') {
            final double porcentajeRoya = (data['porcentaje_roya'] as num).toDouble();

            setState(() {
              _resultadosAnalisis[claveAnalisis] = porcentajeRoya;

              if (_datosTablaRoya != null && filaIndex < _datosTablaRoya!.length) {
                List<double> porcentajes = List<double>.from(_datosTablaRoya![filaIndex]['porcentajes_hojas'] ?? []);
                if (hojaIndex < porcentajes.length) {
                  porcentajes[hojaIndex] = porcentajeRoya;
                  _datosTablaRoya![filaIndex]['porcentajes_hojas'] = porcentajes;
                }
              }
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Análisis completado: ${porcentajeRoya.toStringAsFixed(1)}% de roya detectada',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Error en el análisis
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '❌ Error: ${data['mensaje'] ?? 'Error desconocido'}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // Error del servidor
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error del servidor: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error analizando imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al analizar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _analizandoImagen[claveAnalisis] = false;
      });
    }
  }

  void _crearTabla() {
    setState(() {
      _tablaCreada = true;

      // Limpiar controladores anteriores
      for (var controller in _controllersHojasPresentes) {
        controller.dispose();
      }
      for (var controller in _controllersHojasConRoya) {
        controller.dispose();
      }

      // Crear nuevos controladores
      _controllersHojasPresentes = List.generate(
        _numeroFilas,
        (index) => TextEditingController(),
      );
      _controllersHojasConRoya = List.generate(
        _numeroFilas,
        (index) => TextEditingController(),
      );

      // Crear datos iniciales de la tabla
      _datosTablaRoya = List.generate(
        _numeroFilas,
        (index) => {
          'arbol': index + 1,
          'rama': index + 1,
          'hojas_presentes': 0,
          'hojas_con_roya': 0,
          'porcentajes_hojas': <double>[], // Lista dinámica de porcentajes
        },
      );

      resultadoRoya =
          'Tabla creada con $_numeroFilas filas. Ingresa los datos.';
    });
  }

  void _actualizarHojasConRoya(int filaIndex, String valor) {
    final int numHojas = int.tryParse(valor) ?? 0;
    setState(() {
      _datosTablaRoya![filaIndex]['hojas_con_roya'] = numHojas;

      // Actualizar el máximo de hojas con roya para determinar columnas
      _maxHojasConRoya = 0;
      for (var fila in _datosTablaRoya!) {
        final hojas = fila['hojas_con_roya'] as int;
        if (hojas > _maxHojasConRoya) {
          _maxHojasConRoya = hojas;
        }
      }

      // Actualizar la lista de porcentajes para todas las filas
      for (var fila in _datosTablaRoya!) {
        List<double> porcentajes = List<double>.from(
          fila['porcentajes_hojas'] ?? [],
        );
        while (porcentajes.length < _maxHojasConRoya) {
          porcentajes.add(0.0);
        }
        if (porcentajes.length > _maxHojasConRoya) {
          porcentajes = porcentajes.take(_maxHojasConRoya).toList();
        }
        fila['porcentajes_hojas'] = porcentajes;
      }
    });
  }

  void _reiniciarTabla() {
    setState(() {
      _tablaCreada = false;
      _datosTablaRoya = null;
      _maxHojasConRoya = 0;

      // Limpiar controladores
      for (var controller in _controllersHojasPresentes) {
        controller.dispose();
      }
      for (var controller in _controllersHojasConRoya) {
        controller.dispose();
      }
      _controllersHojasPresentes.clear();
      _controllersHojasConRoya.clear();

      // Limpiar datos de análisis de imágenes
      _analizandoImagen.clear();
      _resultadosAnalisis.clear();

      resultadoRoya = 'Configura la tabla para comenzar el análisis...';
    });
  }

  double _calcularSumaTotal(String campo) {
    if (_datosTablaRoya == null || _datosTablaRoya!.isEmpty) return 0.0;

    double suma = 0.0;
    for (var fila in _datosTablaRoya!) {
      final valor = fila[campo];
      if (valor != null) {
        if (valor is num) {
          suma += valor.toDouble();
        } else if (valor is String) {
          suma += double.tryParse(valor) ?? 0.0;
        }
      }
    }
    return suma;
  }

  double _calcularSumaPorcentajes(int hojaIndex) {
    if (_datosTablaRoya == null || _datosTablaRoya!.isEmpty) return 0.0;

    double suma = 0.0;
    for (var fila in _datosTablaRoya!) {
      List<double> porcentajes = List<double>.from(
        fila['porcentajes_hojas'] ?? [],
      );
      if (hojaIndex < porcentajes.length) {
        suma += porcentajes[hojaIndex];
      }
    }
    return suma;
  }

  double _calcularSumaTotalPorcentajes() {
    if (_datosTablaRoya == null || _datosTablaRoya!.isEmpty) return 0.0;

    double suma = 0.0;
    for (var fila in _datosTablaRoya!) {
      List<double> porcentajes = List<double>.from(
        fila['porcentajes_hojas'] ?? [],
      );
      suma += porcentajes.fold(0.0, (total, porcentaje) => total + porcentaje);
    }
    return suma;
  }

  Widget _construirTablaRoya() {
    if (!_tablaCreada) {
      // Panel de configuración inicial
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuración de la Tabla:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Text('Número de filas (Árboles): '),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  controller: TextEditingController(
                    text: _numeroFilas.toString(),
                  ),
                  onChanged: (value) {
                    final numero = int.tryParse(value);
                    if (numero != null && numero > 0 && numero <= 50) {
                      _numeroFilas = numero;
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _crearTabla,
            icon: const Icon(Icons.table_chart),
            label: const Text('Crear Tabla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Instrucciones:\n'
              '1. Ingresa el número de filas que necesitas\n'
              '2. Haz clic en "Crear Tabla"\n'
              '3. Completa los datos de hojas presentes y hojas con roya\n'
              '4. Las columnas de porcentaje se crearán automáticamente',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      );
    }

    // Tabla dinámica creada
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tabla de Análisis de Roya:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            ElevatedButton.icon(
              onPressed: _reiniciarTabla,
              icon: const Icon(Icons.refresh),
              label: const Text('Nueva Tabla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.green[100]),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 12,
              ),
              columnSpacing: 15,
              dataRowMinHeight: 70, // Aumentar altura para acomodar botones
              dataRowMaxHeight: 90,
              columns: [
                const DataColumn(label: Text('Árbol No.')),
                const DataColumn(label: Text('Rama No.')),
                const DataColumn(label: Text('Hojas\npresentes')),
                const DataColumn(label: Text('Hojas\ncon roya')),
                // Columnas dinámicas para porcentajes
                ...List.generate(
                  _maxHojasConRoya,
                  (index) => DataColumn(
                    label: Text(
                      '% Área Hoja ${index + 1}\n(Manual/AI)',
                      style: TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const DataColumn(label: Text('Suma área\ncon roya (%)')),
              ],
              rows: [
                // Filas de datos editables
                ..._datosTablaRoya!.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> fila = entry.value;
                  List<double> porcentajes = List<double>.from(
                    fila['porcentajes_hojas'] ?? [],
                  );

                  return DataRow(
                    color: MaterialStateProperty.all(
                      index % 2 == 0 ? Colors.white : Colors.grey[50],
                    ),
                    cells: [
                      DataCell(Text('${fila['arbol']}')),
                      DataCell(Text('${fila['rama']}')),
                      // Campo editable para hojas presentes
                      DataCell(
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: _controllersHojasPresentes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.all(4),
                            ),
                            onChanged: (value) {
                              final numero = int.tryParse(value) ?? 0;
                              setState(() {
                                _datosTablaRoya![index]['hojas_presentes'] =
                                    numero;
                              });
                            },
                          ),
                        ),
                      ),
                      // Campo editable para hojas con roya
                      DataCell(
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: _controllersHojasConRoya[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.all(4),
                            ),
                            onChanged: (value) {
                              _actualizarHojasConRoya(index, value);
                            },
                          ),
                        ),
                      ),
                      // Campos para porcentajes de área afectada
                      ...List.generate(_maxHojasConRoya, (hojaIndex) {
                        final String claveAnalisis = '${index}_$hojaIndex';
                        final bool analizando =
                            _analizandoImagen[claveAnalisis] ?? false;
                        final double valorActual =
                            porcentajes.length > hojaIndex
                            ? porcentajes[hojaIndex]
                            : 0.0;

                        return DataCell(
                          SizedBox(
                            width: 120, // Aumentar ancho para acomodar botón
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Campo de texto para porcentaje
                                SizedBox(
                                  height: 35,
                                  child: TextField(
                                    key: ValueKey('text_${claveAnalisis}'),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    controller: TextEditingController(
                                      text: valorActual > 0
                                          ? valorActual.toStringAsFixed(1)
                                          : '',
                                    ),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.all(4),
                                      suffixText: '%',
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      final porcentaje =
                                          double.tryParse(value) ?? 0.0;
                                      setState(() {
                                        if (hojaIndex < porcentajes.length) {
                                          porcentajes[hojaIndex] = porcentaje;
                                        } else {
                                          // Expandir lista si es necesario
                                          while (porcentajes.length <=
                                              hojaIndex) {
                                            porcentajes.add(0.0);
                                          }
                                          porcentajes[hojaIndex] = porcentaje;
                                        }
                                        _datosTablaRoya![index]['porcentajes_hojas'] =
                                            porcentajes;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Botón para análisis de imagen
                                SizedBox(
                                  height: 25,
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: analizando
                                        ? null
                                        : () => _seleccionarFuenteImagenRoya(
                                            index,
                                            hojaIndex,
                                          ),
                                    icon: analizando
                                        ? SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(Icons.camera_alt, size: 12),
                                    label: Text(
                                      analizando ? 'Analizando...' : 'Analizar',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: analizando
                                          ? Colors.grey
                                          : Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      minimumSize: Size(0, 25),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      // Suma total calculada
                      DataCell(
                        Text(
                          '${porcentajes.fold(0.0, (sum, p) => sum + p).toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                // Fila de totales
                DataRow(
                  color: MaterialStateProperty.all(Colors.green[50]),
                  cells: [
                    const DataCell(
                      Text(
                        'TOTAL',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${_datosTablaRoya!.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${_calcularSumaTotal('hojas_presentes').toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${_calcularSumaTotal('hojas_con_roya').toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Totales de porcentajes por columna
                    ...List.generate(
                      _maxHojasConRoya,
                      (hojaIndex) => DataCell(
                        Text(
                          '${_calcularSumaPorcentajes(hojaIndex).toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${_calcularSumaTotalPorcentajes().toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Limpiar todos los controladores
    for (var controller in _controllersHojasPresentes) {
      controller.dispose();
    }
    for (var controller in _controllersHojasConRoya) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Inicializar el plugin file_picker y luego consultar API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      consultarApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consulta API')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sección de consulta de estado
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Estado de la API',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_cargandoApi)
                      const CircularProgressIndicator()
                    else
                      Text(resultado, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _cargandoApi ? null : consultarApi,
                      child: const Text('Consultar Estado API'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Sección de segmentación de imágenes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Segmentación de Imágenes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_cargandoSegmentacion)
                      const CircularProgressIndicator()
                    else
                      Text(resultadoSegmentacion, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _cargandoSegmentacion ? null : _seleccionarFuenteImagen,
                      icon: const Icon(Icons.image),
                      label: const Text('Seleccionar y Segmentar Imagen'),
                    ),
                    // Mostrar la imagen segmentada si existe
                    if (_imagenSegmentada != null) ...[
                      const SizedBox(height: 20),
                      // Mostrar ambas imágenes en fila si hay espacio, sino en columna
                      if (_imagenOriginal != null) ...[
                        const Text(
                          'Comparación de Imágenes:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Imagen Original
                            Expanded(
                              child: Column(
                                children: [
                                  const Text(
                                    'Original',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 200,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.blue),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        _imagenOriginal!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Imagen Segmentada
                            Expanded(
                              child: Column(
                                children: [
                                  const Text(
                                    'Segmentada',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 200,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.green),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        _imagenSegmentada!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const Text(
                          'Imagen Segmentada:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          constraints: const BoxConstraints(
                            maxHeight: 300,
                            maxWidth: double.infinity,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _imagenSegmentada!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error, color: Colors.red),
                                        Text('Error al cargar imagen'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _imagenSegmentada = null;
                                _imagenOriginal = null;
                                resultadoSegmentacion =
                                    'Selecciona una imagen para segmentar...';
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Limpiar'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Aquí puedes agregar funcionalidad para guardar la imagen
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Función de guardado no implementada',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Sección de análisis de roya
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Análisis de Roya',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Configura y completa la tabla de análisis de roya',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    _construirTablaRoya(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
