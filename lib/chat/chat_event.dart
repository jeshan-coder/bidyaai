part of 'chat_bloc.dart';
/*
event related to chat
Toggles context : responsible for clearing chat history or saved context
Clear Quiz State : responsible for clearing quiz state
Clear Reader State : responsible for clearing reader state
Send Message : responsible for sending message to AI
 */
@immutable
sealed class ChatEvent extends Equatable{
  const ChatEvent();

  @override
  List<Object?> get props => [];
}


class InitializeChat extends ChatEvent{}

class SendMessage extends ChatEvent{
  final String message;
  final Uint8List? imageBytes;
  const SendMessage(this.message,{this.imageBytes});

  @override
  List<Object?> get props => [message,imageBytes];
}

class ClearQuizState extends ChatEvent
{

}

class ToggleContext extends ChatEvent{}


class ClearReaderState extends ChatEvent
{

}


