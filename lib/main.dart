import 'package:anticipatorygpt/home/home.dart';
import 'package:anticipatorygpt/routers.dart';
import 'package:flutter/material.dart';
import 'notFound.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anticipatory gpt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute:AppRoutes.home,
      onGenerateRoute: AppRouter.generateRoute,
      home: Home(),
    );
  }
}



