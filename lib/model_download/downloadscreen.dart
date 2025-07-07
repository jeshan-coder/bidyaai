import 'package:anticipatorygpt/model_download/download_model_bloc.dart';
import 'package:anticipatorygpt/routers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<DownloadModelBloc, DownloadModelState>(
        builder: (context, state) {
          if (state is DownloadInprogress) {
            return DownloadProgressIndicator(progress: state.progress);
          }

          if (state is DownloadFailure) {
            return DownloadErrorWidget(
              error: state.error,
              onRetry: () {
                context.read<DownloadModelBloc>().add(CheckModelExists());
              },
            );
          }
          //
          // if(state is DownloadSuccess || state is ModelAlreadyExists)
          //   {
          //     return Center(child: Text("Model already exists !"),);
          //   }
          return Center(
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Initializing...", style: TextStyle(fontSize: 18)),
              ],
            ),
          );
        },
        listener: (context, state) {
          if (state is DownloadSuccess || state is ModelAlreadyExists) {

            SnackBar snackbar = SnackBar(
              content: Text(
                state is DownloadSuccess
                    ? 'Download Complete !'
                    : 'Model already available.',
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackbar);

            // Navigator.of(context).pushReplacementNamed(AppRoutes.home);

            // WidgetsBinding.instance.addPostFrameCallback((_){
            //   if(context.mounted)
            //     {
            //       Navigator.of(context).pushReplacementNamed(AppRoutes.home);
            //     }
            // });
            Future.delayed(const Duration(seconds: 1), () {
              if(context.mounted) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.home);
              }
                });
          }
        },
      ),
    );
  }
}

class DownloadProgressIndicator extends StatelessWidget {
  final double progress;

  const DownloadProgressIndicator({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Downloading AI Model",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            "This is a one-time download and may take a few minutes. Please stay connected to the internet.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 32),
          LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: Colors.grey.shade700,
            valueColor: const AlwaysStoppedAnimation<Color>(
              Colors.indigoAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${(progress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 24),
          const Text(
            'Download Failed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
