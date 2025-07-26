import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/core/chat.dart'; // For InferenceChat
// Removed: import 'package:flutter_gemma/core/model.dart'; // No longer need InferenceModel directly here

import 'package:anticipatorygpt/quiz/quiz_model.dart';
import 'package:anticipatorygpt/quiz/quiz_bloc.dart';
import 'package:anticipatorygpt/quiz/quiz_event.dart';
import 'package:anticipatorygpt/quiz/quiz_state.dart';

/// A dedicated screen for displaying and interacting with a generated quiz.
class QuizScreen extends StatelessWidget {
  final Quiz quiz;
  final InferenceChat chatInstance; // Changed to take InferenceChat

  const QuizScreen({
    super.key,
    required this.quiz,
    required this.chatInstance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Time!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: BlocProvider(
        create: (context) => QuizBloc(chat: chatInstance)..add(InitializeQuiz(quiz: quiz)), // Pass chatInstance
        child: BlocConsumer<QuizBloc, QuizState>(
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
              return const Center(child: CircularProgressIndicator());
            }

            final currentQuiz = state.quiz!;
            final userAnswers = state.userAnswers;
            final explanations = state.explanations;

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: currentQuiz.questions.length,
              itemBuilder: (context, index) {
                final question = currentQuiz.questions[index];
                final selectedAnswer = userAnswers[index];
                final explanation = explanations[index];
                final isExplanationLoading = state is QuizLoadingExplanation &&
                    state.questionIndexLoading == index;

                return QuizQuestionCard(
                  questionIndex: index,
                  question: question,
                  selectedAnswer: selectedAnswer,
                  explanation: explanation,
                  isExplanationLoading: isExplanationLoading,
                  onOptionSelected: (optionIndex) {
                    context.read<QuizBloc>().add(
                      SubmitAnswer(
                        questionIndex: index,
                        selectedOptionIndex: optionIndex,
                      ),
                    );
                  },
                  onRequestExplanation: () {
                    context.read<QuizBloc>().add(
                      RequestExplanation(
                        questionIndex: index,
                        questionText: question.questionText,
                        options: question.options, // Pass List<Option>
                        selectedOptionIndex: selectedAnswer!, // Must have an answer selected
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Widget to display a single quiz question with its options and explanation.
class QuizQuestionCard extends StatelessWidget {
  final int questionIndex;
  final Question question;
  final int? selectedAnswer;
  final String? explanation;
  final bool isExplanationLoading;
  final ValueChanged<int> onOptionSelected;
  final VoidCallback onRequestExplanation;

  const QuizQuestionCard({
    super.key,
    required this.questionIndex,
    required this.question,
    required this.selectedAnswer,
    required this.explanation,
    required this.isExplanationLoading,
    required this.onOptionSelected,
    required this.onRequestExplanation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasAnswered = selectedAnswer != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${questionIndex + 1}: ${question.questionText}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...question.options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final Option option = entry.value; // Changed from String to Option
              final bool isCorrectOption = optionIndex == question.correctAnswerIndex;
              final bool isSelected = optionIndex == selectedAnswer;

              Color? optionColor;
              if (hasAnswered) {
                if (isSelected) {
                  optionColor = isCorrectOption ? Colors.green.shade700 : Colors.red.shade700;
                } else if (isCorrectOption) {
                  optionColor = Colors.green.shade900; // Show correct answer even if not selected
                }
              }

              final Color primaryColorWithOpacity = Color.fromARGB(
                (theme.colorScheme.primary.a * 255.0 * 0.7).round() & 0xff, // Apply opacity to alpha
                (theme.colorScheme.primary.r * 255.0).round() & 0xff, // Get red component
                (theme.colorScheme.primary.g * 255.0).round() & 0xff, // Get green component
                (theme.colorScheme.primary.b * 255.0).round() & 0xff, // Get blue component
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ChoiceChip(
                  label: Text('${String.fromCharCode(65 + optionIndex)}. ${option.text}'), // Access option.text
                  selected: isSelected,
                  onSelected: hasAnswered ? null : (selected) {
                    if (selected) {
                      onOptionSelected(optionIndex);
                    }
                  },
                  selectedColor: optionColor ?? primaryColorWithOpacity,
                  backgroundColor: theme.cardColor,
                  labelStyle: TextStyle(
                    color: hasAnswered && isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(
                      color: optionColor != null ? optionColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
            if (hasAnswered) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: isExplanationLoading ? null : onRequestExplanation,
                  icon: isExplanationLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.lightbulb_outline),
                  label: Text(isExplanationLoading ? 'Getting Explanation...' : 'Explain This'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
            if (explanation != null && !isExplanationLoading) ...[
              const SizedBox(height: 16),
              Text(
                'Explanation:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                explanation!,
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(
                    (theme.colorScheme.onSurface.a * 255.0 * 0.8).round() & 0xff,
                    (theme.colorScheme.onSurface.r * 255.0).round() & 0xff,
                    (theme.colorScheme.onSurface.g * 255.0).round() & 0xff,
                    (theme.colorScheme.onSurface.b * 255.0).round() & 0xff,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
