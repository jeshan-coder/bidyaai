import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true,title: Text("Anticipatry gpt"),),
      body: Center(child:Image.asset("assets/first.png",width: 100,height: 100,),),
    );
  }
}
