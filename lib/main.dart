import 'package:anticipatorygpt/home/home.dart';
import 'package:anticipatorygpt/model_download/download_model_bloc.dart';
import 'package:anticipatorygpt/model_download/downloadscreen.dart';
import 'package:anticipatorygpt/routers.dart';
import 'package:anticipatorygpt/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'model_download/model_repository.dart';
import 'notFound.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => ModelRepository(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<DownloadModelBloc>(
            create: (context) => DownloadModelBloc(
              RepositoryProvider.of<ModelRepository>(context),
            )..add(CheckModelExists()),
          ),
        ],
        child: MaterialApp(
          title: 'Anticipatory gpt',
          debugShowCheckedModeBanner: false,
          theme:AppTheme.mainTheme,
          initialRoute: AppRoutes.download,
          onGenerateRoute: AppRouter.generateRoute,
        ),
      ),
    );
  }
}
