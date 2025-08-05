import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:bidyaai/quiz/quiz_model.dart';

@immutable
sealed class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class InitializeQuiz extends QuizEvent {
  final Quiz quiz;
  const InitializeQuiz({required this.quiz});

  @override
  // TODO: implement props
  List<Object?> get props => [quiz];
}

class SubmitAnswer extends QuizEvent {
  final int questionIndex;
  final int selectedOptionIndex;

  const SubmitAnswer({
    required this.questionIndex,
    required this.selectedOptionIndex,
  });

  @override
  // TODO: implement props
  List<Object?> get props => [questionIndex, selectedOptionIndex];
}

class RequestExplanation extends QuizEvent {
  final int questionIndex;
  final String questionText;
  final List<Option> options;
  final int selectedOptionIndex;

  const RequestExplanation({
    required this.questionIndex,
    required this.questionText,
    required this.options,
    required this.selectedOptionIndex,
  });

  @override
  // TODO: implement props
  List<Object?> get props => [
    questionText,
    questionText,
    options,
    selectedOptionIndex,
  ];
}
