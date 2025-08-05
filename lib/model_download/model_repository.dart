import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/*
It contains functions related to checking model exists or not and downloading model from hugging face.
there functions are used in bloc code also.

getModelFilePath : responsible for getting model file path from local storage.
checkIfModelExists : checks if model exists in local storage.
downloadModel : responsible for downloading model from hugging face.
 */
class ModelRepository {
  final Dio _dio = Dio();
  // --- PREVIOUS 4B MODEL (COMMENTED OUT FOR REFERENCE) ---
  // static const String _modelFileName = 'gemma-3n-E4B-it-int4.task';
  // static const String _modelUrl = 'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task';

  static const String _modelFileName = 'gemma-3n-E2B-it-int4.task';

  // This is the correct, direct download link for the specified .task file.
  static const String _modelUrl =
      'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task';
  // --- NEW: HUGGING FACE AUTHENTICATION ---
  // To download this model, you need a Hugging Face User Access Token.
  // 1. Go to https://huggingface.co/settings/tokens
  // 2. Generate a new token (a 'read' role is sufficient).
  // 3. Paste your token here.
  static const String _huggingFaceToken =
      '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';

  // Define a minimum expected file size in bytes.
  // The actual file is ~4.4GB. We'll use 3GB as a safe lower limit.
  static const int _minExpectedSizeBytes = 3000000000;

  Future<String> getModelFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_modelFileName';
  }

  // Checks if the model file exists and is a reasonable size.
  Future<bool> checkIfModelExists() async {
    final filePath = await getModelFilePath();
    final file = File(filePath);

    if (!await file.exists()) {
      print("Model file does not exist.");
      return false;
    }

    final localFileLength = await file.length();
    print("Found local file. Size: $localFileLength bytes.");

    if (localFileLength < _minExpectedSizeBytes) {
      print(
        "Local file is too small. It's likely corrupt or not the real model. Deleting it.",
      );
      await file.delete();
      return false;
    }

    print("Local file size is valid. Model exists.");
    return true;
  }

  Future<String> downloadModel(Function(double) onProgress) async {
    final filePath = await getModelFilePath();
    try {
      print("Starting download from $_modelUrl to $filePath");

      // --- UPDATED: ADDING AUTH HEADER ---
      // We pass an Options object with the Authorization header to the download request.
      await _dio.download(
        _modelUrl,
        filePath,
        options: Options(
          headers: {'Authorization': 'Bearer $_huggingFaceToken'},
        ),
        onReceiveProgress: (received, total) {
          if (total != -1 && total > 0) {
            double progress = received / total;
            onProgress(progress);
          } else {
            double progress = received / (_minExpectedSizeBytes * 1.46);
            onProgress(progress.clamp(0.0, 1.0));
          }
        },
      );
      print("Download completed successfully.");
      return filePath;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        print(
          "Authorization failed. Please check your Hugging Face token in model_repository.dart.",
        );
        throw Exception(
          "Authorization failed (401). Is your Hugging Face token correct?",
        );
      }
      print("Exception occurred during download: $e");
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      throw Exception(
        "Failed to download model. Please check your network connection and try again.",
      );
    }
  }
}
