import 'dart:async';
import 'dart:convert'; // For JSON decoding

import 'package:anticipatorygpt/quiz/quiz_event.dart';
import 'package:anticipatorygpt/quiz/quiz_state.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_gemma/core/chat.dart'; // For InferenceChat
import 'package:flutter_gemma/flutter_gemma.dart'; // For Message

import 'package:meta/meta.dart';

import 'package:anticipatorygpt/quiz/quiz_model.dart';
import 'package:anticipatorygpt/management/prompt_management.dart';
import 'package:anticipatorygpt/management/model_settings.dart';



/// BLoC responsible for managing the state and logic of the quiz feature.
class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final InferenceChat _chat; // Changed to take InferenceChat
  final String _currentLanguageCode;

  QuizBloc({required InferenceChat chat,required String languageCode}) // Changed constructor parameter
      : _chat = chat,
        _currentLanguageCode=languageCode,
        super(QuizInitial()) {
    on<InitializeQuiz>(_onInitializeQuiz);
    on<SubmitAnswer>(_onSubmitAnswer);
    on<RequestExplanation>(_onRequestExplanation);
  }

  /// Handles the [InitializeQuiz] event.
  /// Sets the initial quiz data and displays it.
  Future<void> _onInitializeQuiz(
      InitializeQuiz event, Emitter<QuizState> emit) async {
    emit(QuizDisplay(quiz: event.quiz));
  }

  /// Handles the [SubmitAnswer] event.
  /// Updates the user's answer for a specific question.
  Future<void> _onSubmitAnswer(
      SubmitAnswer event, Emitter<QuizState> emit) async {
    if (state is QuizDisplay) {
      final currentState = state as QuizDisplay;
      final updatedUserAnswers =
      Map<int, int?>.from(currentState.userAnswers);
      updatedUserAnswers[event.questionIndex] = event.selectedOptionIndex;

      emit(QuizDisplay(
        quiz: currentState.quiz,
        userAnswers: updatedUserAnswers,
        explanations: currentState.explanations,
      ));
    }
  }

  /// Handles the [RequestExplanation] event.
  /// Requests an explanation from the AI model for a given question.
  Future<void> _onRequestExplanation(
      RequestExplanation event, Emitter<QuizState> emit) async {
    if (state is! QuizDisplay && state is! QuizLoadingExplanation) {
      return;
    }

    final currentState = state;
    final currentQuiz = currentState.quiz;
    final currentUserAnswers = currentState.userAnswers;
    final currentExplanations = Map<int, String?>.from(currentState.explanations);

    // Initial emit for loading state, without any fragment yet
    emit(QuizLoadingExplanation(
      quiz: currentQuiz,
      userAnswers: currentUserAnswers,
      explanations: currentExplanations,
      questionIndexLoading: event.questionIndex,
      streamingExplanationFragment: '', // Start with empty fragment
    ));

    try {
      print("QuizBloc: Clearing chat history for explanation...");
      await _chat.clearHistory(); // Clear history before explanation request

      final explanationPrompt = PromptManager.generateExplanationPrompt(
        event.questionText,
        event.options,
        event.selectedOptionIndex,
      );

      final String localizedPrompt='Respond in ${_currentLanguageCode}:$explanationPrompt';


      print("QuizBloc: Explanation prompt: $explanationPrompt");

      await _chat.addQueryChunk(Message.text(text: localizedPrompt, isUser: true));
      print("QuizBloc: Sending query chunk for explanation...");

      String fullExplanation = '';
      final responseStream = _chat.generateChatResponseAsync(); // Use the shared _chat instance
      print("QuizBloc: Generating response stream for explanation...");

      // Stream the explanation parts
      await for (final responsePart in responseStream.timeout(const Duration(seconds: 30))) {
        fullExplanation += responsePart;
        print("QuizBloc: Received explanation part: $responsePart");
        // Emit new loading state with the current fragment
        emit(QuizLoadingExplanation(
          quiz: currentQuiz,
          userAnswers: currentUserAnswers,
          explanations: currentExplanations,
          questionIndexLoading: event.questionIndex,
          streamingExplanationFragment: fullExplanation, // Update fragment
        ));
        // Add a small delay to allow UI to update
        await Future.delayed(const Duration(milliseconds: 10)); // Yield control
      }
      print("QuizBloc: Full explanation received: $fullExplanation");


      currentExplanations[event.questionIndex] = fullExplanation;

      print("QuizBloc: Emitting QuizDisplay with complete explanation.");
      emit(QuizDisplay(
        quiz: currentQuiz,
        userAnswers: currentUserAnswers,
        explanations: currentExplanations,
        streamingExplanationFragment: null, // Clear fragment on completion
      ));
    } on TimeoutException catch (e) {
      print("QuizBloc: Explanation generation timed out: $e");
      emit(QuizError(
        error: 'Explanation generation timed out. Please try again.',
        quiz: currentQuiz,
        userAnswers: currentUserAnswers,
        explanations: currentExplanations,
        streamingExplanationFragment: null, // Clear fragment on error
      ));
      emit(QuizDisplay( // Revert to display state after error
        quiz: currentQuiz,
        userAnswers: currentUserAnswers,
        explanations: currentExplanations,
        streamingExplanationFragment: null, // Clear fragment on error
      ));
    } catch (e) {
      print("QuizBloc: Error generating explanation: $e");
      emit(QuizError(
        error: 'Failed to get explanation: $e',
        quiz: currentQuiz,
        userAnswers: currentUserAnswers,
        explanations: currentExplanations,
        streamingExplanationFragment: null, // Clear fragment on error
      ));
      emit(QuizDisplay( // Revert to display state after error
        quiz: currentQuiz,
        userAnswers: currentUserAnswers,
        explanations: currentExplanations,
        streamingExplanationFragment: null, // Clear fragment on error
      ));
    } finally {
      print("QuizBloc: Explanation request processed.");
    }
  }
}