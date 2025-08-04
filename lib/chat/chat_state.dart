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

  // for quiz
  final bool quizReady;
  final Quiz? generatedQuiz;
  final bool isContextAware;
  final String languageCode;
  final bool readerReady;

  const ChatState({this.messages=const [],this.quizReady=false,this.generatedQuiz,this.isContextAware=false,this.languageCode='en-Us',this.readerReady=false});

  @override
  List<Object?> get props => [messages,quizReady,generatedQuiz,isContextAware,languageCode];
}

// state while the ai model is ready but no message have been sent yet
final class ChatInitial extends ChatState {}

// state while ai is being loaded into memory
class ChatModelLoading extends ChatState{}





// state when the model is processing a message
class ChatLoading extends ChatState
{
  const ChatLoading({required super.messages,super.quizReady,super.generatedQuiz,required super.isContextAware,required super.languageCode,required super.readerReady});
}

class ChatLoaded extends ChatState
{
  const ChatLoaded({required super.messages,super.quizReady,super.generatedQuiz,required super.isContextAware,required super.languageCode,required super.readerReady});
}

// for quiz
// successfully generated and is ready
class ChatQuizReady extends ChatState
{
  const ChatQuizReady({required super.messages,required super.generatedQuiz,required super.isContextAware,required super.languageCode,required super.readerReady}):super(quizReady: true);

  @override
  List<Object?> get props => [messages,generatedQuiz,isContextAware,languageCode,readerReady];
}

class ChatReaderReady extends ChatState
{
  const ChatReaderReady({required super.messages, required super.isContextAware, required super.languageCode})
      : super(readerReady: true);


  @override
  List<Object?> get props => [messages, isContextAware, languageCode, readerReady];
}



class ChatError extends ChatState
{
  final String error;

  const ChatError({required this.error,required super.messages,super.quizReady,super.generatedQuiz,required super.isContextAware,required super.languageCode,required super.readerReady});


  @override
  // TODO: implement props
  List<Object?> get props => [error,messages,quizReady,generatedQuiz,isContextAware,languageCode,readerReady];
}

