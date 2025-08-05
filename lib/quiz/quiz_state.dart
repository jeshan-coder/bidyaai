import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'quiz_model.dart';

@immutable
sealed class QuizState extends Equatable {
  final Quiz? quiz;
  final Map<int, int?> userAnswers;
  final Map<int, String?> explanations;
  final String? streamingExplanationFragment;

  const QuizState({
    this.quiz,
    this.userAnswers = const {},
    this.explanations = const {},
    this.streamingExplanationFragment,
  });

  @override
  // TODO: implement props
  List<Object?> get props => [
    quiz,
    userAnswers,
    explanations,
    streamingExplanationFragment,
  ];
}

final class QuizInitial extends QuizState {}

// quiz is being displayed and ready for interaction
class QuizDisplay extends QuizState {
  const QuizDisplay({
    required super.quiz,
    super.userAnswers,
    super.explanations,
    super.streamingExplanationFragment,
  });

  @override
  // TODO: implement props
  List<Object?> get props => [
    quiz,
    userAnswers,
    explanations,
    streamingExplanationFragment,
  ];
}

class QuizLoadingExplanation extends QuizState {
  final int questionIndexLoading;

  const QuizLoadingExplanation({
    required super.quiz,
    required super.userAnswers,
    required super.explanations,
    required this.questionIndexLoading,
    super.streamingExplanationFragment,
  });

  @override
  // TODO: implement props
  List<Object?> get props => [
    quiz,
    userAnswers,
    explanations,
    questionIndexLoading,
    streamingExplanationFragment,
  ];
}

class QuizError extends QuizState {
  final String error;

  const QuizError({
    required this.error,
    super.quiz,
    super.userAnswers,
    super.explanations,
    super.streamingExplanationFragment,
  });

  @override
  List<Object?> get props => [
    error,
    quiz,
    userAnswers,
    explanations,
    streamingExplanationFragment,
  ];
}
