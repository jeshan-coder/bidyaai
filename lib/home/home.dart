import 'package:anticipatorygpt/routers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../model_download/model_repository.dart';

// This is your main application screen. It no longer needs the modelPath.
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // You can access the repository here if you need to get the model path
    // to initialize your AI service.
    final modelRepository = RepositoryProvider.of<ModelRepository>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen'),
      automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Application is ready.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              // Example of how to get the path when you need it.
              FutureBuilder<String>(
                future: modelRepository.getModelFilePath(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Model Info",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Model is available at:",
                              style: TextStyle(color: Colors.white70),
                            ),
                            SelectableText(
                              snapshot.data!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              ElevatedButton(onPressed: (){
                Navigator.of(context).pushNamed(AppRoutes.chat);
              }, child:Text("Start"))
            ],
          ),
        ),
      ),
    );
  }
}
