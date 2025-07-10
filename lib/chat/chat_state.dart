part of 'chat_bloc.dart';


class ChatMessage extends Equatable
{
  final String text;
  final Uint8List? imageBytes;
  final bool isFromUser;

  const ChatMessage({required this.text,this.imageBytes,required this.isFromUser});

  @override
  List<Object?> get props=>[text,imageBytes,isFromUser];
}





@immutable
sealed class ChatState extends Equatable{
  final List<ChatMessage> messages;

  const ChatState({this.messages=const []});

  @override
  List<Object> get props => [messages];
}

// state while the ai model is ready but no message have been sent yet
final class ChatInitial extends ChatState {}

// state while ai is being loaded into memory
class ChatModelLoading extends ChatState{}





// state when the model is processing a message
class ChatLoading extends ChatState
{
  const ChatLoading({required super.messages});
}

class ChatLoaded extends ChatState
{
  const ChatLoaded({required super.messages});
}

class ChatError extends ChatState
{
  final String error;

  const ChatError({required this.error,required super.messages});


  @override
  // TODO: implement props
  List<Object> get props => [error,messages];
}

