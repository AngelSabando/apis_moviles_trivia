import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;
  String? _errorMessage;

  CategoryModel? _selectedCategory;
  String _selectedDifficulty = 'easy';
  int _selectedAmount = 5;

  final List<Map<String, String>> _difficulties = [
    {'value': 'easy', 'label': 'Fácil'},
    {'value': 'medium', 'label': 'Medio'},
    {'value': 'hard', 'label': 'Difícil'},
  ];

  final List<int> _amounts = [5, 10, 15];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _errorMessage = null;
    });

    try {
      final categories = await _apiService.getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingCategories = false;
      });
    }
  }

  void _startQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          amount: _selectedAmount,
          category: _selectedCategory,
          difficulty: _selectedDifficulty,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trivia Quiz Master'),
        centerTitle: true,
        elevation: 2,
      ),
      body: _isLoadingCategories
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando categorías disponibles...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          'Error al conectar con la API',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _fetchCategories,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.quiz,
                                      size: 32, color: theme.colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Configuración de Trivia',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Personaliza tu partida seleccionando la categoría, dificultad y número de preguntas.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                              const Divider(height: 32),

                              // Selector de Categoría
                              const Text(
                                'Categoría',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<CategoryModel?>(
                                value: _selectedCategory,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.category_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.withOpacity(0.08),
                                ),
                                hint: const Text('Cualquier categoría'),
                                items: [
                                  const DropdownMenuItem<CategoryModel?>(
                                    value: null,
                                    child: Text('Cualquier categoría (Aleatoria)'),
                                  ),
                                  ..._categories.map((category) {
                                    return DropdownMenuItem<CategoryModel?>(
                                      value: category,
                                      child: Text(
                                        category.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              // Selector de Dificultad
                              const Text(
                                'Dificultad',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedDifficulty,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.speed_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.withOpacity(0.08),
                                ),
                                items: _difficulties.map((diff) {
                                  return DropdownMenuItem<String>(
                                    value: diff['value'],
                                    child: Text(diff['label']!),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedDifficulty = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 20),

                              // Selector de Cantidad de Preguntas
                              const Text(
                                'Cantidad de preguntas',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: _selectedAmount,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.format_list_numbered),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.withOpacity(0.08),
                                ),
                                items: _amounts.map((amount) {
                                  return DropdownMenuItem<int>(
                                    value: amount,
                                    child: Text('$amount preguntas'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedAmount = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Botón para iniciar
                      ElevatedButton.icon(
                        onPressed: _startQuiz,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 28),
                        label: const Text(
                          'Iniciar Trivia',
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
