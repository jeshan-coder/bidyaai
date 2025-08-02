import 'dart:typed_data';
import 'package:anticipatorygpt/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:anticipatorygpt/routers.dart'; // Import AppRoutes
import 'package:anticipatorygpt/quiz/quiz_model.dart'; // Import Quiz model
import 'chat_bloc.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(InitializeChat());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  void _sendMessage() {
    if (_textController.text.trim().isNotEmpty || _selectedImageBytes != null) {
      context.read<ChatBloc>().add(
        SendMessage(
          _textController.text.trim(),
          imageBytes: _selectedImageBytes,
        ),
      );
      _textController.clear();
      setState(() {
        _selectedImageBytes = null;
      });
      FocusScope.of(context).unfocus();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "BidyaAI",
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: AppTheme.primaryColor),
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              final bool isModelReady =
                  state is! ChatModelLoading && state is! ChatLoading;
              return IconButton(
                onPressed: isModelReady
                    ? () {
                  Navigator.of(context)
                      .pushNamed(AppRoutes.cameraLive, arguments: {
                    'chatInstance': context.read<ChatBloc>().chatInstance
                  });
                }
                    : null,
                icon: const Icon(Icons.videocam, color: AppTheme.primaryColor),
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: BlocConsumer<ChatBloc, ChatState>(
                  builder: (context, state) {
                    if (state is ChatModelLoading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Loading model...",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      );
                    }
                    if (state is ChatError && state.messages.isEmpty) {
                      return Center(child: Text('Error: ${state.error}'));
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        return _ChatMessageBubble(message: message);
                      },
                    );
                  },
                  listener: (context, state) {
                    if (state is ChatLoading ||
                        state is ChatLoaded ||
                        state is ChatQuizReady) {
                      _scrollToBottom();
                    }
                    if (state is ChatError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${state.error}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
              BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state.quizReady && state.generatedQuiz != null) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.quiz,
                            arguments: {
                              'quiz': state.generatedQuiz,
                              'chatInstance':
                              context.read<ChatBloc>().chatInstance,
                              'languageCode': state.languageCode,
                            },
                          ).then((_) {
                            context.read<ChatBloc>().add(ClearQuizState());
                          });
                        },
                        icon: const Icon(Icons.quiz_outlined),
                        label: const Text('Start Quiz!'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          textStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  return _MessageInputField(
                    controller: _textController,
                    onSend: _sendMessage,
                    onAttach: _pickImage,
                    isGenerating:
                    state is ChatLoading || state is ChatModelLoading,
                    attachedImageBytes: _selectedImageBytes,
                    onClearImage: () {
                      setState(() {
                        _selectedImageBytes = null;
                      });
                    },
                  );
                },
              ),
            ],
          ),
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state is ChatModelLoading) {
                return Container(
                  color: Colors.black.withOpacity(0.05),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatMessageBubble({required this.message});

  // CHANGE: New helper method to build the text with highlighting.
  List<TextSpan> _buildTextSpans(BuildContext context, String text, bool isUser) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyLarge?.copyWith(
      color: isUser ? Colors.white : Colors.black87,
    );

    if (isUser && text.startsWith('/quiz')) {
      return [
        TextSpan(
          text: '/quiz',
          style: baseStyle?.copyWith(
            color: Colors.green.shade400,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: text.substring(5), // The rest of the string
          style: baseStyle,
        ),
      ];
    }
    return [TextSpan(text: text, style: baseStyle)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isFromUser;

    final aiAvatar = const CircleAvatar(
        backgroundImage: AssetImage('assets/bidya.png'));
    final userAvatar = const CircleAvatar(
        backgroundImage: AssetImage('assets/user.png'));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment:
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
            EdgeInsets.only(left: isUser ? 0 : 52, right: isUser ? 52 : 0),
            child: Text(
              isUser ? "User" : "BidyaAI",
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[aiAvatar, const SizedBox(width: 12)],
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color:
                  isUser ? AppTheme.primaryColor : const Color(0xFFF1F2F6),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                // CHANGE: Replaced Text with RichText to allow for styled text spans.
                child: RichText(
                  text: TextSpan(
                    children: _buildTextSpans(context, message.text, isUser),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [userAvatar],
                )
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool isGenerating;
  final Uint8List? attachedImageBytes;
  final VoidCallback onClearImage;

  const _MessageInputField({
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.isGenerating,
    this.attachedImageBytes,
    required this.onClearImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      color: Colors.transparent,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachedImageBytes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Image attached",
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            color: AppTheme.primaryColor,
                            onPressed: onClearImage,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            enabled: !isGenerating,
                            decoration: InputDecoration(
                              hintText: 'Ask me anything...',
                              hintStyle:
                              TextStyle(color: Colors.grey.shade500),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.only(
                                  left: 20.0, top: 14, bottom: 14),
                            ),
                            onSubmitted: (_) =>
                            isGenerating ? null : onSend(),
                          ),
                        ),
                        IconButton(
                          onPressed: isGenerating || attachedImageBytes != null
                              ? null
                              : onAttach,
                          icon: Icon(Icons.image_outlined,
                              color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: FloatingActionButton(
                    onPressed: isGenerating ? null : onSend,
                    backgroundColor: AppTheme.primaryColor,
                    elevation: 0,
                    shape: const CircleBorder(),
                    child: isGenerating
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.send,
                        color: Colors.white, size: 22),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
