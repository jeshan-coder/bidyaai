import 'dart:async';
import 'dart:convert';
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

  InferenceChat? get chatInstance =>_chat;

  ChatBloc(this._modelRepository) : super(ChatInitial()) {
    // on<ChatEvent>((event, emit) {
    //   // TODO: implement event handler
    // });
    on<InitializeChat>(_onInitializeChat);
    on<SendMessage>(_onSendMessage);
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
        emit(ChatError(error:'Failed to initialize AI model: $e', messages: []));
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
  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit)
  async
  {
    if (_chat==null)
    {
      emit(ChatError(error: 'Chat session is not initialized.', messages: state.messages));
      return;
    }

    final userMessageText = event.message.trim();
    final userMessage=ChatMessage(text: userMessageText,imageBytes: event.imageBytes,isFromUser: true);

    final updatedMessages=List<ChatMessage>.from(state.messages)..add(userMessage);

    // Check if the user is requesting a quiz
    final isQuizRequest = userMessageText.toLowerCase().startsWith('make quiz on');
    String promptToModel;
    String loadingMessage;

    if (isQuizRequest) {
      final topic = userMessageText.substring('make quiz on'.length).trim();
      promptToModel = PromptManager.generateQuizRequestPrompt(topic.isEmpty ? 'general knowledge' : topic);
      loadingMessage = 'Generating quiz on ${topic.isEmpty ? 'general knowledge' : topic}...';
    } else {
      promptToModel = PromptManager.generateChatPrompt(userMessageText);
      loadingMessage = ''; // Standard chat loading message handled by UI
    }

    // Add a placeholder message for AI response or quiz generation
    final modelResponsePlaceholder = ChatMessage(text: loadingMessage, isFromUser: false);
    final messagesWithPlaceholder = List<ChatMessage>.from(updatedMessages)..add(modelResponsePlaceholder);

    emit(ChatLoading(messages: messagesWithPlaceholder));

    try{
      final Message promptMessage;

      if(event.imageBytes!=null) {
        promptMessage = Message.withImage(text: promptToModel, imageBytes:event.imageBytes!,isUser: true);
      } else {
        promptMessage = Message.text(text: promptToModel,isUser: true);
      }

      await _chat!.addQueryChunk(promptMessage);

      // Generate response without passing generation parameters here, as they are set during createChat
      final responseStream = _chat!.generateChatResponseAsync();

      String fullResponse='';
      await for(final responsePart in responseStream) {
        if(isClosed) return;
        fullResponse+=responsePart;
        // Update the placeholder message with streaming response
        final currentMessages = List<ChatMessage>.from(updatedMessages);
        currentMessages.add(ChatMessage(text: fullResponse, isFromUser: false));
        emit(ChatLoading(messages: currentMessages));
      }

      if (isQuizRequest) {
        try {
          // Attempt to parse the response as JSON for the quiz
          final List<dynamic> jsonList = jsonDecode(fullResponse);
          final Quiz generatedQuiz = Quiz.fromJson(jsonList);

          // Emit ChatQuizReady state with the generated quiz
          final finalMessages = List<ChatMessage>.from(updatedMessages)
            ..add(ChatMessage(text: 'Quiz generated! Click the button below to start.', isFromUser: false));
          emit(ChatQuizReady(messages: finalMessages, generatedQuiz: generatedQuiz));

        } catch (e) {
          print("Failed to parse quiz JSON: $e");
          // If JSON parsing fails, treat it as a regular text response
          final finalMessages = List<ChatMessage>.from(updatedMessages)
            ..add(ChatMessage(text: fullResponse, isFromUser: false));
          emit(ChatLoaded(messages: finalMessages));
        }
      } else {
        // For regular chat, emit ChatLoaded with the full response
        final finalMessages = List<ChatMessage>.from(updatedMessages)
          ..add(ChatMessage(text: fullResponse, isFromUser: false));
        emit(ChatLoaded(messages: finalMessages));
      }

    }
    catch(e)
    {
      emit(ChatError(error: 'Failed to get response from model: $e',
          messages: updatedMessages));
    }

  }
  
  @override
  Future<void> close() {
    // _chatPlugin.dispose();
    _inferenceModel?.close();
    return super.close();
  }
}
