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


  @override
  void dispose()
  {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage()
  {
    if(_textController.text.trim().isNotEmpty)
      {
        context.read<ChatBloc>().add(SendMessage(_textController.text.trim()));
        _textController.clear();
        FocusScope.of(context).unfocus();
      }
  }

  void _scrollToBottom()
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
      appBar: AppBar(
        title: Text("Chat"),

      ),
      body: Column(
        children: [
          Expanded(child:
          BlocConsumer<ChatBloc,ChatState>(builder:(context,state){
            if(state.messages.isEmpty)
              {
                return const Center(
                  child: Text("Ask me anything !"),
                );
              }

            return ListView.builder(controller: _scrollController,padding: const EdgeInsets.all(8.0),itemCount: state.messages.length,itemBuilder:(context,index){
              final message=state.messages[index];

              return _ChatMessageBubble(message:message);
            });
          }, listener:(context,state){
            if(state is ChatLoading || state is ChatLoaded) {
              _scrollToBottom();
            }
            if(state is ChatError)
              {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content:Text('Error: ${state.error}'),
                  backgroundColor: Colors.red,),

                );
              }
          })),
          _MessageInputField(
            controller:_textController,
            onSend:_sendMessage,
          )
        ],
      ),
    );
  }
}


class _ChatMessageBubble extends StatelessWidget {

  final ChatMessage message;
  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final isUser=message.isFromUser;
    return Align(
      alignment: isUser?Alignment.centerRight:Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0,horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 14.0),
        decoration: BoxDecoration(
          color: isUser?theme.colorScheme.primary:theme.cardColor,
          borderRadius: BorderRadius.circular(16.0)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text,
              style: TextStyle(
                color: isUser?theme.colorScheme.onPrimary:theme.colorScheme.onSurface
              ),

            ),
            if(!isUser && message.text.isEmpty)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2,),
              )

          ],
        ),
      ),


    );
  }
}

class _MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _MessageInputField({required this.controller,required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0,-1),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1)
          )
        ]
      ),
      child: SafeArea(child:Row(
        children: [
          Expanded(child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText:"Type a message...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
                borderSide: BorderSide.none
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0)

            ),
            onSubmitted: (_)=>onSend(),
          )),
          const SizedBox(width: 8.0,),
          IconButton(onPressed: onSend, icon:const Icon(Icons.send),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.all(12)
          ),
          )
        ],
      )),
    );
  }
}



