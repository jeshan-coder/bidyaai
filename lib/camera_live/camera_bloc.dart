import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart'; // For temporary file path
import 'dart:io'; // For File operations

import 'package:anticipatorygpt/management/prompt_management.dart';
import 'package:anticipatorygpt/management/model_settings.dart';

import 'camera_event.dart';
import 'camera_state.dart';



/// BLoC responsible for managing camera operations and AI interactions
/// for the live camera feature.
class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final InferenceChat _chat;
  CameraController? _cameraController;

  CameraBloc({required InferenceChat chat})
      : _chat = chat,
        super(CameraInitial()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<CaptureAndSendMessage>(_onCaptureAndSendMessage);
    on<ClearResponse>(_onClearResponse);
  }

  /// Initializes the camera controller and starts the preview.
  Future<void> _onInitializeCamera(
      InitializeCamera event, Emitter<CameraState> emit) async {
    if (state is! CameraInitial && state is! CameraError) {
      // Only initialize if not already ready or in error state
      return;
    }

    emit(const CameraLoading()); // Indicate camera is initializing

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        emit(const CameraError(error: 'No cameras found on device.'));
        return;
      }

      // Select the first available camera (usually back camera)
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium, // Medium resolution for performance
        enableAudio: false, // Audio not needed for this feature
      );

      await _cameraController!.initialize();
      await _cameraController!.startImageStream((image) {
        // This stream can be used for continuous processing if needed,
        // but for "last frame" we'll capture explicitly.
      });

      emit(CameraReady(cameraController: _cameraController!));
      print("CameraBloc: Camera initialized and ready.");
    } catch (e) {
      print("CameraBloc: Error initializing camera: $e");
      emit(CameraError(error: 'Failed to initialize camera: $e'));
    }
  }

  /// Captures an image, sends it with a message to the AI, and streams the response.
  Future<void> _onCaptureAndSendMessage(
      CaptureAndSendMessage event, Emitter<CameraState> emit) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      emit(CameraError(
          error: 'Camera not initialized.',
          cameraController: state.cameraController,
          currentResponse: state.currentResponse));
      return;
    }

    // Emit loading state with initial message, currentResponse is null for bottom text
    emit(CameraLoading(
        cameraController: _cameraController,
        currentResponse: null, // Set to null to prevent text from appearing at bottom
        isResponding: true));

    try {
      // Clear chat history before new interaction
      await _chat.clearHistory();

      final XFile imageFile = await _cameraController!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();

      final prompt = PromptManager.generateImageUnderstandingPrompt(event.message);

      await _chat.addQueryChunk(Message.withImage(
        text: prompt,
        imageBytes: imageBytes,
        isUser: true,
      ));

      String fullResponse = '';
      final responseStream = _chat.generateChatResponseAsync();

      await for (final responsePart in responseStream.timeout(const Duration(seconds: 45))) {
        fullResponse += responsePart;
        // When streaming, update currentResponse for the TOP overlay only
        emit(CameraLoading(
            cameraController: _cameraController,
            currentResponse: fullResponse, // This is for the top overlay
            isResponding: true));
        await Future.delayed(const Duration(milliseconds: 50)); // Yield control for streaming
      }

      // When response is complete, set isResponding to false
      emit(CameraReady(
          cameraController: _cameraController!,
          currentResponse: fullResponse,
          isResponding: false));
      print("CameraBloc: Image analysis complete.");
    } on TimeoutException catch (e) {
      print("CameraBloc: AI response timed out: $e");
      emit(CameraError(
          error: 'AI response timed out. Please try again.',
          cameraController: _cameraController,
          currentResponse: state.currentResponse, // Keep last response for error display
          isResponding: false));
      emit(CameraReady(
          cameraController: _cameraController!,
          currentResponse: state.currentResponse, // Revert to ready state with last response
          isResponding: false));
    } catch (e) {
      print("CameraBloc: Error sending message with image: $e");
      emit(CameraError(
          error: 'Failed to get AI response: $e',
          cameraController: _cameraController,
          currentResponse: state.currentResponse, // Keep last response for error display
          isResponding: false));
      emit(CameraReady(
          cameraController: _cameraController!,
          currentResponse: state.currentResponse, // Revert to ready state with last response
          isResponding: false));
    }
  }

  /// Clears the current AI response displayed on the screen.
  Future<void> _onClearResponse(
      ClearResponse event, Emitter<CameraState> emit) async {
    emit(CameraReady(cameraController: _cameraController!, currentResponse: null));
  }

  @override
  Future<void> close() {
    _cameraController?.dispose(); // Dispose camera controller
    print("CameraBloc: Camera controller disposed.");
    return super.close();
  }
}