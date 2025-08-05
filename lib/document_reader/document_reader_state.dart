import 'dart:typed_data';
import 'package:equatable/equatable.dart';

/// Base class for document-related states
abstract class DocumentState extends Equatable {
  const DocumentState();

  @override
  List<Object?> get props => [];
}

/// No document selected yet
final class DocumentInitial extends DocumentState {}

/// In the process of picking or loading a PDF
final class DocumentLoading extends DocumentState {}

/// In the process of analyzing the document with AI
class DocumentAnalyzing extends DocumentState {
  final Uint8List pdfBytes;
  final int pageCount;
  final int currentPage;
  final String currentResponse;

  const DocumentAnalyzing({
    required this.pdfBytes,
    required this.pageCount,
    required this.currentPage,
    this.currentResponse = '',
  });

  @override
  List<Object?> get props => [pdfBytes, pageCount, currentPage, currentResponse];
}

/// Successfully loaded PDF in memory and is ready for interaction
class DocumentLoaded extends DocumentState {
  final Uint8List pdfBytes;
  final int pageCount;
  final int currentPage;

  const DocumentLoaded({
    required this.pdfBytes,
    required this.pageCount,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [pdfBytes, pageCount, currentPage];
}

// PDF is loaded and AI has responded.
class DocumentLoadedWithResponse extends DocumentState {
  final Uint8List pdfBytes;
  final int pageCount;
  final int currentPage;
  final String aiResponse;

  const DocumentLoadedWithResponse({
    required this.pdfBytes,
    required this.pageCount,
    required this.currentPage,
    required this.aiResponse,
  });

  @override
  List<Object?> get props => [pdfBytes, pageCount, currentPage, aiResponse];
}


/// An error occurred
class DocumentError extends DocumentState {
  final String message;
  const DocumentError(this.message);

  @override
  List<Object?> get props => [message];
}

