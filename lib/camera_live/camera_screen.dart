import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img; // IMPORT for image processing

import 'package:anticipatorygpt/camera_live/camera_bloc.dart';
import 'package:anticipatorygpt/camera_live/camera_event.dart';
import 'package:anticipatorygpt/camera_live/camera_state.dart';
import 'package:flutter_gemma/core/chat.dart'; // For InferenceChat
import 'package:anticipatorygpt/theme.dart'; // IMPORT THEME

// --- IMPORTANT DEPENDENCY ---
// For image preprocessing to work, please add the 'image' package to your pubspec.yaml:
//
// dependencies:
//   image: ^4.1.7
//

/// A screen for live camera feed and AI interaction with image input.
class CameraScreen extends StatefulWidget {
  final InferenceChat chatInstance;

  const CameraScreen({super.key, required this.chatInstance});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // CHANGE: Re-introduced the text controller for the live input field.
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize CameraBloc with the shared chat instance
    context.read<CameraBloc>().add(InitializeCamera());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // CHANGE: This method now reads from the text controller and preprocesses the image.
  Future<void> _captureAndSendMessage() async {
    final bloc = context.read<CameraBloc>();
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please type a message to send with the image.')),
      );
      return;
    }

    if (bloc.state is CameraReady) {
      final CameraController? controller = bloc.state.cameraController;
      if (controller != null && controller.value.isInitialized) {
        try {
          final XFile imageFile = await controller.takePicture();
          final Uint8List imageBytes = await imageFile.readAsBytes();

          // --- IMAGE PREPROCESSING STEP ---
          // Decode, resize to 512x512, and re-encode the image.
          final originalImage = img.decodeImage(imageBytes)!;
          final resizedImage =
          img.copyResize(originalImage, width: 512, height: 512);
          final Uint8List processedImageBytes =
          Uint8List.fromList(img.encodeJpg(resizedImage));
          // --- END OF PREPROCESSING ---

          bloc.add(CaptureAndSendMessage(
            message: _textController.text.trim(),
            imageBytes: processedImageBytes, // Send the processed image
          ));
          _textController.clear();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to capture image: $e')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera not ready yet.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live AI Vision'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              context.read<CameraBloc>().add(ClearResponse());
            },
            tooltip: 'Clear Response',
          ),
        ],
      ),
      body: BlocConsumer<CameraBloc, CameraState>(
        listener: (context, state) {
          if (state is CameraError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.error}')),
            );
          }
        },
        builder: (context, state) {
          if (state is CameraInitial ||
              state is CameraLoading && state.cameraController == null) {
            return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ));
          }

          if (state.cameraController == null ||
              !state.cameraController!.value.isInitialized) {
            return const Center(
                child: Text('Camera not available or initializing...'));
          }

          return Stack(
            children: [
              Positioned.fill(
                child: CameraPreview(state.cameraController!),
              ),
              if (state.currentResponse != null &&
                  state.currentResponse!.isNotEmpty)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.currentResponse!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    left: 16,
                    right: 16,
                  ),
                  child: Builder(
                    builder: (innerContext) {
                      if (state.isResponding) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor),
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Analyzing...',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      } else if (state.currentResponse != null &&
                          state.currentResponse!.isNotEmpty) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              innerContext
                                  .read<CameraBloc>()
                                  .add(ClearResponse());
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Ask New Question'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding:
                              const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      } else {
                        // CHANGE: Reverted to the live input field and send button UI.
                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                enabled: !state.isResponding,
                                decoration: InputDecoration(
                                  hintText: 'Type a question...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 14),
                                ),
                                style: const TextStyle(color: Colors.black),
                                onSubmitted: (_) => _captureAndSendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FloatingActionButton(
                              onPressed: _captureAndSendMessage,
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              child: const Icon(Icons.send),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
