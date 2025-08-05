import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Base class for document-related events
abstract class DocumentEvent extends Equatable {
  const DocumentEvent();

  @override
  List<Object?> get props => [];
}

/// User taps "Select PDF"
class SelectDocument extends DocumentEvent {}

/// Viewer reports total page count
class DocumentPageLoaded extends DocumentEvent {
  final int pageCount;
  const DocumentPageLoaded(this.pageCount);

  @override
  List<Object?> get props => [pageCount];
}

/// Viewer reports current page changed (1-based)
class DocumentPageChanged extends DocumentEvent {
  final int pageNumber;
  const DocumentPageChanged(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}

/// Something went wrong
class DocumentErrorEvent extends DocumentEvent {
  final String message;
  const DocumentErrorEvent(this.message);

  @override
  List<Object?> get props => [message];
}

// A user sends a message with a screenshot to the AI.
class ProcessDocument extends DocumentEvent {
  final String message;
  final Uint8List imageBytes;
  const ProcessDocument({required this.message, required this.imageBytes});

  @override
  List<Object?> get props => [message, imageBytes];
}

// A user clears the AI response from the screen.
class ClearResponse extends DocumentEvent {}
