import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'chat_bloc.dart';

// this is not used so, we could ignore this file

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
      resizeToAvoidBottomInset: true, // allows body to shift for keyboard
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatModelLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Initializing AI Model...'),
                      ],
                    ),
                  );
                }
                if (state is ChatError && state.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Initialization Failed",
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<ChatBloc>().add(InitializeChat()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: state.messages.isEmpty
                          ? const Center(child: Text('Ask me anything'))
                          : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8.0),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages[index];
                          return _ChatMessageBubble(message: message);
                        },
                      ),
                    ),
                    _MessageInputField(
                      controller: _textController,
                      onSend: _sendMessage,
                      onAttach: _pickImage,
                      onClearImage: () {
                        setState(() {
                          _selectedImageBytes = null;
                        });
                      },
                      isGenerating: state is ChatLoading,
                      attachedImageBytes: _selectedImageBytes,
                    ),
                  ],
                );
              },
              listener: (context, state) {
                if (state is ChatLoading || state is ChatLoaded) {
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
    final theme = Theme.of(context);
    final isUser = message.isFromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.memory(
                  message.imageBytes!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            if (message.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                    top: message.imageBytes != null ? 8.0 : 0),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isUser
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            if (!isUser &&
                message.text.isEmpty &&
                message.imageBytes == null)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onClearImage;
  final bool isGenerating;
  final Uint8List? attachedImageBytes;

  const _MessageInputField({
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.onClearImage,
    required this.isGenerating,
    this.attachedImageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canAttach = !isGenerating && attachedImageBytes == null;

    return Padding(
      padding: EdgeInsets.fromLTRB(8, 8, 8, bottomInset),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachedImageBytes != null)
              _ImagePreview(
                imageBytes: attachedImageBytes!,
                onClear: onClearImage,
              ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, -1),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: canAttach ? onAttach : null,
                    icon: const Icon(
                        Icons.add_photo_alternate_outlined),
                    color: canAttach
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: !isGenerating,
                      decoration: InputDecoration(
                        hintText: isGenerating
                            ? 'AI is responding…'
                            : 'Type a message…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor:
                        Theme.of(context).scaffoldBackgroundColor,
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      onSubmitted: (_) =>
                      isGenerating ? null : (_) => onSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: isGenerating ? null : onSend,
                    icon: Icon(isGenerating
                        ? Icons.stop_circle_outlined
                        : Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: isGenerating
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor:
                      Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final Uint8List imageBytes;
  final VoidCallback onClear;
  const _ImagePreview({
    required this.imageBytes,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 8.0, left: 40, right: 40),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.memory(
              imageBytes,
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
