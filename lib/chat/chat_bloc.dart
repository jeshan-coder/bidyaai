import 'package:anticipatorygpt/model_download/model_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_mediapipe_chat/flutter_mediapipe_chat.dart';
import 'package:meta/meta.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ModelRepository _modelRepository;
  final FlutterMediapipeChat _chatPlugin =FlutterMediapipeChat();

  bool _isModelLoaded=false;

  ChatBloc(this._modelRepository) : super(ChatInitial()) {
    // on<ChatEvent>((event, emit) {
    //   // TODO: implement event handler
    // });
    on<SendMessage>(_onSendMessage);
    _initialize();
  }

  Future<void> _initialize() async
  {
    try{
      final modelPath= await _modelRepository.getModelFilePath();

      final config=ModelConfig(path: modelPath,
      temperature: 0.8,
      maxTokens: 2048,
      topK: 40);

      await _chatPlugin.loadModel(config);
      _isModelLoaded=true;
    }
    catch(e)
    {
      emit(ChatError(error: 'Failed to initialize AI model: $e', messages:[]));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async
  {
    if (!_isModelLoaded)
      {
        emit(ChatError(error: 'AI Model is not initialized', messages: state.messages));
        return;
      }

    final userMessage=ChatMessage(text: event.message, isFromUser: true);

    final updatedMessages=List<ChatMessage>.from(state.messages)..add(userMessage);


    final modelResponsePlaceholder=ChatMessage(text: '', isFromUser: false);

    final messagesWithPlaceholder=List<ChatMessage>.from(updatedMessages)..add(modelResponsePlaceholder);


    emit(ChatLoading(messages: messagesWithPlaceholder));

    try{
      final responseStream= _chatPlugin.generateResponseAsync(event.message);
      String fullResponse='';
      await for(final responsePart in responseStream)
        {
          fullResponse+=responsePart??'';
          final currentMessages=List<ChatMessage>.from(updatedMessages);
          currentMessages.add(ChatMessage(text: fullResponse, isFromUser: false));
          emit(ChatLoading(messages: currentMessages));
        }

      final finalMessages=List<ChatMessage>.from(updatedMessages)..add(ChatMessage(text: fullResponse, isFromUser: false));
      emit(ChatLoaded(messages: finalMessages));
    }
    catch(e)
    {
      emit(ChatError(error: 'Failed to send message: $e', messages: state.messages));
    }

  }
  @override
  Future<void> close() {
    // _chatPlugin.dispose();
    return super.close();
  }
}
