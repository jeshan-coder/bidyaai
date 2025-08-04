import 'dart:async';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:anticipatorygpt/management/prompt_management.dart';

import 'document_reader_event.dart';
import 'document_reader_state.dart';


class DocumentReaderBloc extends Bloc<DocumentEvent, DocumentState> {
  final InferenceChat _chat;
  final String _languageCode;

  DocumentReaderBloc({required InferenceChat chat, required String languageCode})
      : _chat = chat,
        _languageCode = languageCode,
        super(DocumentInitial()) {
    on<SelectDocument>(_onSelectDocument);
    on<DocumentPageLoaded>(_onDocumentPageLoaded);
    on<DocumentPageChanged>(_onDocumentPageChanged);
    on<DocumentErrorEvent>(_onError);
    on<ProcessDocument>(_onProcessDocument);
    on<ClearResponse>(_onClearResponse);
  }

  Future<void> _onSelectDocument(
      SelectDocument event, Emitter<DocumentState> emit) async {
    emit(DocumentLoading());
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) {
        emit(DocumentInitial());
        return;
      }

      final Uint8List bytes = result.files.single.bytes!;
      emit(DocumentLoaded(
        pdfBytes: bytes,
        pageCount: 0,
        currentPage: 0,
      ));
    } catch (e) {
      emit(DocumentError('Failed to pick PDF: $e'));
    }
  }

  void _onDocumentPageLoaded(
      DocumentPageLoaded event, Emitter<DocumentState> emit) {
    final s = state;
    if (s is DocumentLoaded) {
      emit(DocumentLoaded(
        pdfBytes: s.pdfBytes,
        pageCount: event.pageCount,
        currentPage: 1,
      ));
    } else if (s is DocumentLoadedWithResponse) {
      emit(DocumentLoadedWithResponse(
        pdfBytes: s.pdfBytes,
        pageCount: event.pageCount,
        currentPage: 1,
        aiResponse: s.aiResponse,
      ));
    }
  }

  void _onDocumentPageChanged(
      DocumentPageChanged event, Emitter<DocumentState> emit) {
    final s = state;
    if (s is DocumentLoaded) {
      emit(DocumentLoaded(
        pdfBytes: s.pdfBytes,
        pageCount: s.pageCount,
        currentPage: event.pageNumber,
      ));
    } else if (s is DocumentLoadedWithResponse) {
      emit(DocumentLoadedWithResponse(
        pdfBytes: s.pdfBytes,
        pageCount: s.pageCount,
        currentPage: event.pageNumber,
        aiResponse: s.aiResponse,
      ));
    }
  }

  void _onError(DocumentErrorEvent event, Emitter<DocumentState> emit) {
    emit(DocumentError(event.message));
  }

  // NEW EVENT HANDLER: Processes the document and sends to AI
  Future<void> _onProcessDocument(
      ProcessDocument event, Emitter<DocumentState> emit) async {
    if (_chat == null) {
      emit(DocumentError('AI chat session is not initialized.'));
      return;
    }

    final Uint8List pdfBytes;
    final int pageCount;
    final int currentPage;

    if (state is DocumentLoaded) {
      final s = state as DocumentLoaded;
      pdfBytes = s.pdfBytes;
      pageCount = s.pageCount;
      currentPage = s.currentPage;
    } else if (state is DocumentLoadedWithResponse) {
      final s = state as DocumentLoadedWithResponse;
      pdfBytes = s.pdfBytes;
      pageCount = s.pageCount;
      currentPage = s.currentPage;
    } else {
      emit(DocumentError('Cannot process document in current state.'));
      return;
    }

    try {
      emit(DocumentAnalyzing(
        pdfBytes: pdfBytes,
        pageCount: pageCount,
        currentPage: currentPage,
      ));

      await _chat.clearHistory();

      final prompt = PromptManager.generateImageUnderstandingPrompt(event.message);

      await _chat.addQueryChunk(Message.withImage(
        text: prompt,
        imageBytes: event.imageBytes,
        isUser: true,
      ));

      String fullResponse = '';
      final responseStream = _chat.generateChatResponseAsync();
      await for (final responsePart in responseStream) {
        fullResponse += responsePart;
        emit(DocumentAnalyzing(
          pdfBytes: pdfBytes,
          pageCount: pageCount,
          currentPage: currentPage,
          currentResponse: fullResponse,
        ));
      }

      emit(DocumentLoadedWithResponse(
        pdfBytes: pdfBytes,
        pageCount: pageCount,
        currentPage: currentPage,
        aiResponse: fullResponse,
      ));

      print("DocumentReaderBloc: AI analysis complete.");
    } catch (e) {
      print("DocumentReaderBloc: Error sending message with image: $e");
      emit(DocumentError('Failed to get AI response: $e'));
    }
  }

  // NEW EVENT HANDLER: Clears the AI response from the state.
  void _onClearResponse(ClearResponse event, Emitter<DocumentState> emit) {
    if (state is DocumentLoadedWithResponse) {
      final s = state as DocumentLoadedWithResponse;
      // Revert to a normal DocumentLoaded state with the same PDF data.
      emit(DocumentLoaded(
        pdfBytes: s.pdfBytes,
        pageCount: s.pageCount,
        currentPage: s.currentPage,
      ));
    }
  }

  @override
  Future<void> close() {
    print("DocumentReaderBloc: Disposed chat instance.");
    return super.close();
  }
}
