import 'package:bidyaai/model_download/download_model_bloc.dart';
import 'package:bidyaai/routers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bidyaai/theme.dart'; // IMPORT ADDED

/*
Displays progress of downloading model from hugging face.
redirected to this page automatically if model is not present.
 */
class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text("BidyaAI", style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
      ),
      // The BLoC logic is now restored.
      body: BlocConsumer<DownloadModelBloc, DownloadModelState>(
        listener: (context, state) {
          if (state is DownloadSuccess || state is ModelAlreadyExists) {
            SnackBar snackbar = SnackBar(
              content: Text(
                state is DownloadSuccess
                    ? 'Download Complete!'
                    : 'Model already available.',
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackbar);

            Future.delayed(const Duration(seconds: 1), () {
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.home);
              }
            });
          }
        },
        builder: (context, state) {
          if (state is DownloadInprogress) {
            return DownloadProgressUI(progress: state.progress);
          }

          if (state is DownloadFailure) {
            return DownloadErrorWidget(
              error: state.error,
              onRetry: () {
                context.read<DownloadModelBloc>().add(CheckModelExists());
              },
            );
          }

          // Default state (Initializing)
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Initializing..."),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DownloadProgressUI extends StatelessWidget {
  final double progress;

  const DownloadProgressUI({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // CHANGE: Adjusted the color to be slightly darker for better visibility.
    const progressBarBackgroundColor = Color(0xFFE0E0E0);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text("Downloading Bidya AI", style: textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            "This is a one-time download and may take a few minutes. Please stay connected to the internet.",
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Downloading", style: textTheme.bodyMedium),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: progressBarBackgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DownloadErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const DownloadErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Download Failed', style: textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text(
            "There was a problem downloading the content. Please check your internet connection and try again.",
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
            ),
            child: Text(
              'Retry',
              style: textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
