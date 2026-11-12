import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String categoryName;
  final String difficulty;

  const ResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.categoryName,
    required this.difficulty,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final ApiService _apiService = ApiService();

  bool _isPosting = true;
  bool _postSuccess = false;
  Map<String, dynamic>? _postResult;
  String? _postErrorMessage;

  @override
  void initState() {
    super.initState();
    _submitScore();
  }

  Future<void> _submitScore() async {
    setState(() {
      _isPosting = true;
      _postSuccess = false;
      _postErrorMessage = null;
    });

    try {
      final result = await _apiService.postScore(
        score: widget.score,
        totalQuestions: widget.totalQuestions,
        category: widget.categoryName,
        difficulty: widget.difficulty,
      );

      setState(() {
        _isPosting = false;
        _postSuccess = true;
        _postResult = result;
      });
    } catch (e) {
      setState(() {
        _isPosting = false;
        _postSuccess = false;
        _postErrorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (widget.score / widget.totalQuestions) * 100;

    String feedbackMessage;
    IconData feedbackIcon;
    Color feedbackColor;

    if (percentage >= 80) {
      feedbackMessage = '¡Excelente desempeño!';
      feedbackIcon = Icons.emoji_events;
      feedbackColor = Colors.amber.shade700;
    } else if (percentage >= 50) {
      feedbackMessage = '¡Buen esfuerzo! Sigue mejorando.';
      feedbackIcon = Icons.thumb_up_alt;
      feedbackColor = Colors.blue.shade600;
    } else {
      feedbackMessage = '¡Ánimo! La práctica hace al maestro.';
      feedbackIcon = Icons.school;
      feedbackColor = Colors.orange.shade700;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Resumen de puntaje
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 24.0, horizontal: 16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: feedbackColor.withOpacity(0.15),
                      child: Icon(feedbackIcon, size: 48, color: feedbackColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      feedbackMessage,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${widget.score} / ${widget.totalQuestions}',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percentage.toStringAsFixed(1)}% de aciertos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.category, size: 16),
                          label: Text(
                            widget.categoryName,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Chip(
                          avatar: const Icon(Icons.speed, size: 16),
                          label: Text(
                            'Dificultad: ${widget.difficulty.toUpperCase()}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card demostrativo de petición POST
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Demostración Petición POST',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (_isPosting)
                      const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Enviando resultados a https://jsonplaceholder.typicode.com/posts...',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      )
                    else if (_postSuccess)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '¡Resultados registrados en el servidor! (HTTP ${_postResult?['statusCode'] ?? 201})',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Text(
                              'Respuesta mock JSONPlaceholder:\n'
                              '• ID asignado: ${_postResult?['data']?['id']}\n'
                              '• Score registrado: ${widget.score}/${widget.totalQuestions}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Error al enviar POST: $_postErrorMessage',
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _submitScore,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Reintentar POST'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Botón Volver al inicio
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.home),
              label: const Text(
                'Volver al Inicio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
