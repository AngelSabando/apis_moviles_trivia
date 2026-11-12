import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import '../models/category_model.dart';
import '../models/question_model.dart';

class ApiService {
  static const String _baseUrl = 'https://opentdb.com';
  static const String _placeholderUrl =
      'https://jsonplaceholder.typicode.com/posts';

  final GoogleTranslator _translator = GoogleTranslator();

  /// Mapeo de categorías conocidas de Open Trivia DB para traducción instantánea
  static const Map<String, String> _categoryTranslations = {
    'General Knowledge': 'Cultura General',
    'Entertainment: Books': 'Entretenimiento: Libros',
    'Entertainment: Film': 'Entretenimiento: Películas',
    'Entertainment: Music': 'Entretenimiento: Música',
    'Entertainment: Musicals & Theatres': 'Entretenimiento: Musicales y Teatros',
    'Entertainment: Television': 'Entretenimiento: Televisión',
    'Entertainment: Video Games': 'Entretenimiento: Videojuegos',
    'Entertainment: Board Games': 'Entretenimiento: Juegos de Mesa',
    'Science & Nature': 'Ciencia y Naturaleza',
    'Science: Computers': 'Ciencia: Informática',
    'Science: Mathematics': 'Ciencia: Matemáticas',
    'Mythology': 'Mitología',
    'Sports': 'Deportes',
    'Geography': 'Geografía',
    'History': 'Historia',
    'Politics': 'Política',
    'Art': 'Arte',
    'Celebrities': 'Celebridades',
    'Animals': 'Animales',
    'Vehicles': 'Vehículos',
    'Entertainment: Comics': 'Entretenimiento: Cómics',
    'Science: Gadgets': 'Ciencia: Gadgets y Tecnología',
    'Entertainment: Japanese Anime & Manga':
        'Entretenimiento: Anime y Manga Japonés',
    'Entertainment: Cartoon & Animations':
        'Entretenimiento: Animación y Caricaturas',
  };

  /// Traduce un texto de inglés a español de forma segura y tolerante a fallos.
  Future<String> _translateText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;
    try {
      final translation =
          await _translator.translate(trimmed, from: 'en', to: 'es');
      return translation.text;
    } catch (_) {
      // Si falla la red o hay timeout, se preserva el texto original
      return text;
    }
  }

  /// Obtiene la lista de categorías disponibles desde Open Trivia Database traducidas al español.
  Future<List<CategoryModel>> getCategories() async {
    final url = Uri.parse('$_baseUrl/api_category.php');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> categoriesJson = data['trivia_categories'] ?? [];
      final rawCategories = categoriesJson
          .map((json) => CategoryModel.fromJson(json))
          .toList();

      // Traducir las categorías en paralelo optimizando con Future.wait
      return await Future.wait(rawCategories.map((cat) async {
        if (_categoryTranslations.containsKey(cat.name)) {
          return CategoryModel(
            id: cat.id,
            name: _categoryTranslations[cat.name]!,
          );
        }
        final translatedName = await _translateText(cat.name);
        return CategoryModel(id: cat.id, name: translatedName);
      }));
    } else {
      throw Exception('Error al cargar categorías: ${response.statusCode}');
    }
  }

  /// Obtiene preguntas y las traduce al español en paralelo mediante Future.wait.
  Future<List<QuestionModel>> getQuestions({
    required int amount,
    int? categoryId,
    String? difficulty,
  }) async {
    final Map<String, String> queryParameters = {
      'amount': amount.toString(),
      'type': 'multiple',
    };

    if (categoryId != null && categoryId > 0) {
      queryParameters['category'] = categoryId.toString();
    }

    if (difficulty != null && difficulty.isNotEmpty && difficulty != 'any') {
      queryParameters['difficulty'] = difficulty.toLowerCase();
    }

    final url = Uri.https('opentdb.com', '/api.php', queryParameters);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final int responseCode = data['response_code'] ?? -1;

      if (responseCode == 0) {
        final List<dynamic> results = data['results'] ?? [];
        final questions =
            results.map((json) => QuestionModel.fromJson(json)).toList();

        // Traduce dinámicamente cada pregunta y sus opciones en paralelo
        return await Future.wait(
          questions.map((question) => _translateQuestion(question)),
        );
      } else if (responseCode == 1) {
        throw Exception(
            'No hay suficientes preguntas para los filtros seleccionados. Intenta con otra categoría o menor cantidad.');
      } else {
        throw Exception(
            'Error devuelto por la API con código de respuesta: $responseCode');
      }
    } else {
      throw Exception(
          'Error en la petición de preguntas: ${response.statusCode}');
    }
  }

  /// Traduce concurrentemente enunciado, respuesta correcta y opciones de una pregunta.
  Future<QuestionModel> _translateQuestion(QuestionModel question) async {
    final questionTextFuture = _translateText(question.questionText);
    final correctAnswerFuture = _translateText(question.correctAnswer);
    final optionsFuture = Future.wait(
      question.allOptions.map((opt) => _translateText(opt)),
    );

    // Se ejecutan en paralelo
    final results = await Future.wait([
      questionTextFuture,
      correctAnswerFuture,
      optionsFuture,
    ]);

    final translatedQuestionText = results[0] as String;
    final translatedCorrectAnswer = results[1] as String;
    final translatedOptions = results[2] as List<String>;

    // Garantizar correspondencia exacta entre correctAnswer y la opción en allOptions
    final correctIndex = question.allOptions.indexOf(question.correctAnswer);
    if (correctIndex != -1 && correctIndex < translatedOptions.length) {
      translatedOptions[correctIndex] = translatedCorrectAnswer;
    }

    return question.copyWith(
      questionText: translatedQuestionText,
      correctAnswer: translatedCorrectAnswer,
      allOptions: translatedOptions,
    );
  }

  /// Envía el puntaje obtenido mediante una petición POST a JSONPlaceholder.
  Future<Map<String, dynamic>> postScore({
    required int score,
    required int totalQuestions,
    required String category,
    required String difficulty,
  }) async {
    final url = Uri.parse(_placeholderUrl);
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'title': 'Trivia Score Submission',
        'score': score,
        'totalQuestions': totalQuestions,
        'percentage': ((score / totalQuestions) * 100).toStringAsFixed(1),
        'category': category,
        'difficulty': difficulty,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } else {
      throw Exception('Error al enviar el puntaje: ${response.statusCode}');
    }
  }
}
