import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/question_model.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final int amount;
  final CategoryModel? category;
  final String difficulty;

  const QuizScreen({
    super.key,
    required this.amount,
    required this.category,
    required this.difficulty,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final ApiService _apiService = ApiService();

  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final questions = await _apiService.getQuestions(
        amount: widget.amount,
        categoryId: widget.category?.id,
        difficulty: widget.difficulty,
      );

      if (questions.isEmpty) {
        setState(() {
          _errorMessage =
              'No se encontraron preguntas con los filtros seleccionados.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _handleOptionSelected(String option) {
    if (_isAnswered) return; // Bloquea clics múltiples

    final currentQuestion = _questions[_currentIndex];
    final isCorrect = option == currentQuestion.correctAnswer;

    setState(() {
      _isAnswered = true;
      _selectedOption = option;
      if (isCorrect) {
        _score++;
      }
    });

    // Pequeño delay para feedback visual antes de pasar a la siguiente pregunta
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;

      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _isAnswered = false;
          _selectedOption = null;
        });
      } else {
        // Fin de la trivia -> navegar a ResultScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              score: _score,
              totalQuestions: _questions.length,
              categoryName: widget.category?.name ?? 'Todas las categorías',
              difficulty: widget.difficulty,
            ),
          ),
        );
      }
    });
  }

  Color _getButtonColor(String option, QuestionModel question, ThemeData theme) {
    if (!_isAnswered) {
      return theme.colorScheme.surface;
    }

    if (option == question.correctAnswer) {
      return Colors.green.shade600;
    }

    if (option == _selectedOption && option != question.correctAnswer) {
      return Colors.red.shade600;
    }

    return theme.colorScheme.surface.withOpacity(0.5);
  }

  Color _getTextColor(String option, QuestionModel question, ThemeData theme) {
    if (!_isAnswered) {
      return theme.colorScheme.onSurface;
    }

    if (option == question.correctAnswer ||
        (option == _selectedOption && option != question.correctAnswer)) {
      return Colors.white;
    }

    return theme.colorScheme.onSurface.withOpacity(0.4);
  }

  BorderSide _getButtonBorder(
      String option, QuestionModel question, ThemeData theme) {
    if (!_isAnswered) {
      return BorderSide(color: theme.colorScheme.outline.withOpacity(0.3));
    }

    if (option == question.correctAnswer) {
      return const BorderSide(color: Colors.green, width: 2);
    }

    if (option == _selectedOption && option != question.correctAnswer) {
      return const BorderSide(color: Colors.red, width: 2);
    }

    return BorderSide(color: theme.colorScheme.outline.withOpacity(0.1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trivia')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando preguntas de la API...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 64, color: Colors.amber),
                const SizedBox(height: 16),
                Text(
                  'No se pudieron cargar las preguntas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchQuestions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver a configuración'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category?.name ?? 'Trivia Abierta'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            minHeight: 6,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de información superior
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    avatar: const Icon(Icons.format_list_numbered, size: 18),
                    label: Text(
                      'Pregunta ${_currentIndex + 1} de ${_questions.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.star, size: 18, color: Colors.amber),
                    label: Text(
                      'Puntaje: $_score',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tarjeta con el texto de la pregunta
              Expanded(
                flex: 3,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Text(
                          currentQuestion.questionText,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Opciones de respuesta
              Expanded(
                flex: 4,
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentQuestion.allOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final option = currentQuestion.allOptions[index];
                    final buttonColor =
                        _getButtonColor(option, currentQuestion, theme);
                    final textColor =
                        _getTextColor(option, currentQuestion, theme);
                    final borderSide =
                        _getButtonBorder(option, currentQuestion, theme);

                    IconData? statusIcon;
                    if (_isAnswered) {
                      if (option == currentQuestion.correctAnswer) {
                        statusIcon = Icons.check_circle;
                      } else if (option == _selectedOption) {
                        statusIcon = Icons.cancel;
                      }
                    }

                    return SizedBox(
                      height: 58,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: buttonColor,
                          side: borderSide,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed:
                            _isAnswered ? null : () => _handleOptionSelected(option),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: textColor.withOpacity(0.15),
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (statusIcon != null)
                              Icon(statusIcon, color: textColor, size: 22),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
