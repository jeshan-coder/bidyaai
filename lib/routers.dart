import 'package:anticipatorygpt/model_download/downloadscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat/ChatScreen.dart';
import 'chat/chat_bloc.dart';
import 'home/home.dart';
import 'model_download/model_repository.dart';
import 'notFound.dart';

class AppRoutes {
  static const String home = '/';
  static const String download = "/download";
  static const String chat = "/chat";
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

      default:
      // Fallback for undefined routes
        return MaterialPageRoute(builder: (_) => NotFound());
    }
  }
}
