
import 'dart:async';
import 'package:anticipatorygpt/management/prompt_management.dart';
import 'package:anticipatorygpt/quiz/quiz_event.dart';
import 'package:anticipatorygpt/quiz/quiz_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

class QuizBloc extends Bloc<QuizEvent,QuizState>
{
  final InferenceChat _chat;
  
  QuizBloc({required InferenceChat chat}):_chat=chat,super(QuizInitial())
  {
    on<InitializeQuiz>(_onInitializeQuiz);
    on<SubmitAnswer>(_onSubmitAnswer);
    on<RequestExplanation>(_onRequestExplanation);
  }
  
  Future<void> _onInitializeQuiz(InitializeQuiz event, Emitter<QuizState> emit)async
  {
    emit(QuizDisplay(quiz: event.quiz));
  }
  
  
  Future<void> _onSubmitAnswer(SubmitAnswer event, Emitter<QuizState> emit) async
  {
    if(state is QuizDisplay)
      {
        final currentState= state as QuizDisplay;
        
        final updatedUserAnswers= Map<int,int?>.from(currentState.userAnswers);
        
        updatedUserAnswers[event.questionIndex]=event.selectedOptionIndex;
      
        print("state is Quiz Display");
        print("updated user answer: $updatedUserAnswers");
        print("selected option index: ${event.selectedOptionIndex}");
        
        emit(QuizDisplay(quiz: currentState.quiz,userAnswers: updatedUserAnswers,explanations: currentState.explanations));
      }
  }


  Future<void> _onRequestExplanation(
      RequestExplanation event, Emitter<QuizState> emit) async {
    if (state is! QuizDisplay && state is! QuizLoadingExplanation) {
      return;
    }
    print("on request explanation called ");
    final currentState = state;
    final currentQuiz = currentState.quiz;
    final currentUserAnswers = currentState.userAnswers;
    final currentExplanations = Map<int, String?>.from(currentState.explanations);

    emit(QuizLoadingExplanation(
      quiz: currentQuiz,
      userAnswers: currentUserAnswers,
      explanations: currentExplanations,
      questionIndexLoading: event.questionIndex,
    ));

    InferenceChat? explanationChat; // Declare temporary chat session
    try {
      print("QuizBloc: Creating temporary chat session for explanation...");

      await _chat.clearHistory();
      print("explaination chat called .");
      final explanationPrompt = PromptManager.generateExplanationPrompt(
        event.questionText,
        event.options,
        event.selectedOptionIndex,
      );
      print("QuizBloc: Explanation prompt: $explanationPrompt");

      await _chat.addQueryChunk(Message.text(text: explanationPrompt, isUser: true));

      print("QuizBloc: Sending query chunk for explanation...");

      String fullExplanation = '';
      final responseStream = _chat.generateChatResponseAsync();
      print("QuizBloc: Generating response stream for explanation...");

      // Add a timeout for the explanation generation
      await for (final responsePart in responseStream.timeout(const Duration(seconds: 30))) { // 30-second timeout
        fullExplanation += responsePart;
        print("QuizBloc: Received explanation part: $responsePart");
      }
      print("QuizBloc: Full explanation received: $fullExplanation");


      currentExplanations[event.questionIndex] = fullExplanation;

      print("QuizBloc: Emitting QuizDisplay with explanation.");
      emit(QuizDisplay(
        quiz: currentQuiz,
        userAnswers: currentUserAnswers,
        explanations: currentExplanations,
      ));
    } on TimeoutException catch (e) {
      print("QuizBloc: Explanation generation timed out: $e");
      emit(QuizError(
        error: 'Explanation generation timed out. Please try again.',
        quiz: currentQuiz,
        userAnswers: currentUserAnswers,
        explanations: currentExplanations,
      ));
      emit(QuizDisplay( // Revert to display state after error
        quiz: currentQuiz,
        userAnswers: currentUserAnswers,
        explanations: currentExplanations,
      ));
    } catch (e) {
      print("QuizBloc: Error generating explanation: $e");
      emit(QuizError(
        error: 'Failed to get explanation: $e',
        quiz: currentQuiz,
        userAnswers: currentUserAnswers,
        explanations: currentExplanations,
      ));
      emit(QuizDisplay( // Revert to display state after error
        quiz: currentQuiz,
        userAnswers: currentUserAnswers,
        explanations: currentExplanations,
      ));
    } finally {
      // The temporary chat session will be garbage collected when it goes out of scope.
      // No explicit close() method on InferenceChat.
      print("QuizBloc: Explanation chat session scope ended.");
    }
  }
 
}