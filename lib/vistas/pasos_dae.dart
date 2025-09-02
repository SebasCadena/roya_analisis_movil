import 'package:flutter/material.dart';

class PasosDAEPage extends StatelessWidget {
  const PasosDAEPage({super.key});

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
            Icon(Icons.eco, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Pasos del DAE',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.agriculture, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    'Protocolo de Evaluación',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Seguimiento de Roya del Café',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Pasos del protocolo
            Text(
              'Pasos del Protocolo:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 15),

            // Paso 1
            _construirPasoCard(
              numeroStep: '1',
              titulo: 'Ubicación inicial',
              descripcion: 'Colócate en el centro del primer surco del lote.',
              icono: Icons.my_location,
              color: Colors.blue,
            ),

            // Paso 2
            _construirPasoCard(
              numeroStep: '2',
              titulo: 'Selección del árbol',
              descripcion: 'Escoge un árbol cercano desde tu posición inicial.',
              icono: Icons.park,
              color: Colors.green,
            ),

            // Paso 3
            _construirPasoCard(
              numeroStep: '3',
              titulo: 'Selección de la rama',
              descripcion:
                  'Elige la rama con mayor follaje y al menos 10 hojas en el tercio medio productivo del árbol.',
              icono: Icons.nature,
              color: Colors.teal,
            ),

            // Paso 4
            _construirPasoCard(
              numeroStep: '4',
              titulo: 'Conteo de hojas',
              descripcion:
                  'Cuenta el número total de hojas en la rama seleccionada.',
              icono: Icons.format_list_numbered,
              color: Colors.orange,
            ),

            // Paso 5
            _construirPasoCard(
              numeroStep: '5',
              titulo: 'Identificación de hojas con roya',
              descripcion:
                  'Cuenta cuántas hojas presentan pústulas esporuladas (síntoma de roya activa).',
              icono: Icons.search,
              color: Colors.red,
            ),

            // Paso 6
            _construirPasoCard(
              numeroStep: '6',
              titulo: 'Estimación de severidad',
              descripcion:
                  'Para cada hoja con roya, estima el porcentaje de área afectada comparándola con el Diagrama de Área Estándar (DAE). Asigna 0% a las hojas completamente sanas.',
              icono: Icons.analytics,
              color: Colors.purple,
            ),

            // Paso 7
            _construirPasoCard(
              numeroStep: '7',
              titulo: 'Registro de datos',
              descripcion:
                  'Anota para cada hoja: número de hoja, estado (sana o infectada) y porcentaje estimado de severidad.',
              icono: Icons.edit_note,
              color: Colors.indigo,
            ),

            const SizedBox(height: 30),

            // Footer informativo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber[300]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 24),
                  const SizedBox(height: 8),
                  Text(
                    'Importante',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Sigue cada paso del protocolo cuidadosamente para obtener datos precisos sobre la incidencia y severidad de la roya del café.',
                    style: TextStyle(color: Colors.amber[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirPasoCard({
    required String numeroStep,
    required String titulo,
    required String descripcion,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Card(
        elevation: 4,
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Número del paso
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    numeroStep,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
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
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      descripcion,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(icono, color: color, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
