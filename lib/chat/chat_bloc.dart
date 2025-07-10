import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:anticipatorygpt/model_download/model_repository.dart';
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
      
      _chat=await _inferenceModel!.createChat(supportImage: true);
      
      emit(ChatInitial());
    }
    catch(e)
    {
        print("❌ Failed to initialize AI model: $e");
        emit(ChatError(error:'Failed to initialize AI model: $e', messages: []));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async
  {

    if (_chat==null)
      {
        emit(ChatError(error: 'Chat session is not initialized.', messages: state.messages));
        return;
      }

    final userMessage=ChatMessage(text: event.message,imageBytes: event.imageBytes,isFromUser: true);

    final updatedMessages=List<ChatMessage>.from(state.messages)..add(userMessage);


    final modelResponsePlaceholder=ChatMessage(text: '', isFromUser: false);

    final messagesWithPlaceholder=List<ChatMessage>.from(updatedMessages)..add(modelResponsePlaceholder);


    emit(ChatLoading(messages: messagesWithPlaceholder));

    try{

        final Message promptMessage;

        if(event.imageBytes!=null)
          {
            promptMessage=Message.withImage(text: event.message, imageBytes:event.imageBytes!,isUser: true);
          }
        else
          {
            promptMessage=Message.text(text: event.message,isUser: true);
          }


      await _chat!.addQueryChunk(promptMessage);

      final responseStream= _chat!.generateChatResponseAsync();

      String fullResponse='';



      await for(final responsePart in responseStream)
        {
          if(isClosed) return;
          fullResponse+=responsePart;
          final currentMessages=List<ChatMessage>.from(updatedMessages);
          currentMessages.add(ChatMessage(text: fullResponse, isFromUser: false));
          emit(ChatLoading(messages: currentMessages));
        }

      final finalMessages=List<ChatMessage>.from(updatedMessages)..add(ChatMessage(text: fullResponse, isFromUser: false));
      emit(ChatLoaded(messages: finalMessages));

    }
    catch(e)
    {
      // if(!isClosed) {
        emit(ChatError(error: 'Failed to get response from model: $e',
            messages: updatedMessages));
      // }
        }

  }
  @override
  Future<void> close() {
    // _chatPlugin.dispose();
    _inferenceModel?.close();
    return super.close();
  }
}
