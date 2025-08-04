import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:image/image.dart' as img;

import 'package:anticipatorygpt/theme.dart';
import 'document_reader_bloc.dart';
import 'document_reader_event.dart';
import 'document_reader_state.dart';

// MODIFICATION: Pass InferenceChat and languageCode to the screen.
class DocumentReaderScreen extends StatelessWidget {
  final InferenceChat chatInstance;
  final String languageCode;
  const DocumentReaderScreen({Key? key, required this.chatInstance, required this.languageCode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // MODIFICATION: Create the bloc with the chat instance and language code.
      create: (_) => DocumentReaderBloc(chat: chatInstance, languageCode: languageCode),
      child: _DocumentView(),
    );
  }
}

class _DocumentView extends StatefulWidget {
  @override
  State<_DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<_DocumentView> {
  late PdfViewerController _pdfController;
  // NEW: GlobalKey to capture the screenshot of the PDF viewer.
  final GlobalKey _pdfViewerKey = GlobalKey();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // NEW METHOD: Captures a screenshot of the current PDF page.
  Future<Uint8List?> _captureScreenshot() async {
    try {
      final RenderRepaintBoundary boundary =
      _pdfViewerKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage();
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Downsize the image for faster processing by the AI model.
      final img.Image? originalImage = img.decodeImage(pngBytes);
      if (originalImage == null) return null;
      final img.Image resizedImage = img.copyResize(originalImage, width: 512, height: 512);
      return Uint8List.fromList(img.encodeJpg(resizedImage));
    } catch (e) {
      print("Error capturing screenshot: $e");
      return null;
    }
  }

  // NEW METHOD: Sends the message and screenshot to the AI.
  Future<void> _sendMessageWithScreenshot() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type a question.')),
      );
      return;
    }

    final pdfState = context.read<DocumentReaderBloc>().state;
    if (pdfState is! DocumentLoaded && pdfState is! DocumentLoadedWithResponse) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF first.')),
      );
      return;
    }

    final imageBytes = await _captureScreenshot();
    if (imageBytes != null) {
      context.read<DocumentReaderBloc>().add(ProcessDocument(
        message: text,
        imageBytes: imageBytes,
      ));
      _textController.clear();
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture PDF screenshot.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // MODIFICATION: Set Scaffold background color to white.
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('PDF Reader'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<DocumentReaderBloc, DocumentState>(
        listener: (context, state) {
          if (state is DocumentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          if (state is DocumentInitial) {
            return _buildSelectButton(context);
          }

          if (state is DocumentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DocumentError) {
            return _buildError(context, state.message);
          }

          if (state is DocumentLoaded || state is DocumentAnalyzing || state is DocumentLoadedWithResponse) {
            final pdfBytes = state is DocumentLoaded ? state.pdfBytes
                : state is DocumentAnalyzing ? state.pdfBytes
                : (state as DocumentLoadedWithResponse).pdfBytes;
            return _buildPdfViewer(context, state, pdfBytes);
          }

          return const SizedBox.shrink();
        },
      ),
      // MODIFICATION: Removed floating action buttons.
      // Removed the floatingActionButton property entirely.
    );
  }

  Widget _buildSelectButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Select PDF Document'),
        onPressed: () {
          context.read<DocumentReaderBloc>().add(SelectDocument());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () =>
                context.read<DocumentReaderBloc>().add(SelectDocument()),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // MODIFICATION: This widget is now more complex to include AI interaction.
  Widget _buildPdfViewer(BuildContext context, DocumentState state, Uint8List pdfBytes) {
    final int currentPage = state is DocumentLoaded
        ? state.currentPage
        : state is DocumentAnalyzing
        ? state.currentPage
        : (state as DocumentLoadedWithResponse).currentPage;
    final int pageCount = state is DocumentLoaded
        ? state.pageCount
        : state is DocumentAnalyzing
        ? state.pageCount
        : (state as DocumentLoadedWithResponse).pageCount;
    final bool isAnalyzing = state is DocumentAnalyzing;
    final bool hasResponse = state is DocumentLoadedWithResponse;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              RepaintBoundary(
                key: _pdfViewerKey,
                child: SfPdfViewer.memory(
                  pdfBytes,
                  controller: _pdfController,
                  onDocumentLoaded: (details) {
                    final total = _pdfController.pageCount;
                    context
                        .read<DocumentReaderBloc>()
                        .add(DocumentPageLoaded(total));
                  },
                  onPageChanged: (details) {
                    context
                        .read<DocumentReaderBloc>()
                        .add(DocumentPageChanged(details.newPageNumber));
                  },
                ),
              ),
              // MODIFICATION: Made the AI response container scrollable.
              if (state is DocumentAnalyzing || state is DocumentLoadedWithResponse)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4, // Constrain height to prevent overflow
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        state is DocumentAnalyzing ? state.currentResponse : (state as DocumentLoadedWithResponse).aiResponse,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Page indicator and input row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              Text(
                'Page $currentPage/$pageCount',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (!hasResponse) // Show input field and send button when no response
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        enabled: !isAnalyzing,
                        decoration: InputDecoration(
                          hintText: 'Ask a question about this page...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isAnalyzing ? Colors.grey.shade200 : Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      heroTag: 'send',
                      onPressed: isAnalyzing ? null : _sendMessageWithScreenshot,
                      mini: true,
                      backgroundColor: isAnalyzing ? Colors.grey : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      child: isAnalyzing
                          ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.send),
                    ),
                  ],
                )
              else // Show the "Clear" button when there is a response
                ElevatedButton(
                  onPressed: () {
                    context.read<DocumentReaderBloc>().add(ClearResponse());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text('Clear'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
