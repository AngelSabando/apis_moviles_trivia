import 'package:html_unescape/html_unescape.dart';

class QuestionModel {
  final String category;
  final String difficulty;
  final String questionText;
  final String correctAnswer;
  final List<String> allOptions;

  const QuestionModel({
    required this.category,
    required this.difficulty,
    required this.questionText,
    required this.correctAnswer,
    required this.allOptions,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final unescape = HtmlUnescape();

    final decodedCategory = unescape.convert(json['category'] as String? ?? '');
    final decodedDifficulty = json['difficulty'] as String? ?? '';
    final decodedQuestion = unescape.convert(json['question'] as String? ?? '');
    final decodedCorrectAnswer =
        unescape.convert(json['correct_answer'] as String? ?? '');

    final incorrectAnswersRaw =
        (json['incorrect_answers'] as List<dynamic>? ?? []);
    final List<String> options = incorrectAnswersRaw
        .map((e) => unescape.convert(e.toString()))
        .toList();

    options.add(decodedCorrectAnswer);
    options.shuffle();

    return QuestionModel(
      category: decodedCategory,
      difficulty: decodedDifficulty,
      questionText: decodedQuestion,
      correctAnswer: decodedCorrectAnswer,
      allOptions: options,
    );
  }

  QuestionModel copyWith({
    String? category,
    String? difficulty,
    String? questionText,
    String? correctAnswer,
    List<String>? allOptions,
  }) {
    return QuestionModel(
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      questionText: questionText ?? this.questionText,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      allOptions: allOptions ?? this.allOptions,
    );
  }
}
