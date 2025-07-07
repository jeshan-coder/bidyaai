import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'chat_bloc.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final TextEditingController _textController= TextEditingController();

  final ScrollController _scrollController=ScrollController();

  void _sendMessage()
  {
    if(_textController.text.trim().isNotEmpty)
      {
        context.read<ChatBloc>().add(SendMessage(_textController.text.trim()));
        _textController.clear();
      }
  }

  void _scrollToButtom()
  {
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(_scrollController.hasClients)
        {
          _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration:const Duration(milliseconds: 300), curve:Curves.easeOut);
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
    );
  }
}

