import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:isolate';
import 'dart:ui';

import 'package:anticipatorygpt/management/model_settings.dart';
import 'package:anticipatorygpt/management/prompt_management.dart';
import 'package:anticipatorygpt/model_download/model_repository.dart';
import 'package:anticipatorygpt/quiz/quiz_model.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';
// import 'package:flutter_gemma/mobile/flutter_gemma_mobile.dart';
import 'package:meta/meta.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
part 'chat_event.dart';
part 'chat_state.dart';



Future<bool> _initializeModelInIsolate(Map<String,dynamic> args)
async{
  final String modelPath=args['modelPath'];

  final RootIsolateToken rootIsolateToken=args['rootIsolateToken'];

  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

  final gemma=FlutterGemmaPlugin.instance;

  try
      {

        await gemma.modelManager.setModelPath(modelPath);
        final model= await gemma.createModel(modelType: ModelType.gemmaIt,
        preferredBackend: PreferredBackend.gpu,supportImage: true);

        model.close();
        return true;
      }
      catch(e)
  {
    print("Isolate initialization failed: $e");
    return false;
  }

}


class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ModelRepository _modelRepository;
  final FlutterGemmaPlugin _gemmaPlugin =FlutterGemmaPlugin.instance;

  InferenceModel? _inferenceModel;
  InferenceChat? _chat;
  // bool _isModelLoaded=false;

  StreamSubscription? _responseSubscription;

  bool _isContextAware=false;

  String _currentLanguageCode='en-Us';

  InferenceChat? get chatInstance =>_chat;

  ChatBloc(this._modelRepository) : super(ChatInitial()) {
    // on<ChatEvent>((event, emit) {
    //   // TODO: implement event handler
    // });
    on<InitializeChat>(_onInitializeChat);
    on<SendMessage>(_onSendMessage);
    on<ClearQuizState>(_onClearQuizState);
    on<ToggleContext>(_onToggleContext);
    // _initialize();
  }

  Future<void> _onInitializeChat(
      InitializeChat event,
      Emitter<ChatState> emit
      )async
  {
    if(state is !ChatModelLoading)
      {
        emit(ChatModelLoading());
      }
    try{
      final modelPath=await _modelRepository.getModelFilePath();

      final rootIsolateToken =RootIsolateToken.instance;

      if(rootIsolateToken==null)
        {
          throw Exception("Failed to get RootIsolateToken.");
        }

      print("Spawning Isolate for model initialization...");

      final bool success= await Isolate.run(()=>_initializeModelInIsolate({'modelPath':modelPath,'rootIsolateToken':rootIsolateToken}));
      await _gemmaPlugin.modelManager.setModelPath(modelPath);
      if(!success)
        {
          throw Exception("Isolate failed to initialize the model");
        }
      const backend=PreferredBackend.gpu;

      _inferenceModel=await _gemmaPlugin.createModel(modelType: ModelType.gemmaIt,preferredBackend: backend,supportImage: true);

      print("✅ AI Model Initialized successfully with Backend: ${backend.name}");

      _chat=await _inferenceModel!.createChat(supportImage: true,
      temperature: ModelSettings.defaultTemperature,
      topK: ModelSettings.defaultTopK,
      topP: ModelSettings.defaultTopP,
      );

      emit(ChatInitial());
    }
    catch(e)
    {
        print("❌ Failed to initialize AI model: $e");
        emit(ChatError(error:'Failed to initialize AI model: $e', messages: [], isContextAware:state.isContextAware, languageCode:state.languageCode));
    }
  }

  // Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async
  // {
  //
  //   if (_chat==null)
  //     {
  //       emit(ChatError(error: 'Chat session is not initialized.', messages: state.messages));
  //       return;
  //     }
  //
  //   final userMessage=ChatMessage(text: event.message,imageBytes: event.imageBytes,isFromUser: true);
  //
  //   final updatedMessages=List<ChatMessage>.from(state.messages)..add(userMessage);
  //
  //
  //   final modelResponsePlaceholder=ChatMessage(text: '', isFromUser: false);
  //
  //   final messagesWithPlaceholder=List<ChatMessage>.from(updatedMessages)..add(modelResponsePlaceholder);
  //
  //
  //   emit(ChatLoading(messages: messagesWithPlaceholder));
  //
  //   try{
  //
  //       final Message promptMessage;
  //
  //       if(event.imageBytes!=null)
  //         {
  //           promptMessage=Message.withImage(text: event.message, imageBytes:event.imageBytes!,isUser: true);
  //         }
  //       else
  //         {
  //           promptMessage=Message.text(text: event.message,isUser: true);
  //         }
  //
  //
  //     await _chat!.addQueryChunk(promptMessage);
  //
  //     final responseStream= _chat!.generateChatResponseAsync();
  //
  //     String fullResponse='';
  //
  //
  //
  //     await for(final responsePart in responseStream)
  //       {
  //         if(isClosed) return;
  //         fullResponse+=responsePart;
  //         final currentMessages=List<ChatMessage>.from(updatedMessages);
  //         currentMessages.add(ChatMessage(text: fullResponse, isFromUser: false));
  //         emit(ChatLoading(messages: currentMessages));
  //       }
  //
  //     final finalMessages=List<ChatMessage>.from(updatedMessages)..add(ChatMessage(text: fullResponse, isFromUser: false));
  //     emit(ChatLoaded(messages: finalMessages));
  //
  //   }
  //   catch(e)
  //   {
  //     // if(!isClosed) {
  //       emit(ChatError(error: 'Failed to get response from model: $e',
  //           messages: updatedMessages));
  //     // }
  //       }
  //
  // }
  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async
  {
    if (_chat==null)
    {
      emit(ChatError(error: 'Chat session is not initialized.', messages: state.messages, isContextAware:state.isContextAware, languageCode:state.languageCode));
      return;
    }

    final userMessageText = event.message.trim();
    final userMessage=ChatMessage(text: userMessageText,imageBytes: event.imageBytes,isFromUser: true);

    // Create a mutable list of messages from the current state
    final updatedMessages = List<ChatMessage>.from(state.messages);
    updatedMessages.add(userMessage); // Add the user's message

    if (userMessageText.toLowerCase() == '/aware') {
      _isContextAware = true;
      final confirmationMessage = ChatMessage(text: 'AI is now aware of chat history.', isFromUser: false);
      final finalMessages = List<ChatMessage>.from(updatedMessages)
        ..add(confirmationMessage);
      emit(ChatLoaded(messages: finalMessages, isContextAware: _isContextAware, languageCode:state.languageCode));
      return;
    } else if (userMessageText.toLowerCase() == '/clear') {
      _isContextAware = false;
      await _chat!.clearHistory();
      final confirmationMessage = ChatMessage(text: 'Chat history has been cleared.', isFromUser: false);
      final finalMessages = List<ChatMessage>.from(updatedMessages)
        ..add(confirmationMessage);
      emit(ChatLoaded(messages: finalMessages, isContextAware: _isContextAware, languageCode:state.languageCode));
      return;
    }
    else if (userMessageText.toLowerCase().startsWith('/language')) {
      final language = userMessageText.substring('/language'.length).trim().toLowerCase();
      // Remove the _languageMap and use a more flexible approach
      if (language.isNotEmpty) {
        _currentLanguageCode = language; // Directly use the provided string as the code
        await _chat!.clearHistory();
        final confirmationMessage = ChatMessage(text: 'AI will now respond in ${language}.', isFromUser: false);
        final finalMessages = List<ChatMessage>.from(updatedMessages)..add(confirmationMessage);
        emit(ChatLoaded(messages: finalMessages, isContextAware: _isContextAware, languageCode: _currentLanguageCode));
      } else {
        final errorMessage = ChatMessage(text: 'Please specify a language after /language.', isFromUser: false);
        final finalMessages = List<ChatMessage>.from(updatedMessages)..add(errorMessage);
        emit(ChatLoaded(messages: finalMessages, isContextAware: _isContextAware, languageCode: _currentLanguageCode));
      }
      return;
    }

    // Check if the user is requesting a quiz
    final isQuizRequest = userMessageText.toLowerCase().startsWith('/quiz');
    String promptToModel;
    String loadingMessage;

    if (isQuizRequest) {
      final topic = userMessageText.substring('/quiz'.length).trim();
      promptToModel = PromptManager.generateQuizRequestPrompt(topic.isEmpty ? 'general knowledge' : topic);
      loadingMessage = 'Generating quiz on ${topic.isEmpty ? 'general knowledge' : topic}...';
    } else {
      promptToModel = PromptManager.generateChatPrompt(userMessageText);
      loadingMessage = ''; // Standard chat loading message, will be replaced by full response
    }

    // Add a placeholder message for AI response or quiz generation
    final modelResponsePlaceholder = ChatMessage(text: loadingMessage, isFromUser: false);
    updatedMessages.add(modelResponsePlaceholder); // Add the placeholder to the mutable list

    emit(ChatLoading(messages: updatedMessages, languageCode:state.languageCode, isContextAware:state.isContextAware)); // Emit loading state with placeholder

    try{
      final Message promptMessage;

      if(!state.isContextAware) {
        await _chat!.clearHistory();
      }
      String localizedPrompt='Respond in ${_currentLanguageCode}:$promptToModel';


      if(event.imageBytes!=null) {
        promptMessage = Message.withImage(text: localizedPrompt, imageBytes:event.imageBytes!,isUser: true);
      } else {
        promptMessage = Message.text(text: localizedPrompt,isUser: true);
      }

      await _chat!.addQueryChunk(promptMessage);

      final responseStream = _chat!.generateChatResponseAsync();

      String fullResponse='';
      await for(final responsePart in responseStream) {
        if(isClosed) return;
        fullResponse+=responsePart;

        // ONLY for non-quiz requests, update the placeholder with streaming response
        if (!isQuizRequest) {
          final currentMessages = List<ChatMessage>.from(updatedMessages);
          // Replace the last message (placeholder) with the current streaming response
          currentMessages[currentMessages.length - 1] = ChatMessage(text: fullResponse, isFromUser: false);
          emit(ChatLoading(messages: currentMessages, languageCode:state.languageCode, isContextAware:state.isContextAware));
        }
      }

      // After streaming is complete, prepare the final messages
      final List<ChatMessage> finalMessages = List<ChatMessage>.from(updatedMessages);
      // Remove the placeholder message before adding the final response or quiz ready message
      finalMessages.removeLast();


      if (isQuizRequest) {
        String cleanedJsonResponse = fullResponse;
        // Robust JSON extraction: Find the first '[' and last ']'
        final int startIndex = fullResponse.indexOf('[');
        final int endIndex = fullResponse.lastIndexOf(']');

        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
          cleanedJsonResponse = fullResponse.substring(startIndex, endIndex + 1);
        } else {
          // If '[' and ']' not found, or invalid range, log and try to parse full response
          print("Warning: Could not find valid JSON array delimiters. Attempting to parse full response.");
        }


        try {
          // Attempt to parse the cleaned response as JSON for the quiz
          final List<dynamic> jsonList = jsonDecode(cleanedJsonResponse);
          final Quiz generatedQuiz = Quiz.fromJson(jsonList);

          // Add a clean, concise message for quiz readiness
          finalMessages.add(ChatMessage(text: 'Your quiz is ready! Tap "Start Quiz!" below.', isFromUser: false));
          emit(ChatQuizReady(messages: finalMessages, generatedQuiz: generatedQuiz,isContextAware: state.isContextAware, languageCode:state.languageCode));

        } catch (e) {
          print("Failed to parse quiz JSON: $e");
          // If JSON parsing fails, treat it as a regular text response with an error
          finalMessages.add(ChatMessage(text: 'Failed to generate quiz. Please try again or rephrase your request. Error: $e', isFromUser: false));
          emit(ChatLoaded(messages: finalMessages,isContextAware: state.isContextAware, languageCode:state.languageCode));
        }
      } else {
        // For regular chat, add the full response
        finalMessages.add(ChatMessage(text: fullResponse, isFromUser: false));
        emit(ChatLoaded(messages: finalMessages,isContextAware: state.isContextAware, languageCode:state.languageCode));
      }

    }
    catch(e)
    {
      // If an error occurs during generation, replace the placeholder with an error message
      final List<ChatMessage> errorMessages = List<ChatMessage>.from(updatedMessages);
      errorMessages.removeLast(); // Remove placeholder
      errorMessages.add(ChatMessage(text: 'Failed to get response from model: $e', isFromUser: false));
      emit(ChatError(error: 'Failed to get response from model: $e', messages: errorMessages, isContextAware:state.isContextAware, languageCode: ''));
    }
  }

  void _onClearQuizState(ClearQuizState event, Emitter<ChatState> emit) async{
    // Emit a ChatLoaded state, preserving messages but clearing quiz flags

    await _chat?.clearHistory();
    // _inferenceModel?.createChat(
    //   supportImage: true,
    //   temperature: ModelSettings.defaultTemperature,
    //   topK: ModelSettings.defaultTopK,
    //   topP: ModelSettings.defaultTopP
    // ).then((newChat){
    //   _chat=newChat;
      emit(ChatLoaded(messages: state.messages, quizReady: false, generatedQuiz: null,isContextAware: _isContextAware, languageCode:state.languageCode));
    // }).catchError((error){
    //   print("Error re-creating main chat session: $error");
    //
    //   emit(ChatError(error: 'Failed to reset chat session: $error', messages:state.messages,quizReady: false,generatedQuiz: null));
    // });


  }

  // New handler for ToggleContext event
  void _onToggleContext(ToggleContext event, Emitter<ChatState> emit) {
    _isContextAware = !_isContextAware;
    // Emit a ChatLoaded state that reflects the new context mode.
    // The UI can react to this if needed, but it's primarily for internal BLoC logic.
    emit(ChatLoaded(messages: state.messages, isContextAware: _isContextAware, languageCode:state.languageCode));
  }

  @override
  Future<void> close() {
    // _chatPlugin.dispose();
    _inferenceModel?.close();
    return super.close();
  }
}
