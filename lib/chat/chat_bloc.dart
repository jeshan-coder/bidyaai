import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:isolate';
import 'dart:ui';

import 'package:bidyaai/management/model_settings.dart';
import 'package:bidyaai/management/prompt_management.dart';
import 'package:bidyaai/model_download/model_repository.dart';
import 'package:bidyaai/quiz/quiz_model.dart';
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


// MODIFICATION: Removed the separate `_initializeModelInIsolate` function and its logic.
// This code is no longer needed as we are not using an isolate for initialization.

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ModelRepository _modelRepository;
  final FlutterGemmaPlugin _gemmaPlugin =FlutterGemmaPlugin.instance;
  final PreferredBackend _preferredBackend;

  InferenceModel? _inferenceModel;
  InferenceChat? _chat;
  // bool _isModelLoaded=false;

  StreamSubscription? _responseSubscription;

  bool _isContextAware=false;

  String _currentLanguageCode='en-Us';

  InferenceChat? get chatInstance =>_chat;

  ChatBloc(this._modelRepository, {bool useGpu = false})
      : _preferredBackend = useGpu ? PreferredBackend.gpu : PreferredBackend.cpu,
        super(ChatInitial()) {
    on<InitializeChat>(_onInitializeChat);
    on<SendMessage>(_onSendMessage);
    on<ClearQuizState>(_onClearQuizState);
    on<ToggleContext>(_onToggleContext);
    on<ClearReaderState>(_onClearReaderState);
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

      // MODIFICATION: Performing model initialization directly without an isolate.
      await _gemmaPlugin.modelManager.setModelPath(modelPath);

      _inferenceModel=await _gemmaPlugin.createModel(
          modelType: ModelType.gemmaIt,
          preferredBackend: _preferredBackend, // Using the saved backend preference
          supportImage: true);

      print("✅ AI Model Initialized successfully with Backend: ${_preferredBackend.name}");

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
      emit(ChatError(error:'Failed to initialize AI model: $e', messages: [], isContextAware:state.isContextAware, languageCode:state.languageCode, readerReady: false));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async
  {
    if (_chat==null)
    {
      emit(ChatError(error: 'Chat session is not initialized.', messages: state.messages, isContextAware:state.isContextAware, languageCode:state.languageCode,readerReady: state.readerReady));
      return;
    }

    final userMessageText = event.message.trim();
    final userMessage=ChatMessage(text: userMessageText,imageBytes: event.imageBytes,isFromUser: true);

    final updatedMessages = List<ChatMessage>.from(state.messages);
    updatedMessages.add(userMessage);

    if (userMessageText.toLowerCase() == '/aware') {
      _isContextAware = true;
      final confirmationMessage = ChatMessage(text: 'AI is now aware of chat history.', isFromUser: false);
      final finalMessages = List<ChatMessage>.from(updatedMessages)
        ..add(confirmationMessage);
      emit(ChatLoaded(messages: finalMessages, isContextAware: _isContextAware, languageCode:state.languageCode, readerReady: false));
      return;
    } else if (userMessageText.toLowerCase() == '/clear') {
      _isContextAware = false;
      await _chat!.clearHistory();
      final confirmationMessage = ChatMessage(text: 'Chat history has been cleared.', isFromUser: false);
      final finalMessages = List<ChatMessage>.from(updatedMessages)
        ..add(confirmationMessage);
      emit(ChatLoaded(messages: finalMessages, isContextAware: _isContextAware, languageCode:state.languageCode, readerReady: false));
      return;
    }
    else if (userMessageText.toLowerCase().startsWith('/language')) {
      final language = userMessageText.substring('/language'.length).trim().toLowerCase();
      if (language.isNotEmpty) {
        _currentLanguageCode = language;
        await _chat!.clearHistory();
        final confirmationMessage = ChatMessage(text: 'AI will now respond in ${language}.', isFromUser: false);
        final finalMessages = List<ChatMessage>.from(updatedMessages)..add(confirmationMessage);
        emit(ChatLoaded(messages: finalMessages, isContextAware: _isContextAware, languageCode: _currentLanguageCode, readerReady: false));
      }

      else {
        final errorMessage = ChatMessage(text: 'Please specify a language after /language.', isFromUser: false);
        final finalMessages = List<ChatMessage>.from(updatedMessages)..add(errorMessage);
        emit(ChatLoaded(messages: finalMessages, isContextAware: _isContextAware, languageCode: _currentLanguageCode, readerReady: false));
      }
      return;
    }
    else if (userMessageText.toLowerCase().startsWith('/reader')) {
      final finalMessages = List<ChatMessage>.from(updatedMessages)
        ..add(ChatMessage(text: 'Opening document reader...', isFromUser: false));
      emit(ChatReaderReady(messages: finalMessages, isContextAware: state.isContextAware, languageCode: state.languageCode));
      return;
    }

    final isQuizRequest = userMessageText.toLowerCase().startsWith('/quiz');
    String promptToModel;
    String loadingMessage;

    if (isQuizRequest) {
      final topic = userMessageText.substring('/quiz'.length).trim();
      promptToModel = PromptManager.generateQuizRequestPrompt(topic.isEmpty ? 'general knowledge' : topic);
      loadingMessage = 'Generating quiz on ${topic.isEmpty ? 'general knowledge' : topic}...';
    } else {
      promptToModel = PromptManager.generateChatPrompt(userMessageText);
      loadingMessage = '';
    }

    final modelResponsePlaceholder = ChatMessage(text: loadingMessage, isFromUser: false);
    updatedMessages.add(modelResponsePlaceholder);

    emit(ChatLoading(messages: updatedMessages, languageCode:state.languageCode, isContextAware:state.isContextAware, readerReady: state.readerReady));

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

        if (!isQuizRequest) {
          final currentMessages = List<ChatMessage>.from(updatedMessages);
          currentMessages[currentMessages.length - 1] = ChatMessage(text: fullResponse, isFromUser: false);
          emit(ChatLoading(messages: currentMessages, languageCode:state.languageCode, isContextAware:state.isContextAware, readerReady: state.readerReady));
        }
      }

      final List<ChatMessage> finalMessages = List<ChatMessage>.from(updatedMessages);
      finalMessages.removeLast();


      if (isQuizRequest) {
        String cleanedJsonResponse = fullResponse;
        final int startIndex = fullResponse.indexOf('[');
        final int endIndex = fullResponse.lastIndexOf(']');

        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
          cleanedJsonResponse = fullResponse.substring(startIndex, endIndex + 1);
        } else {
          print("Warning: Could not find valid JSON array delimiters. Attempting to parse full response.");
        }


        try {
          final List<dynamic> jsonList = jsonDecode(cleanedJsonResponse);
          final Quiz generatedQuiz = Quiz.fromJson(jsonList);

          finalMessages.add(ChatMessage(text: 'Your quiz is ready! Tap "Start Quiz!" below.', isFromUser: false));
          emit(ChatQuizReady(messages: finalMessages, generatedQuiz: generatedQuiz,isContextAware: state.isContextAware, languageCode:state.languageCode, readerReady: false));

        } catch (e) {
          print("Failed to parse quiz JSON: $e");
          finalMessages.add(ChatMessage(text: 'Failed to generate quiz. Please try again or rephrase your request. Error: $e', isFromUser: false));
          emit(ChatLoaded(messages: finalMessages,isContextAware: state.isContextAware, languageCode:state.languageCode, readerReady: false));
        }
      } else {
        finalMessages.add(ChatMessage(text: fullResponse, isFromUser: false));
        emit(ChatLoaded(messages: finalMessages,isContextAware: state.isContextAware, languageCode:state.languageCode, readerReady: false));
      }

    }
    catch(e)
    {
      final List<ChatMessage> errorMessages = List<ChatMessage>.from(updatedMessages);
      errorMessages.removeLast();
      errorMessages.add(ChatMessage(text: 'Failed to get response from model: $e', isFromUser: false));
      emit(ChatError(error: 'Failed to get response from model: $e', messages: errorMessages, isContextAware:state.isContextAware, languageCode: '', readerReady:state.readerReady));
    }
  }

  void _onClearQuizState(ClearQuizState event, Emitter<ChatState> emit) async{
    await _chat?.clearHistory();
    emit(ChatLoaded(messages: state.messages, quizReady: false, generatedQuiz: null,isContextAware: _isContextAware, languageCode:state.languageCode, readerReady: false));
  }

  // New handler for ToggleContext event
  void _onToggleContext(ToggleContext event, Emitter<ChatState> emit) {
    _isContextAware = !_isContextAware;
    emit(ChatLoaded(messages: state.messages, isContextAware: _isContextAware, languageCode:state.languageCode, readerReady: false));
  }
  void _onClearReaderState(ClearReaderState event, Emitter<ChatState> emit) async {
    if (!state.isContextAware) {
      await _chat?.clearHistory();
    }

    emit(ChatLoaded(messages: state.messages, quizReady: false, generatedQuiz: null, isContextAware: state.isContextAware, languageCode: state.languageCode, readerReady: false));
  }

  @override
  Future<void> close() {
    _inferenceModel?.close();
    return super.close();
  }
}