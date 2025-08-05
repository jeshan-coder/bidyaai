import 'package:flutter/material.dart';

/*
Not found screen if some navigation issue occurs.
 */

class NotFound extends StatelessWidget {
  const NotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Not found !")));
  }
}
