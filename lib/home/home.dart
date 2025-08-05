import 'package:bidyaai/routers.dart';
import 'package:bidyaai/theme.dart';
import 'package:flutter/material.dart';

/*

  Purpose:
  This file defines the main home screen of the BidyaAI application.
  It serves as the entry point for users after the initial setup (like model download).
  From this screen, users can navigate to the chat interface or a guide screen.

  Key Components:
  - `Home` (StatefulWidget): The primary widget for the home screen UI.
  - `_HomeState`: Manages the state for the `Home` widget, specifically the
    toggle for GPU usage.

  Functionality:
  - Displays the application logo and introductory text.
  - Provides a toggle switch to enable or disable GPU acceleration for the
    AI model interactions.
  - Contains buttons to:
    - Navigate to the chat screen (`AppRoutes.chat`), passing the GPU preference.
    - Navigate to a guide screen (`AppRoutes.guide`).

  Usage:
  This screen is typically pushed onto the navigation stack after any initial
  loading or setup screens (e.g., `DownloadScreen`).
  It expects the necessary routes (`AppRoutes.chat`, `AppRoutes.guide`) to be
  defined in the application's router.
*/

// The Home widget is now a StatefulWidget to manage the toggle button state.
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // A state variable to track if the GPU should be used.
  bool _useGpu = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Image.asset(
                      'assets/assist.png',
                      height: MediaQuery.of(context).size.height * 0.4,
                    ),
                    const SizedBox(height: 48),

                    Text(
                      "BidyaAI",
                      style: textTheme.titleLarge?.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      "Education for unreachable",
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Use GPU', style: textTheme.bodyLarge),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _useGpu = !_useGpu;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 50.0,
                              height: 28.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                color: _useGpu
                                    ? AppTheme.primaryColor
                                    : Colors.white,
                                border: Border.all(
                                  color: _useGpu
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade400,
                                ),
                              ),
                              child: Align(
                                alignment: _useGpu
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Container(
                                    width: 24.0,
                                    height: 24.0,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.chat,
                          arguments: {'useGpu': _useGpu},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F1E3A),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Text(
                        'Start Exploring',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.guide);
                      },
                      child: const Text(
                        'Guide',
                        style: TextStyle(
                          color: Color(0xFF0F1E3A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
