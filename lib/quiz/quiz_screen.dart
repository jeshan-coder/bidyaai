// lib/quiz/quiz_screen.dart - UPDATED and CORRECTED for streaming

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/core/chat.dart';

import 'package:bidyaai/quiz/quiz_model.dart';
import 'package:bidyaai/quiz/quiz_bloc.dart';
import 'package:bidyaai/quiz/quiz_event.dart';
import 'package:bidyaai/quiz/quiz_state.dart';
import 'package:bidyaai/theme.dart';

/// A dedicated screen for displaying and interacting with a generated quiz.
class QuizScreen extends StatefulWidget {
  final Quiz quiz;
  final InferenceChat chatInstance;
  final String languageCode;

  const QuizScreen({
    super.key,
    required this.quiz,
    required this.chatInstance,
    required this.languageCode,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          QuizBloc(chat: widget.chatInstance, languageCode: widget.languageCode)
            ..add(InitializeQuiz(quiz: widget.quiz)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Quizzes',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.primaryColor),
          ),
          centerTitle: true,
        ),
        body: BlocConsumer<QuizBloc, QuizState>(
          listener: (context, state) {
            if (state is QuizError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Quiz Error: ${state.error}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is QuizInitial) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              );
            }

            final currentQuiz = state.quiz!;
            final userAnswers = state.userAnswers;

            final isExplanationLoading =
                state is QuizLoadingExplanation &&
                state.questionIndexLoading == _currentQuestionIndex;
            final explanation = state.explanations[_currentQuestionIndex];
            final streamingText = isExplanationLoading
                ? state.streamingExplanationFragment
                : null;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _QuizProgressIndicator(
                      currentQuestion: _currentQuestionIndex + 1,
                      totalQuestions: currentQuiz.questions.length,
                    ),
                    const SizedBox(height: 24),
                    QuizQuestionCard(
                      questionIndex: _currentQuestionIndex,
                      question: currentQuiz.questions[_currentQuestionIndex],
                      selectedAnswer: userAnswers[_currentQuestionIndex],
                      explanation:
                          streamingText ??
                          explanation, // FIX: Pass the combined explanation
                      isExplanationLoading:
                          isExplanationLoading, // FIX: Pass loading state
                      onOptionSelected: (optionIndex) {
                        context.read<QuizBloc>().add(
                          SubmitAnswer(
                            questionIndex: _currentQuestionIndex,
                            selectedOptionIndex: optionIndex,
                          ),
                        );
                      },
                      onRequestExplanation: () {
                        context.read<QuizBloc>().add(
                          RequestExplanation(
                            questionIndex: _currentQuestionIndex,
                            questionText: currentQuiz
                                .questions[_currentQuestionIndex]
                                .questionText,
                            options: currentQuiz
                                .questions[_currentQuestionIndex]
                                .options,
                            selectedOptionIndex:
                                userAnswers[_currentQuestionIndex]!,
                          ),
                        );
                      },
                      onNextQuestion: () {
                        if (_currentQuestionIndex <
                            currentQuiz.questions.length - 1) {
                          setState(() {
                            _currentQuestionIndex++;
                          });
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuizProgressIndicator extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;

  const _QuizProgressIndicator({
    required this.currentQuestion,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = currentQuestion / totalQuestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question $currentQuestion/$totalQuestions',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(
            AppTheme.primaryColor,
          ),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}

class QuizQuestionCard extends StatelessWidget {
  final int questionIndex;
  final Question question;
  final int? selectedAnswer;
  final String? explanation; // FIX: Added explanation and loading state fields
  final bool
  isExplanationLoading; // FIX: Added explanation and loading state fields
  final ValueChanged<int> onOptionSelected;
  final VoidCallback onRequestExplanation;
  final VoidCallback onNextQuestion;

  const QuizQuestionCard({
    super.key,
    required this.questionIndex,
    required this.question,
    required this.selectedAnswer,
    // FIX: Added required fields for explanation and loading state
    required this.explanation,
    required this.isExplanationLoading,
    required this.onOptionSelected,
    required this.onRequestExplanation,
    required this.onNextQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasAnswered = selectedAnswer != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.questionText,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        ...question.options.asMap().entries.map((entry) {
          final optionIndex = entry.key;
          final Option option = entry.value;
          return _OptionTile(
            text: option.text,
            isSelected: optionIndex == selectedAnswer,
            isCorrect: optionIndex == question.correctAnswerIndex,
            hasAnswered: hasAnswered,
            onTap: () {
              if (!hasAnswered) {
                onOptionSelected(optionIndex);
              }
            },
          );
        }).toList(),
        const SizedBox(height: 24),
        if (hasAnswered)
          _ExplanationAndNextButton(
            questionIndex: questionIndex,
            explanation:
                explanation, // FIX: Pass explanation to _ExplanationAndNextButton
            isExplanationLoading:
                isExplanationLoading, // FIX: Pass loading state
            onRequestExplanation: onRequestExplanation,
            onNextQuestion: onNextQuestion,
          ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool hasAnswered;
  final VoidCallback onTap;

  const _OptionTile({
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.hasAnswered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.grey.shade300;
    Color iconColor = Colors.grey.shade300;

    if (hasAnswered) {
      if (isSelected) {
        borderColor = isCorrect ? Colors.green : Colors.red;
        iconColor = isCorrect ? Colors.green : Colors.red;
      } else if (isCorrect) {
        borderColor = Colors.green;
        iconColor = Colors.green;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: iconColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationAndNextButton extends StatelessWidget {
  final int questionIndex;
  final String? explanation; // FIX: Added explanation field
  final bool isExplanationLoading; // FIX: Added loading state field
  final VoidCallback onRequestExplanation;
  final VoidCallback onNextQuestion;

  const _ExplanationAndNextButton({
    required this.questionIndex,
    required this.explanation, // FIX: Added to constructor
    required this.isExplanationLoading, // FIX: Added to constructor
    required this.onRequestExplanation,
    required this.onNextQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isExplanationComplete =
        explanation != null && explanation!.isNotEmpty && !isExplanationLoading;
    final bool isLastQuestion =
        questionIndex ==
        context.read<QuizBloc>().state.quiz!.questions.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (explanation != null && explanation!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Explanation:', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            explanation!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: isExplanationComplete || isExplanationLoading
                  ? null
                  : onRequestExplanation,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                disabledForegroundColor: Colors.grey,
                textStyle: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text(isExplanationLoading ? 'Loading...' : 'Explain This'),
            ),
            ElevatedButton(
              onPressed: isExplanationLoading ? null : onNextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text(isLastQuestion ? 'Finish Quiz' : 'Next Question'),
            ),
          ],
        ),
      ],
    );
  }
}
