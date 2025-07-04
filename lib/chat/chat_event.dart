part of 'chat_bloc.dart';

@immutable
sealed class ChatEvent extends Equatable{
  const ChatEvent();

  @override
  List<Object> get props => [];
}


class InitializeGemma extends ChatEvent{}

class SendMessage extends ChatEvent{
  final String message;
  const SendMessage(this.message);

  @override
  List<Object> get props => [message];
}


