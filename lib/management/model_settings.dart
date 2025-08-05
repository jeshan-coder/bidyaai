import 'package:flutter_gemma/core/chat.dart';

/// File: model_settings.dart
///
/// Purpose:
///   This file defines constant default values for various settings related to
///   the AI model's behavior and configuration. These constants is used
///   during initializing and loading model to memory
///
/// Key Components:
///   - `ModelSettings` (class): A class that acts as a namespace for static
///     constant values. It is not meant to be instantiated.
///
/// Constants Defined:
///   - `defaultTemperature`: The default sampling temperature for the model.
///   - `defaultTopK`: The default top-K sampling value.
///   - `defaultTopP`: The default top-P (nucleus) sampling value.
///   - `defaultMaxOutputTokens`: The default maximum number of tokens the model
///     should generate in a single response.
///


class ModelSettings
{
  static const double defaultTemperature=0.1;

  static const int defaultTopK=40;

  static const double defaultTopP=0.95;

  static const int defaultMaxOutputTokens= 2048;


}