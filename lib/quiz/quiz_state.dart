import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'quiz_model.dart';

@immutable
sealed class QuizState extends Equatable
{
  final Quiz? quiz;
  final Map<int,int?> userAnswers;
  final Map<int,String?> explanations;

  const QuizState({
    this.quiz,
    this.userAnswers=const{},
    this.explanations=const{}
});

  @override
  // TODO: implement props
  List<Object?> get props => [quiz,userAnswers,explanations];

}

final class QuizInitial extends QuizState
{}

// quiz is being displayed and ready for interaction
class QuizDisplay extends QuizState
{
  const QuizDisplay({required super.quiz,
  super.userAnswers,
  super.explanations});

  @override
  // TODO: implement props
  List<Object?> get props => [quiz,userAnswers,explanations];
}

class QuizLoadingExplanation extends QuizState
{
  final int questionIndexLoading;

  const QuizLoadingExplanation({
    required super.quiz,
    required super.userAnswers,
    required super.explanations,
    required this.questionIndexLoading
});

  @override
  // TODO: implement props
  List<Object?> get props => [quiz,userAnswers,explanations,questionIndexLoading];
}

class QuizError extends QuizState
{
  final String error;

  const QuizError({
    required this.error,
    super.quiz,
    super.userAnswers,
    super.explanations
});

  @override
  List<Object?> get props => [error, quiz, userAnswers, explanations];
}


