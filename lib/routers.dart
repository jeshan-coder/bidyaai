import 'package:anticipatorygpt/camera_live/camera_bloc.dart';
import 'package:anticipatorygpt/camera_live/camera_screen.dart';
import 'package:anticipatorygpt/model_download/downloadscreen.dart';
import 'package:anticipatorygpt/quiz/quiz_model.dart';
import 'package:anticipatorygpt/quiz/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'chat/ChatScreen.dart';
import 'chat/chat_bloc.dart';
import 'home/home.dart';
import 'model_download/model_repository.dart';
import 'notFound.dart';

class AppRoutes {
  static const String home = '/';
  static const String download = "/download";
  static const String chat = "/chat";
  static const String quiz="/quiz";
  static const String cameraLive="/cameraLive";
}

class AppRouter {
  /// Generates the route based on the [RouteSettings].
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => Home());

      case AppRoutes.download:
        return MaterialPageRoute(builder: (_) => DownloadScreen());

      case AppRoutes.chat:
        return MaterialPageRoute(builder: (_) =>
            BlocProvider(
              create: (context) => ChatBloc(
                RepositoryProvider.of<ModelRepository>(context),
              ),
              child: ChatScreen(),
            ));

      case AppRoutes.quiz:
      // Extract arguments for QuizScreen
        final args = settings.arguments as Map<String, dynamic>;
        final Quiz quiz = args['quiz'] as Quiz;
        final InferenceChat chatInstance= args['chatInstance'] as InferenceChat; // InferenceChat instance
        final String languageCode = args['languageCode'] as String;

        if (chatInstance == null) {
          // Handle error if chatInstance is not passed or is null
          return MaterialPageRoute(builder: (_) =>
          const Center(child: Text('Error:AI Model not available for quiz.')));
        }

        return MaterialPageRoute(builder: (_) =>
            QuizScreen(
              quiz: quiz,
              chatInstance:chatInstance,
              languageCode: languageCode,
            ));


      case AppRoutes.cameraLive:
        final args=settings.arguments as Map<String,dynamic>;
        final InferenceChat chatInstance= args['chatInstance'] as InferenceChat;

        if(chatInstance==null)
          {
            return MaterialPageRoute(builder: (_)=>const Center(child: Text("Error: chat instance not available for camera AI"),));

          }
        return MaterialPageRoute(builder: (_)=>BlocProvider(create:(context)=>CameraBloc(chat: chatInstance),
        child: CameraScreen(chatInstance: chatInstance),));


      default:
      // Fallback for undefined routes
        return MaterialPageRoute(builder: (_) => NotFound());
    }
  }
}
