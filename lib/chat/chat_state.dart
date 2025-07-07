part of 'chat_bloc.dart';


class ChatMessage extends Equatable
{
  final String text;
  final bool isFromUser;

  const ChatMessage({required this.text,required this.isFromUser});

  @override
  List<Object> get props=>[text,isFromUser];
}





@immutable
sealed class ChatState extends Equatable{
  final List<ChatMessage> messages;

  const ChatState({this.messages=const []});

  @override
  List<Object> get props => [messages];
}

final class ChatInitial extends ChatState {}


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

