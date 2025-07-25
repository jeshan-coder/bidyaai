
import 'package:anticipatorygpt/management/model_settings.dart';
import 'package:anticipatorygpt/management/prompt_management.dart';
import 'package:anticipatorygpt/quiz/quiz_event.dart';
import 'package:anticipatorygpt/quiz/quiz_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

class QuizBloc extends Bloc<QuizEvent,QuizState>
{
  final InferenceModel _inferenceModel;
  
  QuizBloc({required InferenceModel inferenceModel}):_inferenceModel=inferenceModel,super(QuizInitial())
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


  Future<void> _onRequestExplanation(RequestExplanation event, Emitter<QuizState> emit) async
  {
    if(state is !QuizDisplay && state is !QuizLoadingExplanation)
      {
        return;
      }

    final currentState=state;
    final currentQuiz=currentState.quiz;
    final currentUserAnswers=currentState.userAnswers;
    final currentExplanations= Map<int,String?>.from(currentState.explanations);
  
    print("onRequest Explanation:");
    print("current state is $currentState");
    print("current user answers is ${currentState.userAnswers}");
    
    emit(QuizLoadingExplanation(quiz: currentQuiz, 
        userAnswers: currentUserAnswers, 
        explanations: currentExplanations, 
        questionIndexLoading: event.questionIndex));
    
    InferenceChat? explanationChat;

    try{
      explanationChat = await _inferenceModel.createChat(
        supportImage: false, // Explanations are text-only
        temperature: ModelSettings.defaultTemperature,
        topK: ModelSettings.defaultTopK,
        topP: ModelSettings.defaultTopP,
      );

      final explanationPrompt = PromptManager.generateExplanationPrompt(
        event.questionText,
        event.options,
        event.selectedOptionIndex,
      );

      await explanationChat.addQueryChunk(Message.text(text: explanationPrompt, isUser: true));

      String fullExplanation = '';
      final responseStream = explanationChat.generateChatResponseAsync();

      await for (final responsePart in responseStream) {
        fullExplanation += responsePart;
      }

      currentExplanations[event.questionIndex] = fullExplanation;

      emit(QuizDisplay(
        quiz: currentQuiz,
        userAnswers: currentUserAnswers,
        explanations: currentExplanations,
      ));
    }
    catch(e)
    {
      print("Error generating explanation: $e");

      emit(QuizError(error: 'Failed to get explanation: $e',
      quiz: currentQuiz,
      userAnswers: currentUserAnswers,
      explanations: currentExplanations));

      emit(QuizDisplay(
        quiz: currentQuiz,
        userAnswers: currentUserAnswers,
        explanations: currentExplanations,
      ));
    }
    finally{

    }
  
  
  }
 
}